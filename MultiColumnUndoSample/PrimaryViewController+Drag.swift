//
//  PrimaryViewController+Drag.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import UIKit
import MobileCoreServices

extension PrimaryViewController : UITableViewDragDelegate {

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return dragItems(for: indexPath)
    }

    func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        let folder = fetchedResultsController.object(at: indexPath)

        let data = (folder.title ?? "").data(using: .utf8)

        // A strong💪 class to transfer data between processes without preparing any info.plist descriptions or entitlements.
        let itemProvider = NSItemProvider()

        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePlainText as String, visibility: .all) { (completion) in
            completion(data, nil)
            return nil
        }

        return [UIDragItem(itemProvider: itemProvider)]
    }

}
