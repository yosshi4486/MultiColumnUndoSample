//
//  DetailViewController+Drag.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import UIKit
import MobileCoreServices

extension DetailViewController : UITableViewDragDelegate {

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return dragItems(for: indexPath, session: session)
    }

    func dragItems(for indexPath: IndexPath, session: UIDragSession) -> [UIDragItem] {
        let item = fetchedResultsController.object(at: indexPath)
        let data = (item.title ?? "").data(using: .utf8)

        if let localContext = session.localContext as? LocalDragAndDropContext<Item>, localContext.author == "SampleApp.Detail" {
            localContext.items.append(item)
            session.localContext = localContext
        } else {
            session.localContext = LocalDragAndDropContext(author: "SampleApp.Detail", items: [item])
        }

        let itemProvider = NSItemProvider()
        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePlainText as String, visibility: .all) { (completion) -> Progress? in
            completion(data, nil)
            return nil
        }

        return [UIDragItem(itemProvider: itemProvider)]
    }

}
