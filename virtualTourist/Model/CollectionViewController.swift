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

class CollectionViewController:  UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    var places: [Place?] = []
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noPlaceLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    var selectedItems: [Place?] = []

    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        noPlaceLabel.isHidden = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        let tabController = tabBarController as! TabBarViewController
        places = tabController.places
        collectionView?.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Album"
        
        if self.places.count == 0{
            noPlaceLabel.isHidden = false
            return
        }
        
        let region = MKCoordinateRegion(center: (places[0]?.coordinates)!, latitudinalMeters: 100_000, longitudinalMeters: 100_000)
        mapView.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = (places[0]?.coordinates)!
        mapView.addAnnotation(annotation)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        activityIndicator.startAnimating()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photosItem = places[(indexPath as NSIndexPath).row]
        let imageURL = URL(string: photosItem!.image)!
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
        let photosItem = places[(indexPath as NSIndexPath).row]
        newCollection.title = "Delete Selected Photos"
        selectedItems.append(photosItem)
    }
    
    @IBAction func deleteSelectedItems(_ sender: Any) {
        for item in selectedItems{
            places.removeObject(obj: item)
        }
        selectedItems.removeAll()
        newCollection.title = "New Collection"
        collectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let photosItem = places[(indexPath as NSIndexPath).row]
        selectedItems.removeObject(obj: photosItem!)
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
