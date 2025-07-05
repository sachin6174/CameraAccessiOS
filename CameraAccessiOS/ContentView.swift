//
//  ContentView.swift
//  CameraAccessiOS
//
//  Created by sachin kumar on 05/07/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var permissionManager = CameraPermissionManager()
    @State private var showCameraPreview = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: isCompact ? 20 : 30) {
                    headerView
                    
                    VStack(spacing: isCompact ? 15 : 20) {
                        permissionStatusView
                        actionButtonsView
                        permissionInstructionsView
                    }
                    .padding(.horizontal, isCompact ? 16 : 24)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, isCompact ? 20 : 40)
                .padding(.horizontal, isCompact ? 16 : 24)
                .frame(minWidth: geometry.size.width)
            }
        }
        .onAppear {
            permissionManager.refreshPermissionStatus()
            // Automatically request permission if not determined
            if permissionManager.authorizationStatus == .notDetermined {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    permissionManager.requestPermission()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                permissionManager.refreshPermissionStatus()
            }
        }
        .sheet(isPresented: $showCameraPreview) {
            CameraView()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: isCompact ? 50 : 60))
                .foregroundColor(.blue)
            
            Text("Camera Access")
                .font(isCompact ? .title : .largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Manage camera permissions for this app")
                .font(isCompact ? .subheadline : .title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var permissionStatusView: some View {
        HStack(spacing: 15) {
            Image(systemName: cameraAccessIconName)
                .foregroundColor(cameraAccessIconColor)
                .font(.system(size: isCompact ? 30 : 40))
                .frame(width: isCompact ? 40 : 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Camera Permission")
                    .font(isCompact ? .subheadline : .headline)
                    .fontWeight(.semibold)
                
                Text(permissionManager.permissionStatusText)
                    .font(isCompact ? .caption : .subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(isCompact ? 12 : 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            if permissionManager.canRequestPermission {
                Button(action: {
                    permissionManager.requestPermission()
                }) {
                    Text("Grant Camera Permission")
                        .font(isCompact ? .subheadline : .headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: isCompact ? 40 : 44)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            if permissionManager.hasPermission {
                Button(action: {
                    showCameraPreview = true
                }) {
                    Text("Open Camera Preview")
                        .font(isCompact ? .subheadline : .headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: isCompact ? 40 : 44)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: openSystemSettings) {
                    Text("Revoke Camera Permission")
                        .font(isCompact ? .subheadline : .headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: isCompact ? 40 : 44)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            
            if permissionManager.needsSystemSettings {
                Button(action: openSystemSettings) {
                    Text("Grant Permission")
                        .font(isCompact ? .subheadline : .headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: isCompact ? 40 : 44)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            Button(action: {
                permissionManager.refreshPermissionStatus()
            }) {
                Text("Refresh Status")
                    .font(isCompact ? .caption : .subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, minHeight: isCompact ? 32 : 36)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var permissionInstructionsView: some View {
        VStack(spacing: isCompact ? 10 : 12) {
            Text("How to Manage Camera Permissions on iOS:")
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            instructionRowView(
                title: "To revoke this app's camera permission:",
                steps: [
                    "1. Open iOS Settings app",
                    "2. Scroll down and tap 'CameraAccessiOS'",
                    "3. Toggle 'Camera' OFF"
                ],
                backgroundColor: Color.blue.opacity(0.05),
                iconColor: .blue,
                icon: "gearshape.fill"
            )
            
            instructionRowView(
                title: "Alternative method:",
                steps: [
                    "1. Open iOS Settings app",
                    "2. Tap 'Privacy & Security'",
                    "3. Tap 'Camera'",
                    "4. Find 'CameraAccessiOS' and toggle OFF"
                ],
                backgroundColor: Color.orange.opacity(0.05),
                iconColor: .orange,
                icon: "hand.raised.fill"
            )
            
            instructionRowView(
                title: "To reset and re-grant permission:",
                steps: [
                    "1. Follow steps above to revoke permission",
                    "2. Return to this app",
                    "3. Tap 'Grant Camera Permission'",
                    "4. Allow when prompted"
                ],
                backgroundColor: Color.green.opacity(0.05),
                iconColor: .green,
                icon: "arrow.clockwise"
            )
            
            instructionRowView(
                title: "Camera Preview Features:",
                steps: [
                    "• Switch between front and back cameras",
                    "• Tap the rotate icon in camera view",
                    "• Live camera feed with full resolution",
                    "• Real-time camera switching"
                ],
                backgroundColor: Color.purple.opacity(0.05),
                iconColor: .purple,
                icon: "camera.rotate"
            )
        }
        .padding(isCompact ? 12 : 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func instructionRowView(title: String, steps: [String], backgroundColor: Color, iconColor: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(iconColor)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(steps, id: \.self) { step in
                    Text(step)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                }
            }
        }
        .padding(8)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var cameraAccessIconName: String {
        switch permissionManager.authorizationStatus {
        case .authorized:
            return "camera.fill"
        case .denied:
            return "camera.slash.fill"
        case .restricted:
            return "camera.slash"
        case .notDetermined:
            return "camera"
        @unknown default:
            return "camera"
        }
    }
    
    private var cameraAccessIconColor: Color {
        switch permissionManager.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }
    
    private func openSystemSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

#Preview {
    ContentView()
}
