//
//  CameraPermissionManager.swift
//  CameraAccessiOS
//
//  Created by sachin kumar on 05/07/25.
//

import AVFoundation
import SwiftUI
import Combine

class CameraPermissionManager: ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var hasPermission: Bool = false
    
    init() {
        checkPermissionStatus()
    }
    
    func checkPermissionStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        hasPermission = authorizationStatus == .authorized
    }
    
    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already have permission
            DispatchQueue.main.async {
                self.checkPermissionStatus()
            }
            
        case .notDetermined:
            // First time — this will trigger the system alert
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.checkPermissionStatus()
                }
            }
            
        case .denied, .restricted:
            // Permission was previously denied or is restricted
            // The UI will show "Open Settings" button
            DispatchQueue.main.async {
                self.checkPermissionStatus()
            }
            
        @unknown default:
            DispatchQueue.main.async {
                self.checkPermissionStatus()
            }
        }
    }
    
    func refreshPermissionStatus() {
        checkPermissionStatus()
    }
    
    var permissionStatusText: String {
        switch authorizationStatus {
        case .authorized:
            return "Camera access granted"
        case .denied:
            return "Camera access denied"
        case .restricted:
            return "Camera access restricted"
        case .notDetermined:
            return "Camera access not determined"
        @unknown default:
            return "Unknown camera access status"
        }
    }
    
    var canRequestPermission: Bool {
        return authorizationStatus == .notDetermined
    }
    
    var needsSystemSettings: Bool {
        return authorizationStatus == .denied
    }
}
