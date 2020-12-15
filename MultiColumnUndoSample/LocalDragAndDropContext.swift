//
//  LocalDragAndDropContext.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import Foundation

/// A local context of drag & drop.
class LocalDragAndDropContext<Item> {

    /// The author of D&D context.
    var author: String

    /// The box of items.
    var items: [Item]

    init(author: String, items: [Item]) {
        self.author = author
        self.items = items
    }

}
