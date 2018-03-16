//
//  ViewController.swift
//  Sample
//
//  Created by 李二狗 on 2018/3/16.
//  Copyright © 2018年 Meniny Lab. All rights reserved.
//

import UIKit
import Sqlable

struct User {
    var name: String
}

extension User: Sqlable {
    static let id = SQLColumn("id", .integer, PrimaryKey(autoincrement: true))
    static let name = SQLColumn("name", .text)
    static var tableLayout: [SQLColumn] = [id, name]
    
    func valueForColumn(_ column: SQLColumn) -> SQLValue? {
        switch column {
        case User.name:
            return self.name
        default:
            return nil
        }
    }
    
    init(row: SQLReadRow) throws {
        name = try row.get(User.name)
    }
}

let kUserDBName = "User.db"

class ViewController: UITableViewController {
    
    var dataSource: [User] = []
    
    @IBAction func insert(_ sender: UIBarButtonItem) {
        let alert = UIAlertController.init(title: "Insert", message: "Enter a name", preferredStyle: .alert)
        alert.addTextField { (t) in
            t.placeholder = "Name"
            t.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction.init(title: "Insert", style: .default, handler: { (_) in
            guard let name = alert.textFields?.first?.text else { return }
            self.insertUser(User.init(name: name))
            self.queryUsers()
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        self.present(alert, animated: true, completion: nil)
    }
    
    func insertUser(_ user: User) {
        do {
            let database = try setup()
            try user.insert(into: database)
        } catch {
            print(error)
        }
    }
    
    @IBAction func query(_ sender: UIBarButtonItem) {
        queryUsers()
    }
    
    func queryUsers() {
        do {
            let database = try setup()
            self.dataSource.removeAll()
            self.dataSource.append(contentsOf: try User.query(in: database))
            self.tableView.reloadData()
        } catch {
            print(error)
        }
    }
    
    func setup() throws -> SQLiteDatabase {
        let doc = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let database = try SQLiteDatabase.init(filepath: doc.appendingPathComponent(kUserDBName).path)
        try database.create(table: User.self)
        return database
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.queryUsers()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.text = self.dataSource[indexPath.row].name
        cell?.selectionStyle = .none
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
}
