//
//  CurrentConditionsViewsFactory.swift
//  WeatherApp
//
//  Created by Aleksandra Strzemiecka on 20/10/2023.
//

import UIKit

struct CurrentConditionsViewsFactory {
    
    func makeStackView(description: String, value: String) -> UIStackView {
        let descriptionLabel = UILabel()
        descriptionLabel.textColor = .blue
        descriptionLabel.text = description
        let valueLabel = UILabel()
        valueLabel.textColor = .white
        valueLabel.text = value
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(valueLabel)
        return stackView
    }
}
