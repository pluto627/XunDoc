//
//  PhotoDiagnosisView.swift
//  XunDoc
//
//  专门用于图片诊断的界面
//

import SwiftUI
import PhotosUI

struct PhotoDiagnosisView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var apiManager: MoonshotAPIManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var symptoms: [String] = []
    @State private var newSymptom = ""
    @State private var analysisResult: SkinAnalysisResult?
    @State private var isAnalyzing = false
    @State private var showingResult = false
    @State private var additionalNotes = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题和说明
                    HeaderSection()
                    
                    // 图片上传区域
                    ImageUploadSection()
                    
                    // 症状描述区域
                    if selectedImage != nil {
                        SymptomsSection()
                        
                        // 附加说明
                        AdditionalNotesSection()
                        
                        // 分析按钮
                        AnalyzeButton()
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("photo_diagnosis_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel_button", comment: "")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                OriginalImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                OriginalImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingResult) {
                if let result = analysisResult {
                    DiagnosisResultView(result: result, image: selectedImage)
                }
            }
            .alert(NSLocalizedString("error_title", comment: ""), isPresented: $showingError) {
                Button(NSLocalizedString("ok", comment: "")) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 标题区域
    @ViewBuilder
    private func HeaderSection() -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 10)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            
            Text(NSLocalizedString("ai_photo_diagnosis_title", comment: ""))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(NSLocalizedString("upload_image_description", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - 图片上传区域
    @ViewBuilder
    private func ImageUploadSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("upload_image_section", comment: ""))
                .font(.headline)
                .foregroundColor(.primary)
            
            if let selectedImage = selectedImage {
                // 显示已选择的图片
                VStack(spacing: 12) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                    
                    HStack(spacing: 16) {
                        Button(NSLocalizedString("reselect_button", comment: "")) {
                            showingImagePicker = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(NSLocalizedString("photo_action", comment: "")) {
                            showingCamera = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            } else {
                // 图片上传区域
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10]))
                            )
                        
                        VStack(spacing: 16) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.blue.opacity(0.6))
                            
                            Text(NSLocalizedString("click_upload_hint", comment: ""))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("support_formats_hint", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onTapGesture {
                        showingImagePicker = true
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(NSLocalizedString("from_album_action", comment: ""))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text(NSLocalizedString("photo_action", comment: ""))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.appBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 症状描述区域
    @ViewBuilder
    private func SymptomsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("symptom_optional_section", comment: ""))
                .font(.headline)
                .foregroundColor(.primary)
            
            // 添加症状输入框
            HStack {
                TextField(NSLocalizedString("describe_symptoms_placeholder", comment: ""), text: $newSymptom)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addSymptom) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(newSymptom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // 症状标签
            if !symptoms.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(symptoms, id: \.self) { symptom in
                        PhotoSymptomTag(symptom: symptom) {
                            removeSymptom(symptom)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.appBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 附加说明区域
    @ViewBuilder
    private func AdditionalNotesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("additional_notes_section", comment: ""))
                .font(.headline)
                .foregroundColor(.primary)
            
            TextEditor(text: $additionalNotes)
                .frame(height: 100)
                .padding(8)
                .background(Color.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .padding()
        .background(Color.appBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 分析按钮
    @ViewBuilder
    private func AnalyzeButton() -> some View {
        Button(action: performAnalysis) {
            HStack {
                if isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "brain.head.profile")
                }
                
                Text(isAnalyzing ? NSLocalizedString("analyzing_progress", comment: "") : NSLocalizedString("start_analysis_button", comment: ""))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: isAnalyzing ? [.gray, .gray] : [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: isAnalyzing ? .clear : .blue.opacity(0.3), radius: 8)
        }
        .disabled(isAnalyzing || selectedImage == nil)
        .padding(.horizontal)
    }
    
    // MARK: - 辅助方法
    private func addSymptom() {
        let trimmedSymptom = newSymptom.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSymptom.isEmpty && !symptoms.contains(trimmedSymptom) {
            symptoms.append(trimmedSymptom)
            newSymptom = ""
        }
    }
    
    private func removeSymptom(_ symptom: String) {
        symptoms.removeAll { $0 == symptom }
    }
    
    private func performAnalysis() {
        guard let image = selectedImage else { return }
        
        Task {
            isAnalyzing = true
            
            do {
                // 合并症状和附加说明
                var allSymptoms = symptoms
                if !additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    allSymptoms.append(additionalNotes)
                }
                
                let result = try await apiManager.analyzeSkinCondition(image: image, symptoms: allSymptoms)
                
                await MainActor.run {
                    analysisResult = result
                    showingResult = true
                    
                    // 保存诊断记录
                    if true {
                        let consultation = AIConsultation(
                             // 使用默认UUID
                            date: Date(),
                            symptomImage: image.jpegData(compressionQuality: 0.7),
                            symptoms: allSymptoms,
                            aiAnalysis: result.description,
                            recommendations: result.recommendations,
                            severity: AIConsultation.Severity(rawValue: result.severity.capitalized) ?? .medium
                        )
                        healthDataManager.addAIConsultation(consultation)
                    }
                }
            } catch {
                await MainActor.run {
                    // 处理错误
                    print("分析失败: \(error)")
                    errorMessage = "分析失败: \(error.localizedDescription)"
                    showingError = true
                }
            }
            
            await MainActor.run {
                isAnalyzing = false
            }
        }
    }
}

// MARK: - 症状标签
struct PhotoSymptomTag: View {
    let symptom: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(symptom)
                .font(.caption)
                .foregroundColor(.blue)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - 诊断结果视图
struct DiagnosisResultView: View {
    let result: SkinAnalysisResult
    let image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 图片预览
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    }
                    
                    // 分析结果
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("ai_analysis_result_title", comment: ""))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        MarkdownText(text: result.description)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    
                    // 建议
                    if !result.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("professional_advice_title", comment: ""))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(result.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(recommendation)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(red: 245/255, green: 237/255, blue: 220/255))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 3)
                    }
                    
                    // 严重程度提示
                    if result.needMedicalAttention {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(NSLocalizedString("attention_recommended", comment: ""))
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            
                            Text(NSLocalizedString("consult_doctor_message", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("diagnosis_result_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done_button", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 辅助样式
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}


#Preview {
    PhotoDiagnosisView()
        .environmentObject(HealthDataManager.shared)
        .environmentObject(MoonshotAPIManager.shared)
}
