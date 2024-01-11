//
//  UnitGroup.swift
//  WeatherApp
//
//  Created by Aleksandra Strzemiecka on 17/11/2023.
//

import Foundation

enum UnitGroup: String, CaseIterable {
    case metric
    case us
    
    var text: String {
        switch self {
        case .metric:
            return "C"
        case .us:
            return "F"
        }
    }
    
    var unitName: String {
        switch self {
        case .metric:
            return "Celsius"
        case .us:
            return "Fahrenheit"
        }
    }
    
    var unitIndex: Int {
        switch self {
        case .metric:
            return 0
        case .us:
            return 1
        }
    }
}
