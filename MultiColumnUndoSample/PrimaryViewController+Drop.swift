//
//  PrimaryViewController+Drop.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import UIKit

extension PrimaryViewController : UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        var dropProposal = UITableViewDropProposal(operation: .cancel)

        if tableView.hasActiveDrag {
            // If .move is specified, `tableView
            dropProposal = UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            dropProposal = UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
        }

        return dropProposal
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {

        if let destinationIndexPath = coordinator.destinationIndexPath, coordinator.proposal.intent == .insertIntoDestinationIndexPath {

            let folder = fetchedResultsController.object(at: destinationIndexPath)

            coordinator.session.loadObjects(ofClass: NSString.self) { (items) in
                DispatchQueue.main.async {
                    // Item's FRC receive managedObjectDidUpdate notification of appending new items, then update the associated table immediately.
                    folder.appendNewItems(by: items as! [String])
                }
            }
        }

    }

}

extension Folder {

    func appendNewItems(by titles: [String]) {
        for title in titles {
            let item = Item(context: managedObjectContext!)
            item.title = title
            item.date = Date()
            item.folder = self
        }
        try! managedObjectContext?.save()
    }

}
