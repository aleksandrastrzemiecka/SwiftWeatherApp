//
//  SettingsViewController.swift
//  WeatherApp
//
//  Created by Aleksandra Strzemiecka on 21/11/2023.
//

import UIKit
import MapKit

protocol SettingsViewControllerDelegate: AnyObject {
    func didSelect(unitGroup: UnitGroup)
    func didChange(location: String)
}

class SettingsViewController: UIViewController {
    
    weak var delegate: SettingsViewControllerDelegate?
    
    private let unitGroup: UnitGroup
    
    private let segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: UnitGroup.allCases.map { $0.unitName })
        return segmentedControl
    }()
    
    private let locationTextField: UITextField = {
        let locationTextField = UITextField(frame: .zero)
        locationTextField.borderStyle = .line
        locationTextField.layer.borderWidth = 1
        return locationTextField
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .red
        label.isHidden = true
        label.numberOfLines = 0
        return label
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
    
    init(unitGroup: UnitGroup) {
        self.unitGroup = unitGroup
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        segmentedControl.selectedSegmentIndex = unitGroup.unitIndex
        
        UnitGroup.allCases.forEach { unit in
            let celsiusAction = UIAction(title: unit.unitName) { [weak self] _ in
                self?.delegate?.didSelect(unitGroup: unit)
            }
            segmentedControl.setAction(celsiusAction, forSegmentAt: unit.unitIndex)
        }
        view.addSubview(locationTextField)
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            locationTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            locationTextField.widthAnchor.constraint(equalToConstant: 200)
        ])
        locationTextField.delegate = self
        view.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: locationTextField.topAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        localSearchCompleter.delegate = self
        view.addSubview(suggestionsTableView)
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: locationTextField.bottomAnchor),
            suggestionsTableView.leadingAnchor.constraint(equalTo: locationTextField.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: locationTextField.trailingAnchor),
            suggestionsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
    }
    
    func show(error: Error?) {
        guard let error = error else {
            errorLabel.isHidden = true
           return
        }
        errorLabel.isHidden = false
        guard let error = error as? WeatherService.ServiceError else {
            errorLabel.text = error.localizedDescription
            return
        }
        errorLabel.text = error.userReadableMessage
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            delegate?.didChange(location: text)
            localSearchCompleter.queryFragment = text
            errorLabel.isHidden = true
        }
        textField.resignFirstResponder()
        return true
    }
}

extension SettingsViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print(completer.results.map {$0.title} )
        suggestionsTableView.reloadData()
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = localSearchCompleter.results[indexPath.row]
        locationTextField.text = location.title
        delegate?.didChange(location: location.title)
        errorLabel.isHidden = true
    }
}

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        localSearchCompleter.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let location = localSearchCompleter.results[indexPath.row]
        cell.textLabel?.text = location.title
        return cell
    }
}
