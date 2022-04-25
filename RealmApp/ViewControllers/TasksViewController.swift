//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import RealmSwift
import Foundation
import SwiftUI

class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let task = taskList.tasks[indexPath.row]
        
        let deleteAction  = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.deleteTask(from: task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        var doneAction = UIContextualAction()
        if indexPath.section == 0 {
                doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
                StorageManager.shared.doneTask(task)
                let newIndex = IndexPath(row: 0, section: 1)
                tableView.moveRow(at: indexPath, to: newIndex)
                isDone(true)
            }
        } else {
                doneAction = UIContextualAction(style: .normal, title: "UnDone") { _, _, isDone in
                StorageManager.shared.doneTask(task)
                let newIndex = IndexPath(row: 0, section: 0)
                tableView.moveRow(at: indexPath, to: newIndex)
                isDone(true)
        }
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: task) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        editAction.backgroundColor = .orange
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction, doneAction])
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
}

extension TasksViewController {
    
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {

        let alert = AlertController.createAlert(withTitle: "New Task", andMessage: "What do you want to do?")

        alert.action(with: task) { newValue, note in
            if let task = task, let completion = completion {
                StorageManager.shared.editTask(task, newValue: newValue, newNote: note)
                completion()
            } else {
                self.saveTask(withName: newValue, andNote: note)
            }
            
        }
        present(alert, animated: true)
    }

    private func saveTask(withName name: String, andNote note: String) {
        let task = Task(value: [name, note])
        StorageManager.shared.saveTask(task, to: taskList)
        let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
}

