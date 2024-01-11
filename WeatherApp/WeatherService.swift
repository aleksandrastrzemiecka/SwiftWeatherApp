//
//  WeatherService.swift
//  WeatherApp
//
//  Created by Aleksandra Strzemiecka on 27/10/2023.
//

import Foundation

class WeatherService {
    private let apiKey = ""
    
    enum ServiceError: String, Error {
        case invalidLocation = "Bad API Request:Invalid location parameter value."
        case unknown
        
        var userReadableMessage: String {
            switch self {
            case .invalidLocation:
                return "Unknown location. Please try another location."
            case .unknown:
                return "Oops, sorry, something went wrong."
            }
        }
    }
    
    func fetch(unit: UnitGroup, location: String, completion: @escaping (Result<WeatherAPIResponse, Error>) -> ()) {
        guard let url = URL(string: "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(location)?unitGroup=\(unit.rawValue)&key=\(apiKey)&contentType=json") else {
            return
        }
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(
            with: request
        ) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.weatherAPIResponse)
                let weatherAPIResponse = try decoder.decode(
                    WeatherAPIResponse.self, from: data
                )
                completion(.success(weatherAPIResponse))
            } catch {
                guard
                    let errorString = String(data: data, encoding: .utf8),
                    let serviceError = ServiceError(rawValue: errorString)
                else {
                    completion(.failure(ServiceError.unknown))
                    return
                }
                completion(.failure(serviceError))
            }
        }
        task.resume()
    }
}

private extension DateFormatter {
    static let weatherAPIResponse: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
