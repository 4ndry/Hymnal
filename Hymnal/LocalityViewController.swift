//
//  LocalityViewController.swift
//  Hymnal
//
//  Created by Jacob Marttinen on 5/6/17.
//  Copyright © 2017 Jacob Marttinen. All rights reserved.
//

import UIKit
import MapKit

// MARK: - LocalityViewController: UIViewController

class LocalityViewController: UIViewController {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var locality: LocalityEntity!
    var photo: LocalityPhotoEntity!
    
    // MARK: Outlets
    
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var addressView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Actions
    
    @IBAction func addressViewTapped(_ sender: Any) {
        openMaps()
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialiseContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initialiseUI()
    }
    
    // MARK: UI+UX Functionality
    
    private func initialiseUI() {
        mapView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Contact",
            style: UIBarButtonItemStyle.plain,
            target: self,
            action: #selector(LocalityViewController.contactInformation)
        )
        navigationItem.title = "Locality"
    }
    
    private func initialiseContent() {
        titleView.text = locality.name
        
        // If the image has been loaded, set it immediately
        // Otherwise, download the image Data and set it
        if let imageData = photo.imageData {
            self.imageView.image = UIImage(data: imageData as Data)
        } else if let url = photo.url {
            DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
                if let imageData = try? Data(contentsOf: URL(string: url)!) {
                    self.appDelegate.stack.performBackgroundBatchOperation { (workerContext) in
                        self.photo.imageData = imageData as NSData
                    }
                    
                    DispatchQueue.main.async {
                        self.appDelegate.stack.save()
                        self.imageView.image = UIImage(data: imageData)
                    }
                }
            }
        }
        
        mapView.removeAnnotations(self.mapView.annotations)
        let lat = CLLocationDegrees(locality.locationLatitude)
        let long = CLLocationDegrees(locality.locationLongitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.title = "OALC of " + locality.name!
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500)
        mapView.setRegion(region, animated: false)
        
        addressView.text = locality.locationAddress! + "\n🚗"
        
        setNightMode(to: appDelegate.isDark)
    }
    
    private func setNightMode(to enabled: Bool) {
        if appDelegate.isDark != enabled {
            appDelegate.isDark = enabled
            UserDefaults.standard.set(appDelegate.isDark, forKey: "hymnIsDark")
            UserDefaults.standard.synchronize()
        }
        
        if enabled {
            UIApplication.shared.statusBarStyle = .lightContent
            
            view.backgroundColor = Constants.UI.Trout
            
            navigationController?.navigationBar.barTintColor = Constants.UI.Trout
            navigationController?.navigationBar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
            
            titleView.textColor = .white
            addressView.textColor = .white
            addressView.backgroundColor = Constants.UI.Trout
        } else {
            UIApplication.shared.statusBarStyle = .default
            
            view.backgroundColor = .white
            
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.tintColor = Constants.UI.Trout
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: Constants.UI.Trout]
            
            titleView.textColor = Constants.UI.Trout
            addressView.textColor = Constants.UI.Trout
            addressView.backgroundColor = .white
        }
    }
    
    func contactInformation() {
        let contactViewController = storyboard!.instantiateViewController(
            withIdentifier: "ContactViewController"
        ) as! ContactViewController
        contactViewController.locality = locality
        navigationController!.pushViewController(contactViewController, animated: true)
    }
    
    func openMaps() {       
        CLGeocoder().geocodeAddressString(locality.locationAddress!, completionHandler: {(placemarks, error) in
            if error == nil, placemarks!.count > 0 {
                let placemark = placemarks![0]
                if let addressDict = placemark.addressDictionary as? [String:AnyObject], let coordinate = placemark.location?.coordinate {
                    let mapItem = MKMapItem(placemark:MKPlacemark(coordinate: coordinate, addressDictionary: addressDict))
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: launchOptions)
                }
            }
        })
    }
}

// MARK: - LocalityViewController: MKMapViewDelegate

extension LocalityViewController: MKMapViewDelegate {
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
        mapView.deselectAnnotation(didSelect.annotation!, animated: false)
        openMaps()
    }
}
