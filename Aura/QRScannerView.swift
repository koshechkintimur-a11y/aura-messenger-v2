import SwiftUI
import AVFoundation

struct QRScannerView: View {
    let onCodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isScanning = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                QRScannerPreview(isScanning: $isScanning, onCodeScanned: { code in
                    onCodeScanned(code)
                    dismiss()
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .padding(40)
                )
                
                Text("Наведите камеру на QR-код")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 16)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Отмена")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(white: 0.2))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            isScanning = true
        }
        .onDisappear {
            isScanning = false
        }
        .alert("Ошибка", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct QRScannerPreview: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onCodeScanned: (String) -> Void
    
    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        context.coordinator.previewView = previewView
        return previewView
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        if isScanning {
            context.coordinator.startSession()
        } else {
            context.coordinator.stopSession()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRScannerPreview
        var previewView: PreviewView?
        var captureSession: AVCaptureSession?
        
        init(_ parent: QRScannerPreview) {
            self.parent = parent
        }
        
        func startSession() {
            guard captureSession == nil else { return }
            
            let session = AVCaptureSession()
            captureSession = session
            
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
                
                let metadataOutput = AVCaptureMetadataOutput()
                if session.canAddOutput(metadataOutput) {
                    session.addOutput(metadataOutput)
                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    metadataOutput.metadataObjectTypes = [.qr]
                }
                
                previewView?.videoPreviewLayer.session = session
                
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                }
            } catch {
                print("Ошибка инициализации камеры: \(error.localizedDescription)")
            }
        }
        
        func stopSession() {
            captureSession?.stopRunning()
            captureSession = nil
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataMachineReadableCodeObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first,
               let stringValue = metadataObject.stringValue {
                parent.onCodeScanned(stringValue)
                stopSession()
            }
        }
    }
    
    class PreviewView: UIView {
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
    }
}
