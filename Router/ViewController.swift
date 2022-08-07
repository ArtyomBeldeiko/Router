//
//  ViewController.swift
//  Router
//
//  Created by Artyom Beldeiko on 7.08.22.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    let addressButton: UIButton = {
        let addressButton = UIButton()
        addressButton.setImage(UIImage(systemName: "house.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50)), for: .normal)
        addressButton.tintColor = UIColor(red: 21 / 255, green: 52 / 255, blue: 80 / 255, alpha: 1)
        addressButton.translatesAutoresizingMaskIntoConstraints = false
        return addressButton
    }()
    
    let routeButton: UIButton = {
        let routeButton = UIButton()
        routeButton.setImage(UIImage(systemName: "figure.walk.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60)), for: .normal)
        routeButton.tintColor = UIColor(red: 68 / 255, green: 114 / 255, blue: 148 / 255, alpha: 1)
        routeButton.translatesAutoresizingMaskIntoConstraints = false
        routeButton.isHidden = true
        return routeButton
    }()
    
    let resetButton: UIButton = {
        let resetButton = UIButton()
        resetButton.setImage(UIImage(systemName: "minus.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60)), for: .normal)
        resetButton.tintColor = UIColor(red: 182 / 255, green: 33 / 255, blue: 45 / 255, alpha: 1)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.isHidden = true
        return resetButton
    }()
    
    var annotationsArray = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        setConstraints()
        
        addressButton.addTarget(self, action: #selector(addressButtonTapped), for: .touchUpInside)
        routeButton.addTarget(self, action: #selector(routeButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
    }
    
    @objc func addressButtonTapped() {
        alertAddAddress(title: "Add Address", placeholder: "Insert Address") { [self] text in
            setupPlacemark(address: text)
        }
    }
    
    @objc func routeButtonTapped() {
        for index in 0...annotationsArray.count - 2 {
            createDirectionRequest(startCoordinate: annotationsArray[index].coordinate, destinationCoordinate: annotationsArray[index + 1].coordinate)
        }
    
        mapView.showAnnotations(annotationsArray, animated: true)
    }
    
    @objc func resetButtonTapped() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        annotationsArray.removeAll()
        routeButton.isHidden = true
        resetButton.isHidden = true
    }
    
    private func setupPlacemark(address: String) {
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { [self] placemarks, error in
            if let error = error {
                print(error)
                alertError(title: "Error", message: "Request is not available. Please, try again.")
                return
            }
            
            guard let placemarks = placemarks else { return }
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = address
            
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            
            annotationsArray.append(annotation)
            
            if annotationsArray.count > 2 {
                routeButton.isHidden = false
                resetButton.isHidden = false
            }
            
            mapView.showAnnotations(annotationsArray, animated: true)
        }
    }
    
    private func createDirectionRequest(startCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let initialLocation = MKPlacemark(coordinate: startCoordinate)
        let destinationLocation = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: initialLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let direction = MKDirections(request: request)
        direction.calculate { response, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.alertError(title: "Error", message: "Route is not available.")
                 return
            }
            
            var shortestRoute = response.routes[0]
            for route in response.routes {
                shortestRoute = (route.distance < shortestRoute.distance) ? route : shortestRoute
            }
            
            self.mapView.addOverlay(shortestRoute.polyline)
        }
    }
}

extension ViewController {
    
    func setConstraints() {
        
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        view.addSubview(addressButton)
        NSLayoutConstraint.activate([
            addressButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 50),
            addressButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
        
        view.addSubview(routeButton)
        NSLayoutConstraint.activate([
            routeButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 8),
            routeButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -190)
        ])
        
        view.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 8),
            resetButton.topAnchor.constraint(equalTo: routeButton.bottomAnchor, constant: 1)
        ])
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = UIColor(red: 182 / 255, green: 33 / 255, blue: 45 / 255, alpha: 1)
        return renderer
    }
}

