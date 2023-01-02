//
//  LocationManager.swift
//  PermissionCheck
//
//  Created by UMCios on 2023/01/02.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static var shared = LocationManager()
    
    //PermissionAgent에서 옮겨옴
    private var locationManager: CLLocationManager!
    private var authorizationStatusBlock: ((CLAuthorizationStatus) -> ())?
    
    static func checkLocationPermission() async -> Permission.Status {
        return await withCheckedContinuation { continuation in
            LocationManager.shared.requestLocationPermission { auth in
                switch auth {
                case .notDetermined:
                    continuation.resume(returning: .notDetermined)
                case .authorizedWhenInUse, .authorizedAlways:
                    continuation.resume(returning: .authorized)
                case .denied:
                    continuation.resume(returning: .denied)
                case .restricted:
                    continuation.resume(returning: .limited)
                default:
                    continuation.resume(returning: .notDetermined)
                }
                //continuation call 중복호출 방지
                LocationManager.shared.authorizationStatusBlock = nil
            }
        }
    }
    
    //MARK: CLLocation
    private func requestLocationPermission(completion: @escaping (CLAuthorizationStatus) -> ()) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.locationManager = CLLocationManager()
                    self.locationManager.delegate = self
                    if #available(iOS 14, *) {
                        let status = self.locationManager.authorizationStatus
                        if status == .notDetermined {
                            self.authorizationStatusBlock = completion
                            self.locationManager.requestAlwaysAuthorization()
                        } else {
                            completion(status)
                        }
                    } else {
                        let status = CLLocationManager.authorizationStatus()
                        if status == .notDetermined {
                            self.authorizationStatusBlock = completion
                            self.locationManager.requestAlwaysAuthorization()
                        } else {
                            completion(status)
                        }
                    }
                }
            } else {
                completion(.denied)
            }
        }
    }
    
    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined {
            authorizationStatusBlock?(manager.authorizationStatus)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .notDetermined {
            authorizationStatusBlock?(status)
        }
    }
    
    
}
