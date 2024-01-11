//
//  ViewController.swift
//  WeatherApp
//
//  Created by Aleksandra Strzemiecka on 18/10/2023.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.textAlignment = .center
        return label
    }()
    
    private let currentConditionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    private let daysTableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    private var weatherAPIResponse: WeatherAPIResponse? {
        didSet {
            daysTableView.reloadData()
        }
    }
    
    private var unit = UnitGroup.metric {
        didSet {
            fetch()
        }
    }
    
    private var location = "pszczyna" {
        didSet {
            fetch()
        }
    }
    
    private var settingsViewController: SettingsViewController?

    private let toolbarView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }()
    
    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        let colorConfiguration = UIImage.SymbolConfiguration(paletteColors: [.white])
        let configuration = UIImage.SymbolConfiguration(weight: .heavy).applying(colorConfiguration)
        let gearImage = UIImage(systemName: "gear", withConfiguration: configuration)
        button.setImage(gearImage, for: .normal)
        return button
    }()
    
    private let mapButton: UIButton = {
        let button = UIButton(type: .system)
        let colorConfiguration = UIImage.SymbolConfiguration(paletteColors: [.white])
        let configuration = UIImage.SymbolConfiguration(weight: .heavy).applying(colorConfiguration)
        let pinImage = UIImage(systemName: "pin", withConfiguration: configuration)
        button.setImage(pinImage, for: .normal)
        return button
    }()
    
    private let locationManager = CLLocationManager()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        daysTableView.delegate = self
        daysTableView.dataSource = self
        view.backgroundColor = .systemPink
        fetch()
        view.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        view.addSubview(currentConditionsStackView)
        currentConditionsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            currentConditionsStackView.topAnchor.constraint(
                equalTo: locationLabel.bottomAnchor
            ),
            currentConditionsStackView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            currentConditionsStackView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            )
        ])
        view.addSubview(toolbarView)
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                toolbarView.trailingAnchor.constraint(
                    equalTo: view.trailingAnchor
                ),
                toolbarView.heightAnchor.constraint(equalToConstant: 86)
            ]
        )
            
        view.addSubview(daysTableView)
        daysTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            daysTableView.topAnchor.constraint(
                equalTo: currentConditionsStackView.bottomAnchor
            ),
            daysTableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            daysTableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            daysTableView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor)
        ])
        toolbarView.addSubview(settingsButton)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                settingsButton.bottomAnchor.constraint(
                    equalTo: toolbarView.bottomAnchor, constant: -40
                ),
                settingsButton.trailingAnchor.constraint(
                    equalTo: toolbarView.trailingAnchor, constant: -40
                )
            ]
        )
        let action = UIAction { [weak self] _ in
            guard let unit = self?.unit else {
                return
            }
            let settingsViewController = SettingsViewController(unitGroup: unit)
            settingsViewController.delegate = self
            settingsViewController.modalPresentationStyle = .formSheet
            settingsViewController.sheetPresentationController?.detents = [.medium()]
            self?.present(settingsViewController, animated: true)
            self?.settingsViewController = settingsViewController
        }
        settingsButton.addAction(action, for: .touchUpInside)
        
        toolbarView.addSubview(mapButton)
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapButton.bottomAnchor.constraint(
                equalTo: toolbarView.bottomAnchor, constant: -40
            ),
            mapButton.leadingAnchor.constraint(
                equalTo: toolbarView.leadingAnchor, constant: 40
            )
        ])
        let mapAction = UIAction { [weak self] _ in
            let mapViewController = MapViewController()
            mapViewController.delegate = self
            mapViewController.modalPresentationStyle = .formSheet
            mapViewController.sheetPresentationController?.detents = [.large()]
            self?.present(mapViewController, animated: true)
        }
        mapButton.addAction(mapAction, for: .touchUpInside)
        
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        

    }

    private func fetch() {
        WeatherService().fetch(unit: unit, location: location) { result in
            switch result {
            case .success(let weatherAPIResponse):
                DispatchQueue.main.async { [weak self] in
                    self?.updateUI(with: weatherAPIResponse)
                }
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    self?.settingsViewController?.show(error: error)
                }
            }
        }
    }
    
    private func updateUI(with weatherAPIResponse: WeatherAPIResponse) {
        self.weatherAPIResponse = weatherAPIResponse
        let factory = CurrentConditionsViewsFactory()
        locationLabel.text = weatherAPIResponse.resolvedAddress
        let tempStackView = factory.makeStackView(
            description: "Current temperature:",
            value: "\(weatherAPIResponse.currentConditions.temp)" + unit.text
        )
        let feelslikeStackView = factory.makeStackView(
            description: "Feels like temperature:",
            value: "\(weatherAPIResponse.currentConditions.feelslike)" + unit.text
        )
        let humidityStackView = factory.makeStackView(
            description: "Humidity:",
            value: "\(weatherAPIResponse.currentConditions.humidity)"
        )
        currentConditionsStackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        currentConditionsStackView.addArrangedSubview(tempStackView)
        currentConditionsStackView.addArrangedSubview(feelslikeStackView)
        currentConditionsStackView.addArrangedSubview(humidityStackView)
    }
    
    func fetchCityAndCountry(from location: CLLocation, completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            completion(placemarks?.first?.locality,
                       placemarks?.first?.country,
                       error)
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        weatherAPIResponse?.days.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        guard let weatherAPIResponse else {
            return cell
        }
        let day = weatherAPIResponse.days[indexPath.row]
        let temp = day.temp
        let weekday = day.weekday(timezoneName: weatherAPIResponse.timezone)
        cell.textLabel?.text = "Day: \(weekday)"
        cell.detailTextLabel?.text = "Temperature: \(temp)" + unit.text
        return cell
    }
    
    
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: SettingsViewControllerDelegate {
    func didChange(location: String) {
        self.location = location
    }
    
    func didSelect(unitGroup: UnitGroup) {
        unit = unitGroup
    }
    
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocation = manager.location else { return }
        fetchCityAndCountry(from: location) { city, country, error in
            guard let city = city, let country = country, error == nil else { return }
            print(city + ", " + country)
        }
    }
}

extension ViewController: MapViewControllerDelegate {
    
}
