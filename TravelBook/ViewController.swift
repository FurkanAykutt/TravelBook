//
//  ViewController.swift
//  TravelBook
//
//  Created by Furkan Aykut on 26.09.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var titleArray = [String]()
    var idArray = [UUID]()
    var annotationCoordinate: CLLocationCoordinate2D?
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    var selectedTitle = ""
    var selectedTitleID : UUID?
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != ""{
           // Core Data
            
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            fetchRequest.returnsObjectsAsFaults = false
            let idString = selectedTitleID!.uuidString
            print("id: \(idString)")
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0{
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                print("error")
            }
        }
        else{
            
            nameText.text = ""
            commentText.text = ""
        }
        
    }
    
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began{
            
            if nameText.text == ""{
                makeAlert(titleInput: "Error", messageInput: "Please enter name and comment before location")
            }
            else if commentText.text == ""{
                makeAlert(titleInput: "Error", messageInput: "Please enter name and comment before location")
            }
            else if selectedTitle == ""{
                let touchedPoint = gestureRecognizer.location(in: self.mapView)
                let touchedCoordinates = mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                chosenLatitude = touchedCoordinates.latitude
                chosenLongitude = touchedCoordinates.longitude
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinates
                annotationCoordinate = touchedCoordinates
                annotation.title = nameText.text
                annotation.subtitle = commentText.text
                self.mapView.addAnnotation(annotation)
            }
            else {
                self.mapView.removeAnnotations(self.mapView.annotations)
                let touchedPoint = gestureRecognizer.location(in: self.mapView)
                let touchedCoordinates = mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                
                chosenLatitude = touchedCoordinates.latitude
                chosenLongitude = touchedCoordinates.longitude
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinates
                annotationCoordinate = touchedCoordinates
                annotation.title = nameText.text
                annotation.subtitle = commentText.text
                self.mapView.addAnnotation(annotation)
                
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation{
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                if let placemark = placemarks {
                    if placemark.count > 0{
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    

    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let isValid : Bool = areAllTextValid()
        if isValid {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            
            if selectedTitle == ""  {
                saveData(context: context)
            }
            
            else{
                updateData(context: context)
            }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    func areAllTextValid() -> Bool {
        var isValid : Bool = false
        if nameText.text == ""{
            makeAlert(titleInput: "Error", messageInput: "Please insert name to Place")
        }
        else if commentText.text == ""{
            makeAlert(titleInput: "Error", messageInput: "Please insert comment to Place")
        }
        else if annotationCoordinate == nil {
            makeAlert(titleInput: "Error", messageInput: "Please select location")
        }
        else{
            isValid = true
        }
        return isValid
    }
    
    func makeAlert(titleInput : String, messageInput : String){
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveData(context:NSManagedObjectContext){
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(UUID(), forKey: "id")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        
        do{
            try context.save()
            print("success")
        }catch{
            print("error")
        }
    }
    
    func updateData(context : NSManagedObjectContext ) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        let idString = selectedTitleID!.uuidString
        fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            if results.count > 0{
                for result in results as! [NSManagedObject]{
                    result.setValue(nameText.text, forKey: "title")
                    result.setValue(commentText.text, forKey: "subtitle")
                    result.setValue(chosenLatitude, forKey: "latitude")
                    result.setValue(chosenLongitude, forKey: "longitude")
                }
            }
            do{
                try context.save()
                print("Saved")
            }catch{
                print("Error")
            }
        }catch{
            print("error")
        }
    }
    
 
}


