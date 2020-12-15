//
//  DetailViewController+FRCDelegate.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import CoreData

extension DetailViewController : NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        if isUserDriven {
            return
        }
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !isUserDriven {
            tableView.endUpdates()
        }
        isUserDriven = false
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        guard !isUserDriven else {
            return
        }

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
