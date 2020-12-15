//
//  PrimaryViewController+TableViewDelegate.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import UIKit

extension PrimaryViewController {

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, _) in
            self?.deleteFolder(from: indexPath)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setFolderToDetail(indexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

        // Setting new date acts as move in this app context.
        let moveExpectedFolder = fetchedResultsController.object(at: sourceIndexPath)
        let destinationFolder = fetchedResultsController.object(at: destinationIndexPath)
        let expectedDate = destinationFolder.date! + 0.0001

        isUserDriven = true
        moveExpectedFolder.date = expectedDate

        try! managedObjectContext.save()
    }

}
