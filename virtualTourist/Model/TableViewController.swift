//
//  TableViewController.swift
//  virtualTourist
//
//  Created by Geek on 3/31/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import MapKit
import UIKit

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noPlacesLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var places: [Place?] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        tableView.delegate = self
        tableView.dataSource = self
        noPlacesLabel.isHidden = true
        let tabController = tabBarController as! TabBarViewController
        places = tabController.places
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Places"
        
        if self.places.count == 0{
            noPlacesLabel.isHidden = false
            return
        }
        
        let region = MKCoordinateRegion(center: (places[0]?.coordinates)!, latitudinalMeters: 100_000, longitudinalMeters: 100_000)
        mapView.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = (places[0]?.coordinates)!
        mapView.addAnnotation(annotation)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        activityIndicator.stopAnimating()
        let photosItem = self.places[(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
        cell.textLabel?.text = photosItem!.title
        // create url
        let imageURL = URL(string: photosItem!.image)!
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
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch (editingStyle) {
        case .delete:
            let photosItem = self.places[(indexPath as NSIndexPath).row]
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
            places.removeObject(obj: photosItem)
            tableView.endUpdates()
            break
        default:
            return
        }
    }
}
