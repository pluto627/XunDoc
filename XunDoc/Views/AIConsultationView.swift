//
//  AIConsultationView.swift
//  XunDoc
//
//  Created by pluto guo on 9/15/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct AIConsultationView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var apiManager: MoonshotAPIManager
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var symptoms: [String] = []
    @State private var newSymptom = ""
    @State private var analysisResult: SkinAnalysisResult?
    @State private var isAnalyzing = false
    @State private var showingResult = false
    @State private var consultationType: ConsultationType = .skin
    @State private var textInput = ""
    
    enum ConsultationType: String, CaseIterable {
        case skin = "Skin Analysis"
        case symptom = "Symptom Analysis"
        case report = "Report Interpretation"
        case medication = "Medication Guidance"
        
        var icon: String {
            switch self {
            case .skin: return "camera.fill"
            case .symptom: return "text.bubble.fill"
            case .report: return "doc.text.fill"
            case .medication: return "pills.fill"
            }
        }
        
        var localized: String {
            switch self {
            case .skin: return NSLocalizedString("consultation_skin", comment: "")
            case .symptom: return NSLocalizedString("consultation_symptom", comment: "")
            case .report: return NSLocalizedString("consultation_report", comment: "")
            case .medication: return NSLocalizedString("consultation_medication", comment: "")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 咨询类型选择
                    ConsultationTypePicker(selection: $consultationType)
                    
                    switch consultationType {
                    case .skin:
                        SkinAnalysisSection(
                            selectedImage: $selectedImage,
                            symptoms: $symptoms,
                            showingImagePicker: $showingImagePicker,
                            showingCamera: $showingCamera
                        )
                    case .symptom:
                        SymptomAnalysisSection(textInput: $textInput)
                    case .report:
                        ReportInterpretationSection(textInput: $textInput)
                    case .medication:
                        MedicationGuidanceSection(textInput: $textInput)
                    }
                    
                    // 分析按钮
                    AnalyzeButton(
                        consultationType: consultationType,
                        isAnalyzing: $isAnalyzing,
                        action: performAnalysis
                    )
                    
                    // 历史记录
                    ConsultationHistorySection()
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle(NSLocalizedString("ai_consultation", comment: ""))
            .sheet(isPresented: $showingImagePicker) {
                OriginalImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                OriginalImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingResult) {
                if let result = analysisResult {
                    AnalysisResultView(analysisText: result.description)
                }
            }
        }
    }
    
    private func performAnalysis() {
        Task {
            isAnalyzing = true
            
            do {
                switch consultationType {
                case .skin:
                    guard let image = selectedImage else { return }
                    let result = try await apiManager.analyzeSkinCondition(image: image, symptoms: symptoms)
                    analysisResult = result
                    
                    // 保存咨询记录
                    let consultation = AIConsultation(
                        date: Date(),
                        symptomImage: image.jpegData(compressionQuality: 0.5),
                        symptoms: symptoms,
                        aiAnalysis: result.description,
                        recommendations: result.recommendations,
                        severity: AIConsultation.Severity(rawValue: result.severity.capitalized) ?? .medium
                    )
                    healthDataManager.addAIConsultation(consultation)
                    
                case .symptom:
                    let result = try await apiManager.analyzeSymptoms(textInput)
                    // 处理症状分析结果
                    
                case .report:
                    let result = try await apiManager.interpretHealthReport(textInput)
                    // 处理报告解读结果
                    
                case .medication:
                    let result = try await apiManager.getMedicationGuidance(medication: textInput, condition: "")
                    // 处理用药指导结果
                }
                
                showingResult = true
            } catch {
                // 处理错误
                print("Analysis failed: \(error)")
            }
            
            isAnalyzing = false
        }
    }
}

// MARK: - 咨询类型选择器
struct ConsultationTypePicker: View {
    @Binding var selection: AIConsultationView.ConsultationType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(AIConsultationView.ConsultationType.allCases, id: \.self) { type in
                    ConsultationTypeCard(
                        type: type,
                        isSelected: selection == type
                    )
                    .onTapGesture {
                        withAnimation {
                            selection = type
                        }
                    }
                }
            }
        }
    }
}

struct ConsultationTypeCard: View {
    let type: AIConsultationView.ConsultationType
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 60, height: 60)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(15)
            
            Text(type.localized)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .gray)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }
}

// MARK: - 皮肤分析部分
struct SkinAnalysisSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var symptoms: [String]
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    @State private var newSymptom = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 图片选择
            Text(NSLocalizedString("select_photo", comment: ""))
                .font(.headline)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
                    .overlay(
                        Button(action: {
                            selectedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(5),
                        alignment: .topTrailing
                    )
            } else {
                HStack(spacing: 20) {
                    Button(action: {
                        showingCamera = true
                    }) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                            Text(NSLocalizedString("take_photo", comment: ""))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.largeTitle)
                            Text(NSLocalizedString("choose_photo", comment: ""))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .foregroundColor(.blue)
            }
            
            // 症状输入
            Text(NSLocalizedString("describe_symptoms", comment: ""))
                .font(.headline)
                .padding(.top)
            
            HStack {
                TextField(NSLocalizedString("enter_symptom", comment: ""), text: $newSymptom)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !newSymptom.isEmpty {
                        symptoms.append(newSymptom)
                        newSymptom = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // 症状标签
            if !symptoms.isEmpty {
                FlowLayout(spacing: 10) {
                    ForEach(symptoms, id: \.self) { symptom in
                        SymptomTag(symptom: symptom) {
                            symptoms.removeAll { $0 == symptom }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

// MARK: - 症状分析部分
struct SymptomAnalysisSection: View {
    @Binding var textInput: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(NSLocalizedString("describe_symptoms_detail", comment: ""))
                .font(.headline)
            
            TextEditor(text: $textInput)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text(NSLocalizedString("symptom_analysis_hint", comment: ""))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

// MARK: - 报告解读部分
struct ReportInterpretationSection: View {
    @Binding var textInput: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(NSLocalizedString("paste_report", comment: ""))
                .font(.headline)
            
            TextEditor(text: $textInput)
                .frame(minHeight: 200)
                .padding(8)
                .background(Color.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                Text(NSLocalizedString("scan_report_hint", comment: ""))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

// MARK: - 用药指导部分
struct MedicationGuidanceSection: View {
    @Binding var textInput: String
    @State private var condition = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(NSLocalizedString("medication_name", comment: ""))
                .font(.headline)
            
            TextField(NSLocalizedString("enter_medication_name", comment: ""), text: $textInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text(NSLocalizedString("usage_condition", comment: ""))
                .font(.headline)
                .padding(.top)
            
            TextField(NSLocalizedString("enter_condition", comment: ""), text: $condition)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text(NSLocalizedString("medication_guidance_hint", comment: ""))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

// MARK: - 分析按钮
struct AnalyzeButton: View {
    let consultationType: AIConsultationView.ConsultationType
    @Binding var isAnalyzing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                
                Text(isAnalyzing ? NSLocalizedString("analyzing", comment: "") : NSLocalizedString("start_analysis", comment: ""))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isAnalyzing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isAnalyzing)
    }
}

// MARK: - 咨询历史
struct ConsultationHistorySection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(NSLocalizedString("consultation_history", comment: ""))
                .font(.headline)
            
            let consultations = healthDataManager.getAIConsultations().prefix(5)
                
            if consultations.isEmpty {
                Text(NSLocalizedString("no_consultation_history", comment: ""))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(consultations), id: \.id) { consultation in
                    ConsultationHistoryRow(consultation: consultation)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

struct ConsultationHistoryRow: View {
    let consultation: AIConsultation
    
    var body: some View {
        HStack {
            consultation.severity.color
                .frame(width: 4)
            
            VStack(alignment: .leading) {
                Text(consultation.symptoms.joined(separator: ", "))
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(consultation.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - 辅助视图
struct SymptomTag: View {
    let symptom: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(symptom)
                .font(.caption)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(15)
    }
}

// Flow Layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + viewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: viewSize))
                lineHeight = max(lineHeight, viewSize.height)
                currentX += viewSize.width + spacing
                
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
        }
    }
}

#Preview {
    AIConsultationView()
        .environmentObject(HealthDataManager.shared)
        .environmentObject(MoonshotAPIManager.shared)
}

