//
//  CameraPreviewView.swift
//  CameraAccessiOS
//
//  Created by sachin kumar on 05/07/25.
//

import SwiftUI
import AVFoundation
import Combine

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.configure(with: session)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update if needed
    }
}

class CameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func configure(with session: AVCaptureSession) {
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer?.session = session
        previewLayer?.videoGravity = .resizeAspectFill
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            if cameraManager.isSessionRunning {
                CameraPreviewView(session: cameraManager.session)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("Camera Preview")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Camera session is loading...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Camera switch button
                    Button(action: {
                        cameraManager.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Camera Permission Granted!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(cameraManager.currentCameraPosition == .back ? "Back Camera" : "Front Camera")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

class CameraManager: ObservableObject {
    @Published var isSessionRunning = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    let session = AVCaptureSession()
    private var currentVideoInput: AVCaptureDeviceInput?
    
    func startSession() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.setupCamera(position: self.currentCameraPosition)
        }
    }
    
    private func setupCamera(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        
        // Remove existing input if any
        if let currentInput = currentVideoInput {
            session.removeInput(currentInput)
        }
        
        // Get the desired camera
        guard let videoDevice = getCamera(for: position),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            session.commitConfiguration()
            return
        }
        
        session.addInput(videoInput)
        currentVideoInput = videoInput
        session.commitConfiguration()
        
        if !session.isRunning {
            session.startRunning()
        }
        
        DispatchQueue.main.async {
            self.isSessionRunning = self.session.isRunning
            self.currentCameraPosition = position
        }
    }
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first
    }
    
    func switchCamera() {
        guard isSessionRunning else { return }
        
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCamera(position: newPosition)
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
            isSessionRunning = false
        }
    }
}

#Preview {
    CameraView()
}
