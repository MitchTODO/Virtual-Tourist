//
//  FlickrPictureViewController.swift
//  Virtual Tourist
//
//  Created by Tucker on 6/24/19.
//  Copyright © 2019 Tucker. All rights reserved.
//

import UIKit
import Foundation
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,MKMapViewDelegate
{

    // outlets
    @IBOutlet weak var flickrCollections: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newColl: UIButton!
    
    // disimsses the delegate
    @IBAction func backToMap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // loads new collection when pressed
    @IBAction func newCollections(_ sender: Any) {
        showNewCollection()
    }
    
    // reuse ID for each cell
    let reuseIdentifier = "cell"
    
    // pin that is pressed
    var imagesForLocation:Pin?
    
    // used to relate cells to photos
    var urlList = [URL]()
    
    
    
    override func viewDidLoad() {
        mapView.delegate = self
        // allows for the reload of collection cells
        let int32 = Int32(imagesForLocation!.maxPage)
        let maxPage = Int(int32)
        // if maxPage is less then the current page dont allows for reload
        if maxPage < 2 {
            newColl.isEnabled = false
        }
        
        // set the mapview to correct location
        let regionRadius: CLLocationDistance = 100000
        let coordiantes = CLLocationCoordinate2D(latitude:imagesForLocation!.latitude  , longitude: imagesForLocation!.longitude)
        let coordianteRegion = MKCoordinateRegion(center: coordiantes, latitudinalMeters: regionRadius,longitudinalMeters: regionRadius)
        let geoAnnotation = MKPointAnnotation()
        
        // disable some functionality of the mapview
        geoAnnotation.coordinate = coordiantes
        self.mapView.setRegion(coordianteRegion, animated: true)
        self.mapView.isScrollEnabled = false
        self.mapView.isZoomEnabled = false
        
        // allows for mapView to be pressed
        self.mapView.isUserInteractionEnabled = true
        self.mapView.addAnnotation(geoAnnotation)
        
        // if mapView is pressed user to be dismissed back to mapViewController
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backToMap))
        
        // add annotation to the mapview
        self.mapView.addGestureRecognizer(tapGesture)
        
        // loop through every photo releated to pin thats pressed
        for a in imagesForLocation!.tooPhoto!{
            let toPhoto = a as? Photo
            //print (toPhoto?.photoUrl)
            // add the related photo url to "urlList"
            urlList.append(toPhoto!.photoUrl!)
        }

        
    }
    
    
    /**
     Build Collection View
     
    **/
    
    // amount of cells equals the amount of urls within 'urlList'
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urlList.count
    }
    
    // for each cell created
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // set reusable cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
        
        // default cell configuration
        cell.indicatorWithinCell.isHidden = false
        cell.indicatorWithinCell.startAnimating()
        
        // set placeholder image
        cell.imageWithinCell.image = UIImage(named: "imagePlaceHolder")
        
        // request for image related to each cell
        photoForCell(imageUrl: urlList[indexPath.item], cell: cell)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        // remove cell from collectionView
        // remove url from dataSet
        let cellToRemove = self.urlList[indexPath.item]
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // manages requests from CoreData
        let managedContext = appDelegate.persistentContainer.viewContext
        // make a request for photo
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photo")
        // url to string
        let urlString = String(cellToRemove.absoluteString)
        // match url from list to url in CoreData from enitiety Photo
        fetchRequest.predicate = NSPredicate(format:"photoUrl==%@",urlString)
        
        do {
            // execute fetch request for a match -> array
            let addImageToDate = try managedContext.fetch(fetchRequest)
            managedContext.delete(addImageToDate[0])
            try managedContext.save()
            
        } catch let error as NSError {
            error.alert(with: self)
        }
        
        self.urlList.remove(at: indexPath.item)
        self.flickrCollections.deleteItems(at: [indexPath])
        
        
    }
    func save(){
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        // save content
        let managedContext = appDelegate.persistentContainer.viewContext
        do{
        try managedContext.save()
        }catch let error as NSError{
            error.alert(with: self)
        }
    }
    
    func photoForCell(imageUrl:URL,cell:MyCollectionViewCell) -> Void{
        // app delegate for saving
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        // make a request for photo
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photo")
        // url to string
        let urlString = String(imageUrl.absoluteString)
        // match url from list to url in CoreData from enitiety Photo
        fetchRequest.predicate = NSPredicate(format:"photoUrl==%@",urlString)
        
        do {
            // execute fetch request for a match -> array
            let addImageToDate = try managedContext.fetch(fetchRequest)
            // if empty, some thing broke
            // a photo entity will alway have a realted url
           
            if addImageToDate.isEmpty{
                print ("This should never be printed out")
            }else{
                //  as Photo entity
                let theUrl = addImageToDate[0] as? Photo
                // if image is nil a request will be made for the image to populate cell and be save
                // URL == IMAGE
                if theUrl!.image == nil{
                    // make request
                    get(url:imageUrl) { (output,response,error) in
                        // check output for data
                        if output != nil{
                            let data = output!
                            // cast data as UIImage
                            if let image = UIImage(data: data) {
                                
                                theUrl?.image = data
                                self.save()
                                // set cell image
                                cell.imageWithinCell.image = image
                                
                                // stop and hide indicator
                                cell.indicatorWithinCell.stopAnimating()
                                cell.indicatorWithinCell.isHidden = true
                                
                            }
                        }else{
                            error!.alert(with: self)
                        }
                    }
                  
                // else a photo already exist
                // set the cell image
                }else{
                    // case save binary data to UIImage
                    let image = UIImage(data:theUrl!.image!)
                    // set cell image
                    cell.imageWithinCell.image = image
                    // stop and hide indicator
                    cell.indicatorWithinCell.stopAnimating()
                    cell.indicatorWithinCell.isHidden = true
                }
                
            }
        // CoreData failure
        } catch let error as NSError {
             error.alert(with: self)
        }
    }
    
    

    
    func showNewCollection() -> Void{

        // get random intager used as page number
        // must be between 2 and maxPage
        let int32 = Int32(imagesForLocation!.maxPage)
        let maxPage = Int(int32)
        let randomInt = Int.random(in: 2 ... maxPage)
        
        // long lat
        let long = imagesForLocation?.longitude
        let lat = imagesForLocation?.latitude
        
        // build new PIN url

        let geoSearchUrl:URL = buildUrl(lat:lat!, long:long!, pageNumber:randomInt).url!
        
        // appDelegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        // Coredata manager
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // make request for all photoURL related to that pin
        // (NEW PIN = OLD PIN + 1 page)
        get(url:geoSearchUrl){ (output,response,error) in
            // check output
            if output != nil{
                do {
                    // decode result has codable struct
                    try jsonDecoder(data: output!, type: Pictures.self) {
                        (decodedPins) in
                        // remove all photoUrl in urlList
                        self.urlList.removeAll()
                        // loop through all photos realted to new pin
                        for urlParts in decodedPins.photos.photo{
                            // build out each photo url
                            let myurl:URL = buildImageUrlV2(server: urlParts.server, id: urlParts.id, secret: urlParts.secret, farm: urlParts.farm).url!
                            // make new photo
                            let photo = Photo(context: managedContext)
                            
                            // set photo with newly create url
                            photo.photoUrl = myurl
                            photo.pinUrl = geoSearchUrl
                            // add relation from new Photo to old pin
                            // CHECK THIS
                            self.imagesForLocation!.addToTooPhoto(photo)
                            // append new url to urlList
                            self.urlList.append(myurl)
                            
                            
                        }
                        // reload collectons
                        // set collection to top of page
                        self.flickrCollections!.reloadData()
                        self.flickrCollections!.scrollToItem(at: IndexPath(row: 0, section: 0),at: .top,animated: false)
                    }
                     try managedContext.save()
                    
                } catch {
                    // handles errors
                    error.alert(with: self)
                }
            }else{
               print ("NO PIC")
            }
        }
    }
 
    
}
