//
//  ImagesViewController.swift
//  Virtual tourist
//
//  Created by Mac on 7/6/19.
//  Copyright © 2019 Eslam. All rights reserved.
//

import UIKit
import MapKit

class ImagesViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    
    var lat : Double?
    var lon : Double?
    var coordinate : CLLocationCoordinate2D?
    let regionRadius: CLLocationDistance = 1000

    var imagesArray = [String]() {
        didSet {
            DispatchQueue.main.async {
                self.imagesCollectionView.reloadData()
            }
        }
    }
    
    var startIndex = 0
    
    var currentImagesArray = [String]() {
        didSet {
            DispatchQueue.main.async {
                self.imagesCollectionView.reloadData()
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.noImageLabel.isHidden = true
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        downloadImages()
        setUpMap()
        
    }
    var count = 0
    var start = 0
    var end   = 10
    @IBAction func newCollectionButtonPressed(_ sender: AnyObject) {
    }
    
    func setUpArray (){

        
    }
    func setUpMap (){
        self.coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate!
        mapView.addAnnotation(annotation)
        
        let initialLocation = CLLocation(latitude: self.lat!, longitude: self.lon!)
        centerMapOnLocation(location: initialLocation)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setCenter(self.coordinate!, animated: true)
    }
    
    func downloadImages() {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        displayImageFromFlickrBySearch(methodParameters as [String:AnyObject], withPageNumber: 1)
    }
    private func bboxString() -> String {
        return "\(self.lon! - 1) , \(self.lat! - 1) , \(self.lon! + 1), \(self.lat! + 1)"

        
    }
    
    private func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], withPageNumber: Int) {
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        
        methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                self.displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                self.displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                self.displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                self.displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                self.displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                self.displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                self.displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                self.displayError("No Photos Found. Search Again.")
                DispatchQueue.main.async {
                    self.imagesCollectionView.isHidden = true
                    self.noImageLabel.isHidden = false
                    self.noImageLabel.text = "No Photos Found. Search Again."
                }

                
                return
                
            } else {
                print (photosArray.last)
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]

                /* fill the array of images url */
                for i in photosArray{
                    
                    guard let imageUrlString = i[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        self.displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                        return
                    }
                    print (imageUrlString)
                    self.imagesArray.append(imageUrlString)
                }
            }
        }
      task.resume()
    }
    
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    func displayError(_ error: String) {
        print(error)
    }


}

extension ImagesViewController : UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imagesArray.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! CollectionViewCell
        cell.imageView?.image = UIImage(named: "placeHolder")
        
        if self.imagesArray.count != 0 {
        let imageUrl = self.imagesArray[(indexPath as NSIndexPath).row]
        if let url = URL(string: imageUrl){
            let logoImage = try? Data(contentsOf: url)
                if let logoImage = logoImage{
                    cell.imageView!.image = UIImage(data: logoImage)
                }
            }
        }
        
        return cell
    }
}

