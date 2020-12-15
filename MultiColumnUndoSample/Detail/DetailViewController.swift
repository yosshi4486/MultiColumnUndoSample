//
//  DetailViewController.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/14.
//

import UIKit
import CoreData

final class DetailViewController : UITableViewController {

    var isUserDriven: Bool = false

    var folder: Folder? {
        didSet {
            navigationItem.title = folder?.title
            navigationItem.rightBarButtonItem?.isEnabled = folder != nil
            _fetchedResultsController = nil
            tableView.reloadData()
        }
    }

    let managedObjectContext: NSManagedObjectContext = {
        return CoreDataStack.shared.persistentContainer.viewContext
    }()

    var _fetchedResultsController: NSFetchedResultsController<Item>?
    var fetchedResultsController: NSFetchedResultsController<Item> {

        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest = NSFetchRequest<Item>(entityName: "Item")
        if let folder = self.folder {
            fetchRequest.predicate = NSPredicate(format: "folder == %@", folder)
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
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true

        let addBarButton = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] (action) in
            self?.createItem(action)
        }))
        navigationItem.rightBarButtonItem = addBarButton

        addBarButton.isEnabled = folder != nil
        
        managedObjectContext.undoManager = UndoManager()

        // Please see for getting information about iPad shortcut command here:
        // https://developer.apple.com/documentation/uikit/uicommand/adding_menus_and_shortcuts_to_the_menu_bar_and_user_interface
        let undoCommand = UIKeyCommand(input: "Z", modifierFlags: .command, action: #selector(undo(sender:)))
        let redoCommand = UIKeyCommand(input: "Z", modifierFlags: [.command, .shift], action: #selector(redo(sender:)))
        addKeyCommand(undoCommand)
        addKeyCommand(redoCommand)

    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // In UISplitViewController, a responder event is dispatched to detailViewController at first, then it will be dispatched to primary.
        if (action == #selector(undo(sender:))) || (action == #selector(redo(sender:))) {
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

        try! managedObjectContext.save()
    }

    func deleteItem(from indexPath: IndexPath) {
        let deleteExpectedFolder = fetchedResultsController.object(at: indexPath)
        managedObjectContext.delete(deleteExpectedFolder)

        try! managedObjectContext.save()
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

}
