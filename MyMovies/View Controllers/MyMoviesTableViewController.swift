//
//  MyMoviesTableViewController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import CoreData

class MyMoviesTableViewController: UITableViewController {

    lazy var fetchedResultsController: NSFetchedResultsController<Movie> = {
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "hasWatched", ascending: true), NSSortDescriptor(key: "title", ascending: true)]
        let context = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "hasWatched", cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    private let movieController = MovieController.shared
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func refresh(_ sender: Any) {
        movieController.read { _ in
            self.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyMovieCell", for: indexPath) as! MovieTableViewCell
        cell.label.text = fetchedResultsController.object(at: indexPath).title
        cell.movie = fetchedResultsController.object(at: indexPath)
        if fetchedResultsController.object(at: indexPath).hasWatched {
            cell.button.setTitle("Watched", for: .normal)
        } else {
            cell.button.setTitle("Unwatched", for: .normal)
        }
        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
           let movie = fetchedResultsController.object(at: indexPath)
            movieController.delete(movie) { error in
                if let error = error {
                    print("Error deleting movie from server: \(error)")
                    return
                }
                 CoreDataStack.shared.mainContext.delete(movie)
                do {
                    try CoreDataStack.shared.mainContext.save()
                } catch {
                    CoreDataStack.shared.mainContext.reset()
                    NSLog("Error saving managed object context: \(error)")
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = fetchedResultsController.sections?[section] else { return nil }
        if section.name == "0" { return "Unwatched" }
        else { return "Watched" }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if fetchedResultsController.object(at: indexPath).overview?.isEmpty ?? true { tableView.deselectRow(at: indexPath, animated: true); return }
        let description = UIAlertController(title: fetchedResultsController.object(at: indexPath).title, message: fetchedResultsController.object(at: indexPath).overview, preferredStyle: .actionSheet)
        description.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
        tableView.deselectRow(at: indexPath, animated: true)
        self.present(description, animated: true)
    }
}

extension MyMoviesTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            break
        }
    }
}
