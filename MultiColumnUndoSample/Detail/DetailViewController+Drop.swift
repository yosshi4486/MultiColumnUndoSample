//
//  DetailViewController+Drop.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import UIKit

extension DetailViewController : UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        
        var proposal = UITableViewDropProposal(operation: .cancel)

        if let localSession = session.localDragSession?.localContext as? LocalDragAndDropContext<Folder>, localSession.author == "SampleApp.Primary" {
            proposal = UITableViewDropProposal(operation: .cancel)
        } else if tableView.hasActiveDrag {
            // This proposal goes to move delegate method.
            proposal = UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            proposal = UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
        return proposal
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {

        let destinationIndexPath: IndexPath = {
            if let indexPath = coordinator.destinationIndexPath {
                return indexPath
            }

            let lastSectionIndex = tableView.numberOfSections - 1
            let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
            return IndexPath(row: lastRowIndex + 1, section: lastSectionIndex)
        }()

        let baseDate: Date = {
            guard destinationIndexPath.row > 1 else {
                return Date()
            }

            let previousDataIndexPath = IndexPath(row: destinationIndexPath.row - 1, section: destinationIndexPath.section)
            let previousItem = fetchedResultsController.object(at: previousDataIndexPath)
            return previousItem.date!
        }()

        coordinator.session.loadObjects(ofClass: NSString.self) { [unowned self] (items) in
            let stringItems = items as! [String]
            DispatchQueue.main.async {
                for (index, stringItem) in stringItems.enumerated() {
                    let item = Item(context: self.managedObjectContext)
                    item.title = stringItem
                    item.date = baseDate + (Double(index + 1) * 0.001) // millisecond
                    item.folder = self.folder
                }
                try! self.managedObjectContext.save()
            }
        }
    }

}
