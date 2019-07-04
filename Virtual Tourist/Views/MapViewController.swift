//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Tucker on 6/24/19.
//  Copyright © 2019 Tucker. All rights reserved.
//

import UIKit
import MapKit
import CoreData

extension MKMapView {
    
    /*
     MARK: get zoom about for MapView
    */
    
    func topCenterCoordinate() -> CLLocationCoordinate2D {
        return self.convert(CGPoint(x: self.frame.size.width / 2.0, y: 0), toCoordinateFrom: self)
    }
    
    func currentRadius() -> Double {
        let centerLocation = CLLocation(latitude: self.centerCoordinate.latitude, longitude: self.centerCoordinate.longitude)
        let topCenterCoordinate = self.topCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        return centerLocation.distance(from: topCenterLocation)
    }
    
}


class MapViewController: UIViewController,MKMapViewDelegate{
    // IBoutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var isEdit: UIButton!
    
    /*
     MARK: IBAction
     changes between add and remove a pin
     shows/Hides red edit button
     */
    @IBAction func editPins(_ sender: Any) {
        
        isEdit.isHidden = removePinMode
        if removePinMode == false{
            removePinMode = true
        }else{
            removePinMode = false
        }
    }
    
    /*
     MARK: Defaults
     editing mode is disable
     userDefaults used save app settings
    */
    var removePinMode = false
    let defaults = UserDefaults.standard
    
    
    /*
     MARK: viewWillAppear
     fetchs,loads and displays all saved pins
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pin")
        
        do {
            let savedPins = try managedContext.fetch(fetchRequest)
            // prevent re-adding pins to the map
            if mapView.annotations.count < savedPins.count {
                for pin in savedPins{
                    let long = pin.value(forKeyPath: "longitude") as? Double
                    let lat = pin.value(forKeyPath:"Latitude") as? Double
                    let coordiantes = CLLocationCoordinate2D(latitude:lat!  , longitude: long!)
                    let geoAnnotation = MKPointAnnotation()
                    geoAnnotation.coordinate = coordiantes
                    self.mapView.addAnnotation(geoAnnotation)
                }
            }
        } catch let error as NSError {
            error.alert(with: self)
        }
    }
    
    /*
     MARK: viewDidLoad
     sets mapView to last saved region within userdefaults
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPinLocation(longGesture:)))
        mapView.addGestureRecognizer(longGesture)
        let regionRadius = defaults.double(forKey:"Distance")
        let lat = defaults.double(forKey: "Lat")
        let long = defaults.double(forKey: "Long")
        if (lat != 0.0 && long != 0.0){
            let coordiantes = CLLocationCoordinate2D(latitude:lat  , longitude: long)
            let coordianteRegion = MKCoordinateRegion(center: coordiantes, latitudinalMeters: regionRadius,longitudinalMeters: regionRadius)
            // set as current map region
            self.mapView.setRegion(coordianteRegion, animated: true)
        }
        
    }
    
    /*
     MARK: mapView viewFor annotation
     set up annotations
    */
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation:annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor.darkGray
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            pinView!.annotation = annotation
            
            let long = pinView!.annotation!.coordinate.longitude
            let  lat = pinView!.annotation!.coordinate.latitude
            
            let appDelegate =
                UIApplication.shared.delegate as! AppDelegate
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            let fetchRequest =
                NSFetchRequest<NSManagedObject>(entityName: "Pin")
            fetchRequest.predicate = NSPredicate(format:"longitude==\(long)")
            fetchRequest.predicate = NSPredicate(format:"latitude==\(lat)")
            
            do {
                let savedPins = try managedContext.fetch(fetchRequest)
                
                if savedPins.count == 0{
                    
                    fullSearchForGeoBasedImages(Long:(pinView?.annotation?.coordinate.longitude)!, Lat:(pinView?.annotation?.coordinate.latitude)!, pin: pinView!, shouldSave: true)
                }else{
                    
                    let save = savedPins[0] as! Pin
                    if save.pinColor == "red"{
                        pinView!.pinTintColor = UIColor.red
                    }
                    if save.pinColor == "green"{
                        pinView!.pinTintColor = UIColor(red:0.20, green:0.74, blue:0.28, alpha:1.0)
                    }
                }
            } catch let error as NSError {
                error.alert(with: self)
            }
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    /*
     MARK: mapView regionDidChangeAnimated
     save map location when it has been changed
    */
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let currentLocation = mapView.centerCoordinate
        let zoom = mapView.currentRadius()
        defaults.set(zoom, forKey: "Distance")
        defaults.set(currentLocation.latitude,forKey: "Lat")
        defaults.set(currentLocation.longitude, forKey: "Long")
        
    }
    
    /*
     MARK: mapView didSelect annotation
     performs segue to PhotoAlbum view Controller with selected pin
     if enabled will delete selected pin
    */
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let pin = view.annotation as! MKPointAnnotation
        if removePinMode == false {
            
            let point = view as! MKPinAnnotationView
            
            let appDelegate =
                UIApplication.shared.delegate as! AppDelegate
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            let fetchRequest =
                NSFetchRequest<NSManagedObject>(entityName: "Pin")
            
            let long = pin.coordinate.longitude
            let lat = pin.coordinate.latitude
            
            fetchRequest.predicate = NSPredicate(format:"longitude==\(long)")
            fetchRequest.predicate = NSPredicate(format:"latitude==\(lat)")
            
            do {
                let savedPins = try managedContext.fetch(fetchRequest)
                if savedPins.count != 0{
                    let save = savedPins[0] as! Pin
                    if save.pinColor == "green"{
                        performSegue(withIdentifier:"flickrSeque", sender: save)
                    }else{
                        throw CustomErrors.noPitcturesForLocation
                    }
                    
                }else{
                    fullSearchForGeoBasedImages(Long:pin.coordinate.longitude, Lat:pin.coordinate.latitude, pin:point, shouldSave: true)
                }
            } catch {
                error.customAlert(with: self)
            }
            
            mapView.deselectAnnotation(pin, animated: false)
            
        }else{
            
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pin")
            fetchRequest.predicate = NSPredicate(format: "longitude==\(pin.coordinate.longitude)")
            fetchRequest.predicate = NSPredicate(format:"latitude==\(pin.coordinate.latitude)")
            
            do {
                let pintoDelete = try managedContext.fetch(fetchRequest)
                for myPin in pintoDelete{
                    
                    managedContext.delete(myPin)
                    mapView.removeAnnotation(pin)
                }
                try managedContext.save()
            } catch let error as NSError {
                error.alert(with: self)
            }
            
        }
    }
    

    
    /*
     MARK: fullSearchForGeoBasedImages
     called out when a new pin is create in the mapView
     gets pictures related to pins location
     for every picture a photo entity is created and related to the pin entity
     */
    
    func fullSearchForGeoBasedImages(Long:Double, Lat:Double, pin:MKPinAnnotationView,shouldSave:Bool) -> Void{
        let geoSearchUrl:URL = buildUrl(lat:Lat, long:Long, pageNumber: 1).url!
        
        get(url:geoSearchUrl){ (output,response,error) in
            if output != nil{
                do {
                    try jsonDecoder(data: output!, type: Pictures.self) {
                        (decodedPins) in
                        var color = "green"
                        pin.pinTintColor = UIColor(red:0.20, green:0.74, blue:0.28, alpha:1.0)
                        
                        if (Int(decodedPins.photos.total) == 0){
                            pin.pinTintColor = UIColor.red
                            color = "red"
                        }
                        
                        if shouldSave == true{
                            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
                                return
                            }
                            
                            let managedContext = appDelegate.persistentContainer.viewContext
                            let pin = Pin(context:managedContext)
                            pin.url = geoSearchUrl
                            pin.latitude = Lat
                            pin.longitude = Long
                            pin.pinColor = color
                            pin.maxPage = Int32(decodedPins.photos.pages)
                            for urlParts in decodedPins.photos.photo{
                                let photo = Photo(context: managedContext)
                                let myurl:URL = buildImageUrlV2(server: urlParts.server, id: urlParts.id, secret: urlParts.secret, farm: urlParts.farm).url!
                                
                                photo.photoUrl = myurl
                                photo.pinUrl = geoSearchUrl
                                pin.addToTooPhoto(photo)
                            }
                            do {
                                try managedContext.save()
                            } catch let error as NSError{
                                error.alert(with: self)
                            }
                        }
                    }
                } catch {
                    error.alert(with: self)
                }
            }else{
                error!.alert(with: self)
                pin.pinTintColor = UIColor.gray
            }
        }
    }
    
    /*
     MARK: addPinLocation
     will drop the pin on the map with a long hold gesture
    */
    
    @objc func addPinLocation(longGesture: UIGestureRecognizer) -> Void {
        if removePinMode == false{
            if (longGesture.state != UIGestureRecognizer.State.began){
                return;
            }else{
                let touchPoint = longGesture.location(in: mapView)
                let wayCoords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                let wayAnnotation = MKPointAnnotation()
                wayAnnotation.coordinate = wayCoords
                self.mapView.addAnnotation(wayAnnotation)
            }
        }
    }
    
    /*
     MARK: prepare segue
     manages segue when pin is tapped
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "flickrSeque" {
            if let player = sender as? Pin {
                let flickrVC = segue.destination as! PhotoAlbumViewController
                flickrVC.imagesForLocation = player
            }
        }
    }
    
}

