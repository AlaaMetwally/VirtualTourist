//
//  Map.swift
//  virtualTourist
//
//  Created by Geek on 3/28/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    
    // The map. See the setup in the Storyboard file. Note particularly that the view controller
    // is set up as the map view's delegate.
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var dataController: DataController!
    var editButtonIsTapped = false
    var pin: Pin? = nil
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()

    override func viewDidLoad() {
        super.viewDidLoad()
        toolBar.isHidden = true
        mapView.delegate = self
        var annotations = [MKPointAnnotation]()
        self.mapView.addAnnotations(annotations)
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            for dictionary in result.dropLast() {
                let lat = CLLocationDegrees(dictionary.latitude as! Double)
                let long = CLLocationDegrees(dictionary.longitude as! Double)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            if let lastPin = result.last {
            var coordinate: CLLocationCoordinate2D {
                get {
                    let coordinate = CLLocationCoordinate2DMake(lastPin.latitude as! CLLocationDegrees, lastPin.longitude as! CLLocationDegrees)
                    return coordinate
                }
            }
               
                let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100_000, longitudinalMeters: 100_000)
                mapView.setRegion(region, animated: false)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
                
        }
            self.mapView.addAnnotations(annotations)
        }
    }
    
    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.shared
            if let toOpen = view.annotation?.subtitle! {
                app.openURL(URL(string: toOpen)!)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        var latitude = (view.annotation?.coordinate.latitude)!
        var longitude = (view.annotation?.coordinate.longitude)!
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", "\(latitude)", "\(longitude)")
        fetchRequest.predicate = predicate
        
        if editButtonIsTapped{
            self.mapView.removeAnnotation(view.annotation!)
            if let result = try? dataController.viewContext.fetch(fetchRequest){
                for item in result{
                    dataController.viewContext.delete(item)
                    try? dataController.viewContext.save()
                }
            }
            return
        }
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.predicate = predicate
        guard let pin = (try? dataController.viewContext.fetch(fr))!.first else {
            return
        }
        self.pin = pin as! Pin
        self.performSegue(withIdentifier: "PinSegue", sender: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func requestHandler(pin: Pin){
        var request = URLRequest(url: pin.flickrURL())
        /* 4A. Make the request */
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* 5A. Parse the data */
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let photos = parsedResult["photos"] as? NSDictionary else{
                print("no photos")
                return
            }
          
            guard let arrayOfPhotos = photos["photo"] as? [NSDictionary] else {
                return
            }
            for photo in arrayOfPhotos{
                var place = Place(context: self.dataController.viewContext)
                place.image = photo["url_m"] as! String
                place.pin = pin
                place.title = photo["title"] as! String
                pin.places?.adding(place)
            }
        }
        /* 7A. Start the request */
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PinSegue" {
        let controller = segue.destination as! TabBarViewController
        controller.pin = self.pin
        controller.dataController = self.dataController
        }
    }

    @IBAction func editButton(_ sender: Any) {
        if editButtonIsTapped{
            toolBar.isHidden = true
            editButton.title = "Edit"
            editButtonIsTapped = false
        }else{
            toolBar.isHidden = false
            editButton.title = "Done"
            editButtonIsTapped = true
        }
    }
    @IBAction func addPinGesture(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        var pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = locCoord
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = locCoord.latitude
        pin.longitude = locCoord.longitude
        pin.creationDate = Date()
            
        requestHandler(pin: pin)
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "Pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        try? dataController.viewContext.save()
        self.pin = pin
        self.mapView.addAnnotation(pinAnnotation)
    }
    
}
