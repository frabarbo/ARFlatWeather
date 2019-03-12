//
//  ViewController.swift
//  ARFlatWeather
//
//  Created by Francesco Barbolan on 08.03.19.
//  Copyright © 2019 Francesco Barbolan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate, SCNSceneRendererDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var tempToday = ("","")
    var tempTomorrow = ("","")
    var tempAfterTomorrow = ("","")
    var tempAfterAfterTomorrow = ("","")
    var location = ""
    
    var fontSizeAR : CGFloat = 1.0
    var fontSizeARsmall : CGFloat = 0.8
    
    var scene =  SCNScene()
    var boxNode = SCNNode()
    
//    var didFindLocation = false
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sceneView.debugOptions = [ ARSCNDebugOptions.showWorldOrigin]
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
//        locationManager.requestWhenInUseAuthorization();
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.startUpdatingLocation()
        }
        else{
            print("Location service disabled");
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //create a transparent gray layer
        let box = SCNBox(width: 10.3, height: 10.3, length: 0.005, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.clear
//        let material = SCNMaterial()
//        material.diffuse.contents = UIImage(named: "sun.png")
//        box.materials = [material]
        boxNode = SCNNode(geometry: box)
        boxNode.opacity = 0.5
    
        //TODO: set via HitTest
        boxNode.position = SCNVector3(0,0,-1.5)
        scene.rootNode.addChildNode(boxNode)
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    /* This method creates only Text Nodes.
     */
    func createTextNode(title: String, size: CGFloat, x: Float, y: Float, z: Float = 50){
        let text = SCNText(string: title, extrusionDepth: 0.5)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.font = UIFont(name: "Avenir Next", size: size)
        let textNode = SCNNode(geometry: text)
        textNode.position.x = boxNode.position.x - x
        textNode.position.y = boxNode.position.y - y
        textNode.position.z = boxNode.position.z - z
        textNode.geometry?.firstMaterial?.isDoubleSided = true
        
        scene.rootNode.addChildNode(textNode)
    }
    /* This method creates only Image Nodes.
     */
    func createImageNode(width: CGFloat, height: CGFloat, x: Float, y: Float, imageName: String, z: Float = 50)-> SCNNode{
        let imageNode = SCNNode()
        imageNode.geometry = SCNPlane.init(width: width, height: height)
        imageNode.geometry?.firstMaterial?.diffuse.contents = imageName
        imageNode.position.x = boxNode.position.x - x
        imageNode.position.y = boxNode.position.y - y
        imageNode.position.z = boxNode.position.z - z
        
        imageNode.geometry?.firstMaterial?.isDoubleSided = true
        scene.rootNode.addChildNode(imageNode)
        return imageNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    /* Get weather data from Open Weather API. Insert own API-TOKEN.
     */
    func getWeather(latitude: String, longitude: String){
        // napoli 40.833333°, 14.25°
        // caserta 41.066667°, 14.333333°
        
//        let openWeatherEndpoint = "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&units=metric&appid=6243c02604de2ed1242e77d372bc92a3" //API-TOKEN
        let openWeatherEndpoint = "https://api.openweathermap.org/data/2.5/forecast?lat=41.066667&lon=14.333333&units=metric&appid=6243c02604de2ed1242e77d372bc92a3" //API-TOKEN
        guard let url = URL(string: openWeatherEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = URLRequest(url: url)
        let session = URLSession.shared
        
    
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            guard error == nil else {
                print("error calling GET")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            do {
                guard let data = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        print("error trying to convert data to JSON")
                        return
                }
                guard let weatherList = data["list"] as? [[String: Any]] else {
                    print("Could not get weatherList from JSON")
                    return
                }
                //Get the weather for today and for the next 3 days
                for i in 0...3 {
                    if let main = weatherList[i]["main"] as? [String: Any] {
                        if var temp = main["temp"] as? Double{
                            temp.round()
                            switch i {
                            case 0: self.tempToday.0 = String(temp)
                            case 1: self.tempTomorrow.0 = String(temp)
                            case 2: self.tempAfterTomorrow.0 = String(temp)
                            default: self.tempAfterAfterTomorrow.0 = String(temp)
                            }
                            print(temp)
                        }
                    }
                    if let weather = weatherList[i]["weather"] as? [Any] {
                        if let object = weather.first as? [String: Any]{
                            if let main = object["main"] as? String {
                                var weatherDescription = main.lowercased()
                                if weatherDescription.contains("clear"){
                                    weatherDescription = "sun"
                                } else if weatherDescription.contains("cloud"){
                                    weatherDescription = "cloud"
                                } else {
                                    weatherDescription = "rain"
                                }
                                switch i {
                                case 0: self.tempToday.1 = String(weatherDescription)
                                case 1: self.tempTomorrow.1 = String(weatherDescription)
                                case 2: self.tempAfterTomorrow.1 = String(weatherDescription)
                                default: self.tempAfterAfterTomorrow.1 = String(weatherDescription)
                                }
                            }
                        }
                    }
                    print(" --> Giornata: ")
                    if let dt_txt = weatherList[i]["dt_txt"] as? String {
                        print("  -->  dt_txt: \(dt_txt)")
                    }
                }
                //get current location
                guard let city = data["city"] as? [String: Any] else {
                    print("Could not get city from JSON")
                    return
                }
                if let cityName = city["name"] as? String {
                    self.location = cityName
                }
                DispatchQueue.main.async {
                    self.setTemp()
                }
                
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
   
            task.resume()
    
        
    }
    //Text-to-speech
    func speakOut(text: String){
        let speech = AVSpeechUtterance(string: text)
        speech.voice = AVSpeechSynthesisVoice(language: "en-UK")
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(speech)
    }
    //On tap, speak and add a new node.
    @objc func handleTap(gestureRecognize :UITapGestureRecognizer) {
        let sceneView = gestureRecognize.view as! ARSCNView
        let touchLocation = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        if !hitResults.isEmpty {
            self.speakOut(text: "This is the weather for \(self.location). Today is \(self.tempToday.0)°C")
            self.createTextNode(title: "Thank you!", size: fontSizeAR, x: 12, y: 13)
        }
    }
    /* This method sets the weather for today and the next three days.
     */
    func setTemp(){
        //Create main node for today.
        self.createTextNode(title: self.location, size: 2.9, x: 5, y: -5)
        let primaryImage = self.createImageNode(width: 7, height: 7, x: 10, y: -6, imageName: "\(self.tempToday.1).png")
        let action = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(0, 0, 1), duration: 5))
        if self.tempToday.1.contains("sun"){
            primaryImage.runAction(action)
        }
        self.createTextNode(title: "\(self.tempToday.0)°C", size: 2.6, x: 5, y: -2)
        let weekdays = self.getWeekday()
        
        self.createTextNode(title: weekdays.0, size: 2.3, x: 13, y: 2)
        //self.createImageNode(width: 3, height: 3, x: 10.5, y: 4, imageName: "\(self.tempTomorrow.1).png")
        self.createImageNode(width: 3, height: 3, x: 10.5, y: 4, imageName: "cloud.png")
        
        self.createTextNode(title: "\(self.tempTomorrow.0)°C", size: 1.8, x: 13, y: 9)
        self.createTextNode(title: weekdays.1, size: 2.3, x: 6, y: 2)
        //self.createImageNode(width: 3, height: 3, x: 3, y: 4, imageName: "\(self.tempAfterTomorrow.1).png")
        self.createImageNode(width: 3, height: 3, x: 3, y: 4, imageName: "rain.png")
        self.createTextNode(title: "\(self.tempAfterTomorrow.0)°C", size: 1.8, x: 6, y: 9)
        self.createTextNode(title: weekdays.2, size: 2.3, x: -1, y: 2)
        //self.createImageNode(width: 3, height: 3, x:-3, y: 4, imageName: "\(self.tempAfterAfterTomorrow.1).png")
        self.createImageNode(width: 3, height: 3, x:-3, y: 4, imageName: "cloudy.png")
        self.createTextNode(title: "\(self.tempAfterAfterTomorrow.0)°C", size: 1.8, x: -1, y: 9)
    }
    /* This method returns the current weekday.
     */
    func getWeekday() -> (String,String,String){
        let tomorrow = Date().tomorrow
        let afterTomorrow = Date().afterTomorrow
        let afterAfterTomorrow = Date().afterAfterTomorrow
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.dateFormat = "EEEE"
        
        let tomorrowString = dateFormatter.string(from: tomorrow).prefix(3)
        let afterTomorrowString = dateFormatter.string(from: afterTomorrow).prefix(3)
        let afterAfterTomorrowString = dateFormatter.string(from: afterAfterTomorrow).prefix(3)
        print("Weekdays are \(tomorrowString.prefix(3)) \(afterTomorrowString.prefix(3)) \(afterAfterTomorrowString.prefix(3))")
        return (String(tomorrowString), String(afterTomorrowString), String(afterAfterTomorrowString))
    }
}
extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location:CLLocationCoordinate2D = manager.location?.coordinate {
            print("Your location is \(location.latitude) \(location.longitude)")
            manager.stopUpdatingLocation()
            manager.delegate = nil
           
            //get some Weather data
            self.getWeather(latitude: String(location.latitude), longitude: String(location.longitude))
        }
    }
}
extension Date {
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    var afterTomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 2, to: self)!
    }
    var afterAfterTomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 3, to: self)!
    }
}
