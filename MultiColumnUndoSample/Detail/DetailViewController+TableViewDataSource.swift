//
//  DetailViewController+TableViewDataSource.swift
//  MultiColumnUndoSample
//
//  Created by yosshi4486 on 2020/12/15.
//

import UIKit

extension DetailViewController {

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

}
