#!/bin/bash
# 批量修复文件中的成员引用

FILES=(
    "XunDoc/Views/Components/AIReportAnalysisView.swift"
    "XunDoc/Views/Components/BottomAIChatView.swift"
    "XunDoc/Views/AddConversationView.swift"
    "XunDoc/Views/AddPrescriptionView.swift"
    "XunDoc/Views/AddReportWithExcelView.swift"
    "XunDoc/Views/AIAssistantView.swift"
    "XunDoc/Views/MedicalReportsListView.swift"
    "XunDoc/Views/PhotoDiagnosisView.swift"
    "XunDoc/Views/ProfileView.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file"
        # 删除 guard let member = healthDataManager.currentMember else { return } 等检查
        sed -i.bak '/guard let member = healthDataManager.currentMember else { return }/d' "$file"
        sed -i.bak '/guard let member = healthDataManager.currentMember else { return "" }/d' "$file"
        sed -i.bak '/guard let member = healthDataManager.currentMember else { return \[\] }/d' "$file"
    fi
done

echo "Done"

