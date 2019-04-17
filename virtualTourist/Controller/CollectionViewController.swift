//
//  CollectionViewController.swift
//  virtualTourist
//
//  Created by Geek on 4/1/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class CollectionViewController:  UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noPlaceLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    
    var pin: Pin? = nil
    var dataController: DataController!
    private var blockOperation = BlockOperation()
    let fetchRequest:NSFetchRequest<Place> = Place.fetchRequest()
    var fetchedResultsController:NSFetchedResultsController<Place>!
    var selectedItems = [IndexPath]()
    
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        noPlaceLabel.isHidden = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        let tabController = tabBarController as! TabBarViewController
        pin = tabController.pin
        collectionView?.allowsMultipleSelection = true
        dataController = tabController.dataController
        fetchConfig()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Album"
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
        collectionView.reloadData()
    }
    
    func fetchConfig(){
        let predicate = NSPredicate(format: "pin == %@", pin!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin)-album")
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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        activityIndicator.startAnimating()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photosItem = fetchedResultsController.object(at: indexPath)
        let imageURL = URL(string: photosItem.image!)!
        let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            if error == nil {
                // create image
                let downloadedImage = UIImage(data: data!)
                // update UI on a main thread
                DispatchQueue.main.async{
                    self.activityIndicator.stopAnimating()
                    cell.placeImage.image = downloadedImage
                    cell.backgroundView = cell.placeImage
                    let backgroundView = cell.checkmark
                    backgroundView!.image = UIImage(named: "checkmark")
                    cell.selectedBackgroundView = backgroundView
                }
            } else {
                print(error!)
            }
        }
        // start network request
        task.resume()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
            newCollection.title = "Delete Selected Photos"
            selectedItems.append(indexPath)
    }
    
    @IBAction func deleteSelectedItems(_ sender: Any) {
        newCollection.title = "New Collection"
        for item in selectedItems{
            let photoToDelete = fetchedResultsController.object(at: item)
            dataController.viewContext.delete(photoToDelete)
            try? dataController.viewContext.save()
        }
        selectedItems = []
        collectionView.reloadData()
    }
}

extension CollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperation = BlockOperation()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionIndexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            blockOperation.addExecutionBlock {
                self.collectionView?.insertSections(sectionIndexSet)
            }
        case .delete:
            blockOperation.addExecutionBlock {
                self.collectionView?.deleteSections(sectionIndexSet)
            }
        case .update:
            blockOperation.addExecutionBlock {
                self.collectionView?.reloadSections(sectionIndexSet)
            }
        case .move:
            assertionFailure()
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { break }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.insertItems(at: [newIndexPath])
            }
        case .delete:
            guard let indexPath = indexPath else { break }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.deleteItems(at: [indexPath])
            }
        case .update:
            guard let indexPath = indexPath else { break }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.reloadItems(at: [indexPath])
            }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            
            blockOperation.addExecutionBlock {
                self.collectionView?.moveItem(at: indexPath, to: newIndexPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({
            self.blockOperation.start()
        }, completion: nil)
    }
}
extension Array {
    func indexOfObject(object : AnyObject) -> NSInteger {
        return (self as NSArray).index(of: object)
    }
    
    mutating func removeObject<T>(obj: T) where T : Equatable {
        self = self.filter({$0 as? T != obj})
    }
}
