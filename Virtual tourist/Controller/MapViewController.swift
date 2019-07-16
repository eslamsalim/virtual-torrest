//
//  ViewController.swift
//  Virtual tourist
//
//  Created by Eslam  on 5/11/19.
//  Copyright © 2019 Eslam. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let longtiudeKey = "map Center Longtiude"
    let latitudeKey = "map Center Latitude"
    let zoomKey = "zoom Key"

    var pinIcons : [Pins] = []
    var dataController : DataController!
    var fetchedResultsController:NSFetchedResultsController<Pins>!

    override func viewDidLoad() {
        super.viewDidLoad()
        //define a long gesture and add it to the mapview
        setupFetchedResultsController()

        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(longGesture:)))
        mapView.addGestureRecognizer(longGesture)
        mapView.centerCoordinate.latitude = UserDefaults.standard.double(forKey: latitudeKey)
        mapView.centerCoordinate.longitude = UserDefaults.standard.double(forKey: longtiudeKey)
        mapView.visibleMapRect.size.width = UserDefaults.standard.double(forKey: zoomKey)
        mapView.delegate = self
        
    }
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pins> = Pins.fetchRequest()
        
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            pinIcons = result
            for i in pinIcons{
            let annotation = MKPointAnnotation()
            let lat = i.latitude
            let lon = i.longitude
            let points = CLLocationCoordinate2DMake(lat, lon)
            annotation.coordinate = points
            mapView.addAnnotation(annotation)
            }
        }
        
        
//        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
//        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "notebooks")
//        //fetchedResultsController.delegate = self
//        do {
//            try fetchedResultsController.performFetch()
//        } catch {
//            fatalError("The fetch could not be performed: \(error.localizedDescription)")
//        }
    }
  
    @objc func addAnnotation (longGesture: UIGestureRecognizer){
        //get the location of the gesture in the mapview then convert it to coordinate
        let touchPoint = longGesture.location(in: mapView)
        let points = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        //add the anootaion at the corrdinate returned
        let annotation = MKPointAnnotation()
        annotation.coordinate = points
        annotation.title = "hi"
        mapView.addAnnotation(annotation)
        // persist icons
        let iconPin = Pins(context: dataController.viewContext)
        print(points.latitude,points.latitude)
        iconPin.latitude = points.latitude
        iconPin.longitude = points.longitude
        try? dataController.viewContext.save()
    }
}





extension MapViewController : MKMapViewDelegate {
    
    // what will happen when tap on the pin
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let zoomWidth = mapView.visibleMapRect.size.width
        let zoomFactor = Float(log2(zoomWidth)) - 9
        let center = mapView.centerCoordinate
        UserDefaults.standard.set(center.longitude, forKey: longtiudeKey)
        UserDefaults.standard.set(center.latitude, forKey: latitudeKey)
        UserDefaults.standard.set(zoomFactor, forKey: zoomKey)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        print (view.annotation?.coordinate.latitude)
        print (view.annotation?.coordinate.longitude)

        
        let Vc = self.storyboard?.instantiateViewController(withIdentifier: "ImagesViewController") as? ImagesViewController
        Vc?.lon = view.annotation?.coordinate.longitude
        Vc?.lat = view.annotation?.coordinate.latitude
            
        self.navigationController?.pushViewController(Vc!, animated: true)
    }
    
}

