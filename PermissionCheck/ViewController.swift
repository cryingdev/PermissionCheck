//
//  ViewController.swift
//  PermissionCheck
//
//  Created by UMCios on 2023/01/02.
//

import UIKit
import Combine
import CoreLocation
import Photos

class ViewController: UIViewController {

    //will change this to @State private in SwiftUI
    var permissionStatus = false {
        didSet {
            statusLbl.text = "\(permissionStatus)"
        }
    }
    
    @IBOutlet var statusLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Usage
        checkPermission()
        checkPermission()
    }


    func showAlert(title: String, message: String, confim: UIAlertAction, cancel: UIAlertAction? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(confim)
        if let cancel = cancel {
            alertController.addAction(cancel)
        }
        present(alertController, animated: true, completion: nil)
    }
}



extension ViewController {
    
    func checkPermission() {
        let permissionTypes = [Permission( .camera, .optional),
                               Permission( .location, .required),
                               Permission( .audio, .optional),
                               Permission( .photo, .required)]
        Task { @MainActor in
            permissionStatus = await requestPermission(permissionTypes)
        }
    }
    
    func requestPermission(_ permissionTypes: [Permission]) async -> Bool {
        var errMsg = ""
        for permission in permissionTypes {
            let permissionType = permission.type
            var status: Permission.Status = .notDetermined
            
            switch permissionType {
            case .photo:
                errMsg = "사진 접근 권한 필요합니다."
                status = await checkPhotoLibraryPermission()
            case .camera:
                errMsg = "카메라 접근 권한 필요합니다."
                status = await checkCameraPermission()
            case .audio:
                errMsg = "오디오 접근 권한 필요합니다."
                status = await checkAudioPermission()
            case .location:
                errMsg = "위치 접근 권한 필요합니다."
                status = await LocationManager().checkLocationPermission()
            }
            if status == .denied, permission.requirement == .required {
                let value = await withUnsafeContinuation { [weak self] continuation in
                    self?.showAlert(title: "권한 알림",
                              message: errMsg,
                              confim: UIAlertAction(title: "설정하기", style: .default) {  action in
                        let url = URL(string: UIApplication.openSettingsURLString)!
                        UIApplication.shared.open(url)
                        continuation.resume(returning: false)},
                              cancel: UIAlertAction(title: "앱 종료", style: .cancel) { action in
                        exit(0)})
                }
                print("on denied requiredPermission")
            }
        }
        return true
    }
    
    // MARK: - Private
    /// 카메라 권한 요청 메서드
    private func checkCameraPermission() async -> Permission.Status {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            return .authorized
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                    continuation.resume(returning: granted ? .authorized : .denied)
                })
            }
        case .restricted:
            return .denied
        case .denied:
            return .denied
        default:
            return .notDetermined
        }
    }
    
    /// 사진 라이브러리 권한 요청 메서드
    private func checkPhotoLibraryPermission() async -> Permission.Status {
        if #available(iOS 14, *) {
            switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
            case .limited:
                return .limited
            case .authorized:
                return .authorized
            case .notDetermined:
                let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                switch status {
                case .limited:
                    return .limited
                case .authorized:
                    return .authorized
                case .restricted, .denied:
                    return .denied
                default:
                    return .notDetermined
                }
            case .restricted, .denied:
                return .denied
            default:
                return .notDetermined
            }
        } else {
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                return .authorized
            case .notDetermined:
                return await withCheckedContinuation { continuation in
                    PHPhotoLibrary.requestAuthorization({ status in
                        if status == .authorized {
                            continuation.resume(returning:.authorized)
                        } else {
                            continuation.resume(returning:.denied)
                        }
                    })
                }
            case .restricted, .denied:
                return .denied
            default:
                return .notDetermined
            }
        }
    }
    
    /// 마이크 사용 권한 요청 메서드
    private func checkAudioPermission() async -> Permission.Status {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            return .authorized
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                    if granted {
                        continuation.resume(returning: .authorized)
                    } else {
                        continuation.resume(returning: .denied)
                    }
                })
            }
        case .denied:
            return .denied
        default:
            return .notDetermined
        }
    }
}
