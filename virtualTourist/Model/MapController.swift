//
//  Map.swift
//  virtualTourist
//
//  Created by Geek on 3/28/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import UIKit
import MapKit

class MapController: UIViewController, MKMapViewDelegate {
    
    // The map. See the setup in the Storyboard file. Note particularly that the view controller
    // is set up as the map view's delegate.
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var editButton: UIBarButtonItem!
    var editButtonIsTapped = false
    var places: [Place?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolBar.isHidden = true
        mapView.delegate = self
        let annotations = [MKPointAnnotation]()
        self.mapView.addAnnotations(annotations)
        
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
        view.setSelected(true, animated: false)
        if editButtonIsTapped{
            let pin = view.annotation
            self.mapView.removeAnnotation(pin!)
            return
        }

        let latitude = Double((view.annotation?.coordinate.latitude)!)
        let longitude = Double((view.annotation?.coordinate.longitude)!)
        let flickrConfig = FlickrConfig(latitude: latitude, longitude: longitude)
        requestHandler(flickrConfig: flickrConfig){ (places) -> Void in
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "PinSegue", sender: self)
            }
        }
    }
    
    func requestHandler(flickrConfig: FlickrConfig,completionHandler handler:@escaping([Place?]) -> Void){
        var request = URLRequest(url: flickrConfig.flickrURL())
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
            self.places = []
            for photo in arrayOfPhotos{
                var place = Place(title: photo["title"] as! String, image: photo["url_m"] as! String, coordinates: flickrConfig.coordinate as! CLLocationCoordinate2D)
                self.places.append(place)
            }
            handler(self.places)
        }
        /* 7A. Start the request */
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PinSegue" {
        let controller = segue.destination as! TabBarViewController
        controller.places = self.places
        }
    }
    
    @IBAction func addPin(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.mapView)
        let locCoord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = locCoord
 
        self.mapView.addAnnotation(annotation)
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
}
