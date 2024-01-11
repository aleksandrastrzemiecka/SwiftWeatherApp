//
//  MapViewController.swift
//  WeatherApp
//
//  Created by Aleksandra Strzemiecka on 18/12/2023.
//

import UIKit
import MapKit

protocol MapViewControllerDelegate: AnyObject {
    func didChange(location: String)
}

class MapViewController: UIViewController {
    
    weak var delegate: MapViewControllerDelegate?
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    private let localSearchCompleter: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.region = MKCoordinateRegion(.world)
        completer.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        return completer
    }()
    
    private let suggestionsTableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    private let toolbarView: UIView = {
        let toolbarView = UIView()
        return toolbarView
    }()
    
    private var suggestions = MapSuggestions(results: []) {
        didSet {
            suggestionsTableView.reloadData()
        }
    }
    
    private struct MapSuggestions {
        var results: [MKLocalSearchCompletion]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(toolbarView)
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            toolbarView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            toolbarView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            toolbarView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(
                equalTo: toolbarView.bottomAnchor
            ),
            mapView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            mapView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            )
        ])
        mapView.delegate = self
        view.addSubview(suggestionsTableView)
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: mapView.bottomAnchor),
            suggestionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            suggestionsTableView.heightAnchor.constraint(equalToConstant: 200)
        ])
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        
        let touchRecognizer = UITapGestureRecognizer(target: self, action: #selector(onMapTouchAction))
        touchRecognizer.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(touchRecognizer)
        
        localSearchCompleter.delegate = self
    }
    
    @objc private func onMapTouchAction(gestureRecognizer: UIGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate

        let clLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        clLocation.placemark { [weak self] placemarks, error in
            guard let placemarks = placemarks else {
                print("Error:", error ?? "nil")
                return
            }
            
            if let query = placemarks.first?.placeDescription {
                print("query: \(query)")
                self?.localSearchCompleter.queryFragment = query
            } else {
                self?.suggestions.results = []
                let alert = UIAlertController(title: nil, message: "Location not found", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default)
                alert.addAction(action)
                self?.present(alert, animated: true)
            }
        }
        mapView.addAnnotation(annotation)
    }
}

extension MapViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print(completer.results.map {$0.title} )
        suggestions.results = completer.results
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
    }
}

private extension CLLocation {
    func placemark(
        completion: @escaping (_ placemark: [CLPlacemark]?, _ error: Error?) -> ()
    ) {
        CLGeocoder()
            .reverseGeocodeLocation(self) { completion($0, $1) }
    }
}

private extension CLPlacemark {
    var placeDescription: String? {
        if locality == nil || subAdministrativeArea == nil {
            return nil
        }
        return "\(locality ?? ""), \(subAdministrativeArea ?? "")"
    }
}

extension MapViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = suggestions.results[indexPath.row]
        delegate?.didChange(location: location.title)
        dismiss(animated: true)
    }
}

extension MapViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let location = suggestions.results[indexPath.row]
        cell.textLabel?.text = location.title
        return cell
    }
}
