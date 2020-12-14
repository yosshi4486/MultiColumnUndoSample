//
//  PrimaryViewController.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/14.
//

import UIKit
import CoreData

final class PrimaryViewController : UITableViewController {

    private var managedObjectContext: NSManagedObjectContext {
        return CoreDataStack.shared.persistentContainer.viewContext
    }

    var _fetchedResultsController: NSFetchedResultsController<Folder>?
    var fetchedResultsController: NSFetchedResultsController<Folder> {

        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest = NSFetchRequest<Folder>(entityName: "Folder")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.date, ascending: true)]

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


    @IBAction func createFolder(_ sender: Any) {
        let createFolderAlertController = UIAlertController(title: "Create Folder", message: nil, preferredStyle: .alert)
        createFolderAlertController.addTextField { (textField) in
            textField.placeholder = "Enter folder name."
        }
        createFolderAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            createFolderAlertController.dismiss(animated: true, completion: nil)
        }))
        createFolderAlertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] (_) in
            if let textField = createFolderAlertController.textFields?.first {
                self?.createFolder(from: textField.text)
            }
            createFolderAlertController.dismiss(animated: true, completion: nil)
        }))
        present(createFolderAlertController, animated: true, completion: nil)
    }

    func createFolder(from title: String?) {
        let folder = Folder(context: managedObjectContext)
        folder.title = title
        folder.date = Date()

        CoreDataStack.shared.saveContext()
    }

    func deleteFolder(from indexPath: IndexPath) {
        let deleteExpectedFolder = fetchedResultsController.object(at: indexPath)
        managedObjectContext.delete(deleteExpectedFolder)

        CoreDataStack.shared.saveContext()
    }

    func setFolderToDetail(indexPath: IndexPath) {

        guard let detailViewController = splitViewController?.viewController(for: .secondary) as? DetailViewController else {
            return
        }

        let folder = fetchedResultsController.object(at: indexPath)
        detailViewController.folderObjectID = folder.objectID
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
            self?.deleteFolder(from: indexPath)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setFolderToDetail(indexPath: indexPath)
    }


}

extension PrimaryViewController : NSFetchedResultsControllerDelegate {

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

