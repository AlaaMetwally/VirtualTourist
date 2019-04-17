//
//  TableViewController.swift
//  virtualTourist
//
//  Created by Geek on 3/31/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noPlacesLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var fetchedResultsController:NSFetchedResultsController<Place>!
    let fetchRequest:NSFetchRequest<Place> = Place.fetchRequest()

    var pin: Pin? = nil
    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        tableView.delegate = self
        tableView.dataSource = self
        noPlacesLabel.isHidden = true
        let tabController = tabBarController as! TabBarViewController
        pin = tabController.pin
        dataController = tabController.dataController
        let fetchRequest:NSFetchRequest<Place> = Place.fetchRequest()
        fetchConfig()
    }
    
    func fetchConfig(){
        let predicate = NSPredicate(format: "pin == %@", pin!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin)-places")
        print(fetchRequest)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Places"
        
        var coordinate: CLLocationCoordinate2D {
            get {
                let coordinate = CLLocationCoordinate2DMake(self.pin!.latitude as! CLLocationDegrees, self.pin!.longitude as! CLLocationDegrees)
                return coordinate
            }
        }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100_000, longitudinalMeters: 100_000)
        mapView.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        fetchConfig()
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        activityIndicator.stopAnimating()
        let photosItem = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
        cell.textLabel?.text = photosItem.title
        // create url
        
        if let imageURL = URL(string: photosItem.image!) {
            // create network request
            let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                if error == nil {
                    // create image
                    let downloadedImage = UIImage(data: data!)
                    // update UI on a main thread
                    DispatchQueue.main.async{
                        self.activityIndicator.stopAnimating()
                        cell.imageView?.image = downloadedImage
                    }
                } else {
                    print(error!)
                }
            }
            // start network request
            task.resume()
        }
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch (editingStyle) {
        case .delete:
            let photosItem = fetchedResultsController.object(at: indexPath)
            dataController.viewContext.delete(photosItem)
            try? dataController.viewContext.save()
        default:
            return
        }
    }
}

extension TableViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: tableView.insertSections(indexSet, with: .fade)
        case .delete: tableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
        
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
