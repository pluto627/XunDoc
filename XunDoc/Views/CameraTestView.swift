//
//  CameraTestView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI
import AVFoundation

struct CameraTestView: View {
    @State private var captureSession = AVCaptureSession()
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    @State private var status = "初始化中..."
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("摄像头测试")
                    .font(.title)
                
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 300)
                        .cornerRadius(10)
                    
                    if let previewLayer = previewLayer {
                        SimpleCameraPreview(previewLayer: previewLayer)
                            .frame(height: 300)
                            .cornerRadius(10)
                    } else {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            Text("摄像头预览")
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Button("重新初始化") {
                    setupCamera()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .onAppear {
                setupCamera()
            }
            .onDisappear {
                captureSession.stopRunning()
            }
            .navigationTitle("摄像头测试")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func setupCamera() {
        status = "检查权限..."
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        configureCamera()
                    } else {
                        status = "摄像头权限被拒绝"
                    }
                }
            }
        case .denied, .restricted:
            status = "摄像头权限被拒绝或受限"
        @unknown default:
            status = "未知权限状态"
        }
    }
    
    private func configureCamera() {
        status = "配置摄像头..."
        
        captureSession.stopRunning()
        
        // 清除现有输入和输出
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            status = "无法获取摄像头设备"
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            captureSession.beginConfiguration()
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                status = "摄像头输入已添加"
            } else {
                status = "无法添加摄像头输入"
                captureSession.commitConfiguration()
                return
            }
            
            captureSession.sessionPreset = .medium
            captureSession.commitConfiguration()
            
            // 创建预览层
            let newPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            newPreviewLayer.videoGravity = .resizeAspectFill
            
            previewLayer = newPreviewLayer
            
            // 启动会话
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                
                DispatchQueue.main.async {
                    status = captureSession.isRunning ? "摄像头运行中" : "摄像头启动失败"
                }
            }
            
        } catch {
            status = "摄像头配置失败: \(error.localizedDescription)"
        }
    }
}

struct SimpleCameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

#Preview {
    CameraTestView()
}








