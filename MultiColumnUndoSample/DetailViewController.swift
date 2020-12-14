//
//  DetailViewController.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/14.
//

import UIKit
import CoreData

final class DetailViewController : UITableViewController {

    var folderObjectID: NSManagedObjectID? {
        didSet {
            if let newValue = folderObjectID {
                let fetchRequest = NSFetchRequest<Folder>(entityName: "Folder")
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "SELF == %@", newValue)
                folder = try? managedObjectContext.fetch(fetchRequest).first
            } else {
                folder = nil
            }
            navigationItem.rightBarButtonItem?.isEnabled = folderObjectID != nil
            _fetchedResultsController = nil
            tableView.reloadData()
        }
    }

    var folder: Folder?

    let managedObjectContext: NSManagedObjectContext = {
        let parentContext = CoreDataStack.shared.persistentContainer.viewContext
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parentContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    var _fetchedResultsController: NSFetchedResultsController<Item>?
    var fetchedResultsController: NSFetchedResultsController<Item> {

        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        if let folderObjectID = self.folderObjectID {
            fetchRequest.predicate = NSPredicate(format: "folder == %@", folderObjectID)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.date, ascending: true)]

        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: managedObjectContext,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
        aFetchedResultsController.delegate = self

        do {
            try aFetchedResultsController.performFetch()
        } catch {
            fatalError("Error.")
        }

        _fetchedResultsController = aFetchedResultsController

        return _fetchedResultsController!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        let addBarButton = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] (action) in
            self?.createItem(action)
        }))
        navigationItem.rightBarButtonItem = addBarButton

        addBarButton.isEnabled = folderObjectID != nil
        
        CoreDataStack.shared.persistentContainer.viewContext.undoManager = UndoManager()
        managedObjectContext.undoManager = UndoManager()

        // Please see for getting information about iPad shortcut command here:
        // https://developer.apple.com/documentation/uikit/uicommand/adding_menus_and_shortcuts_to_the_menu_bar_and_user_interface
        let undoCommand = UIKeyCommand(input: "Z", modifierFlags: .command, action: #selector(undo(sender:)))
        let redoCommand = UIKeyCommand(input: "Z", modifierFlags: [.command, .shift], action: #selector(redo(sender:)))
        addKeyCommand(undoCommand)
        addKeyCommand(redoCommand)

    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

        if action == #selector(undo(sender:)) || action == #selector(redo(sender:)) {
            return true
        }

        return super.canPerformAction(action, withSender: sender)
    }

    @objc private func undo(sender: Any) {

        managedObjectContext.undo()
    }

    @objc private func redo(sender: Any) {
        managedObjectContext.redo()
    }


    @IBAction func createItem(_ sender: Any) {
        let createFolderAlertController = UIAlertController(title: "Create Item", message: nil, preferredStyle: .alert)
        createFolderAlertController.addTextField { (textField) in
            textField.placeholder = "Enter item name."
        }
        createFolderAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            createFolderAlertController.dismiss(animated: true, completion: nil)
        }))
        createFolderAlertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] (_) in
            if let textField = createFolderAlertController.textFields?.first {
                self?.createItem(from: textField.text)
            }
            createFolderAlertController.dismiss(animated: true, completion: nil)
        }))
        present(createFolderAlertController, animated: true, completion: nil)
    }

    func createItem(from title: String?) {
        let item = Item(context: managedObjectContext)
        item.title = title
        item.date = Date()
        item.folder = self.folder

        CoreDataStack.shared.saveContext()
    }

    func deleteItem(from indexPath: IndexPath) {
        let deleteExpectedFolder = fetchedResultsController.object(at: indexPath)
        managedObjectContext.delete(deleteExpectedFolder)

        CoreDataStack.shared.saveContext()
    }

    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .full
        return df
    }()

    func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let folder = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = folder.title
        cell.detailTextLabel?.text = Self.dateFormatter.string(from: folder.date!)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        configure(cell, at: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, _) in
            self?.deleteItem(from: indexPath)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

}

extension DetailViewController : NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .insert:

            guard let newIndexPath = newIndexPath else {
                return
            }

            tableView.insertRows(at: [newIndexPath], with: .automatic)

        case .delete:

            guard let indexPath = indexPath else {
                return
            }

            tableView.deleteRows(at: [indexPath], with: .automatic)

        case .update:

            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) else {
                return
            }

            configure(cell, at: indexPath)

        case .move:

            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {
                return
            }

            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)

        @unknown default:
            fatalError("New NSFetchedResultsChangeType has added by API changes.")
        }


    }

}

