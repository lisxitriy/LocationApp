//
//  LocationViewController.swift
//  LocationApp
//
//  Created by Olga Trofimova on 05.04.2021.
//

import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController {
    
    var managedObjectContext: NSManagedObjectContext!
    lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
        //        создаем запрос на выборку объекта
                let fetchRequest = NSFetchRequest<Location>()
        //ищем сущность Location
                let entity = Location.entity()
                fetchRequest.entity = entity
        //сообщаем запросу выборки о сортировке по атрибуту даты в возрастающем порядке, чтобы объекты Location, которые пользователь добавил первыми, были в верхней части списка.
        let sort1 = NSSortDescriptor(key: "category", ascending: true)
        let sort2 = NSSortDescriptor(key: "date", ascending: true)
                fetchRequest.sortDescriptors = [sort1, sort2]
//        показать 20 объуктов
        fetchRequest.fetchBatchSize = 20
        
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController

    }()
    
//   если больше не нужен NSFetchedResultsController, просто чтобы больше не получать уведомлений, которые все еще ожидают обработки.
//    deinit {
//      fetchedResultsController.delegate = nil
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performFetch()
        navigationItem.rightBarButtonItem = editButtonItem

    }
    
    //MARK: - Table View Delegates
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        
//        проверим, чтобы все работало
//        let descriptionLabel = cell.viewWithTag(100) as! UILabel
//        descriptionLabel.text = "If you can see this"
//
//        let addressLabel = cell.viewWithTag(101) as! UILabel
//        addressLabel.text = "Then it works"
        
        let location = fetchedResultsController.object(at: indexPath)
        
        cell.configure(for: location)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath
    ) {
      if editingStyle == .delete {
        let location = fetchedResultsController.object( at: indexPath)
        managedObjectContext.delete(location)
        do {
          try managedObjectContext.save()
        } catch {
          fatalCoreDataError(error)
        }
      }
    }

    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                let location = fetchedResultsController.object(at: indexPath)
                controller.locationToEdit = location
            }
        }
    }
    
    //MARK: - Helpers Method
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalCoreDataError(error)
        }
    }
    
}
// MARK: - NSFetchedResultsController Delegate Extension»

extension LocationsViewController: NSFetchedResultsControllerDelegate {
  func controllerWillChangeContent(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>
  ) {
    print("*** controllerWillChangeContent")
    tableView.beginUpdates()
  }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
              print("*** NSFetchedResultsChangeInsert (object)")
              tableView.insertRows(at: [newIndexPath!], with: .fade)

        case .delete:
              print("*** NSFetchedResultsChangeDelete (object)")
             tableView.deleteRows(at: [indexPath!], with: .fade)

        case .update:
            print("*** NSFetchedResultsChangeUpdate (object)")
                  if let cell = tableView.cellForRow(
                    at: indexPath!) as? LocationCell {
                    let location = controller.object(
                      at: indexPath!) as! Location
                    cell.configure(for: location)
                  }

        case .move:
            print("*** NSFetchedResultsChangeMove (object)")
                  tableView.deleteRows(at: [indexPath!], with: .fade)
                  tableView.insertRows(at: [newIndexPath!], with: .fade)

        @unknown default:
            print("*** NSFetchedResults unknown type")
                }
              }

              func controller(
                _ controller: NSFetchedResultsController<NSFetchRequestResult>,
                didChange sectionInfo: NSFetchedResultsSectionInfo,
                atSectionIndex sectionIndex: Int,
                for type: NSFetchedResultsChangeType
              ) {
                switch type {
                case .insert:
                  print("*** NSFetchedResultsChangeInsert (section)")
                  tableView.insertSections(
                    IndexSet(integer: sectionIndex), with: .fade)
                case .delete:
                  print("*** NSFetchedResultsChangeDelete (section)")
                  tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
                case .update:
                  print("*** NSFetchedResultsChangeUpdate (section)")
                case .move:
                  print("*** NSFetchedResultsChangeMove (section)")
                @unknown default:
                  print("*** NSFetchedResults unknown type")
                }
              }

              func controllerDidChangeContent(
                _ controller: NSFetchedResultsController<NSFetchRequestResult>
              ) {
                print("*** controllerDidChangeContent")
                tableView.endUpdates()
              }
}