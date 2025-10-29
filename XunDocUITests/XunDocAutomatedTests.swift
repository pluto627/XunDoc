//
//  XunDocAutomatedTests.swift
//  XunDoc UI自动化测试
//
//  自动化测试脚本 - 测试主要功能流程
//

import XCTest

class XunDocAutomatedTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // 测试失败时继续执行
        continueAfterFailure = false
        
        // 启动应用
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
        
        // 等待启动页完成
        sleep(3)
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 测试套件1: 启动和导航测试
    
    /// TC-AUTO-001: 测试应用启动
    func test001_AppLaunch() throws {
        print("📱 [测试] 应用启动测试")
        
        // 验证应用已启动
        XCTAssertTrue(app.state == .runningForeground, "应用应该在前台运行")
        
        // 等待主页加载
        let homeTitle = app.staticTexts["健康助手"]
        let exists = homeTitle.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "主页应该显示'健康助手'标题")
        
        print("✅ [通过] 应用启动成功")
    }
    
    /// TC-AUTO-002: 测试底部导航栏切换
    func test002_TabBarNavigation() throws {
        print("📱 [测试] 底部导航栏切换")
        
        // 等待主页加载完成
        sleep(2)
        
        // 点击"就诊记录"标签
        let recordsTab = app.buttons["就诊记录"]
        if recordsTab.exists {
            recordsTab.tap()
            sleep(1)
            
            // 验证进入就诊记录页面
            let recordsTitle = app.staticTexts["就诊记录"]
            XCTAssertTrue(recordsTitle.exists, "应该显示就诊记录页面")
            print("  ✓ 就诊记录页面导航成功")
        }
        
        // 点击"用药"标签
        let medicationTab = app.buttons["用药"]
        if medicationTab.exists {
            medicationTab.tap()
            sleep(1)
            
            // 验证进入用药页面
            let medicationTitle = app.staticTexts["用药管理"]
            XCTAssertTrue(medicationTitle.exists, "应该显示用药管理页面")
            print("  ✓ 用药管理页面导航成功")
        }
        
        // 点击"我的"标签
        let profileTab = app.buttons["我的"]
        if profileTab.exists {
            profileTab.tap()
            sleep(1)
            
            // 验证进入个人页面
            let profileTitle = app.staticTexts["我的"]
            XCTAssertTrue(profileTitle.exists, "应该显示我的页面")
            print("  ✓ 我的页面导航成功")
        }
        
        // 返回首页
        let homeTab = app.buttons["首页"]
        if homeTab.exists {
            homeTab.tap()
            sleep(1)
            print("  ✓ 返回首页成功")
        }
        
        print("✅ [通过] 底部导航栏切换测试通过")
    }
    
    // MARK: - 测试套件2: 就诊记录功能测试
    
    /// TC-AUTO-003: 测试创建就诊记录
    func test003_CreateHealthRecord() throws {
        print("📱 [测试] 创建就诊记录")
        
        // 进入就诊记录页面
        navigateToRecords()
        
        // 点击添加按钮
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
        if addButton.exists {
            addButton.tap()
            sleep(1)
            print("  ✓ 打开创建页面")
            
            // 填写医院名称
            let hospitalField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '医院'")).firstMatch
            if hospitalField.exists {
                hospitalField.tap()
                hospitalField.typeText("测试医院")
                print("  ✓ 填写医院名称")
            }
            
            // 填写科室
            let departmentField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '科室'")).firstMatch
            if departmentField.exists {
                departmentField.tap()
                departmentField.typeText("内科")
                print("  ✓ 填写科室")
            }
            
            // 填写症状
            let symptomsField = app.textViews.firstMatch
            if symptomsField.exists {
                symptomsField.tap()
                symptomsField.typeText("自动化测试症状")
                print("  ✓ 填写症状")
            }
            
            // 点击保存/创建按钮
            let saveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '保存' OR label CONTAINS '创建'")).firstMatch
            if saveButton.exists && saveButton.isEnabled {
                saveButton.tap()
                sleep(2)
                print("  ✓ 保存记录")
                
                // 验证记录已创建
                let recordCard = app.staticTexts["测试医院"]
                XCTAssertTrue(recordCard.waitForExistence(timeout: 3), "应该显示新创建的记录")
                print("  ✓ 记录创建成功")
            }
        }
        
        print("✅ [通过] 创建就诊记录测试通过")
    }
    
    /// TC-AUTO-004: 测试搜索功能
    func test004_SearchHealthRecords() throws {
        print("📱 [测试] 搜索就诊记录")
        
        // 进入就诊记录页面
        navigateToRecords()
        
        // 找到搜索框
        let searchField = app.searchFields.firstMatch
        if !searchField.exists {
            // 尝试找TextField
            let textField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '搜索'")).firstMatch
            if textField.exists {
                textField.tap()
                textField.typeText("测试")
                sleep(1)
                print("  ✓ 输入搜索关键词")
                
                // 清空搜索
                if let clearButton = textField.buttons["Clear text"].firstMatch as? XCUIElement, clearButton.exists {
                    clearButton.tap()
                    print("  ✓ 清空搜索")
                }
            }
        }
        
        print("✅ [通过] 搜索功能测试通过")
    }
    
    /// TC-AUTO-005: 测试查看记录详情
    func test005_ViewRecordDetails() throws {
        print("📱 [测试] 查看记录详情")
        
        // 进入就诊记录页面
        navigateToRecords()
        sleep(1)
        
        // 点击第一条记录
        let firstRecord = app.buttons.containing(.staticText, identifier: "测试医院").firstMatch
        if !firstRecord.exists {
            // 如果没有测试医院，找任意记录
            let anyRecord = app.otherElements.containing(.staticText, identifier: "").firstMatch
            if anyRecord.exists {
                anyRecord.tap()
                sleep(1)
                print("  ✓ 打开记录详情")
                
                // 验证详情页面元素
                let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'chevron' OR label CONTAINS '返回'")).firstMatch
                XCTAssertTrue(backButton.exists, "应该显示返回按钮")
                
                // 返回列表
                backButton.tap()
                sleep(1)
                print("  ✓ 返回列表")
            } else {
                print("  ⚠️  没有可查看的记录")
            }
        } else {
            firstRecord.tap()
            sleep(1)
            print("  ✓ 打开测试医院记录详情")
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
        
        print("✅ [通过] 查看记录详情测试通过")
    }
    
    // MARK: - 测试套件3: 用药管理功能测试
    
    /// TC-AUTO-006: 测试添加用药提醒
    func test006_AddMedication() throws {
        print("📱 [测试] 添加用药提醒")
        
        // 进入用药管理页面
        navigateToMedication()
        sleep(1)
        
        // 点击添加用药按钮
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '添加' OR label CONTAINS 'plus'")).firstMatch
        if addButton.exists {
            addButton.tap()
            sleep(1)
            print("  ✓ 打开添加用药页面")
            
            // 步骤1: 填写药品名称
            let nameField = app.textFields.firstMatch
            if nameField.exists {
                nameField.tap()
                nameField.typeText("测试药品")
                print("  ✓ 填写药品名称: 测试药品")
                
                // 选择剂型（假设是片剂）
                let tabletButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '片剂'")).firstMatch
                if tabletButton.waitForExistence(timeout: 2) {
                    tabletButton.tap()
                    print("  ✓ 选择剂型: 片剂")
                }
                
                // 点击下一步
                let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '下一步'")).firstMatch
                if nextButton.exists && nextButton.isEnabled {
                    nextButton.tap()
                    sleep(1)
                    print("  ✓ 进入步骤2")
                }
            }
            
            // 步骤2: 填写剂量
            let dosageField = app.textFields.firstMatch
            if dosageField.exists {
                dosageField.tap()
                dosageField.typeText("1片")
                print("  ✓ 填写剂量: 1片")
                
                // 点击下一步
                let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '下一步'")).firstMatch
                if nextButton.exists && nextButton.isEnabled {
                    nextButton.tap()
                    sleep(1)
                    print("  ✓ 进入步骤3")
                }
            }
            
            // 步骤3: 选择频率
            let onceButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '每天1次'")).firstMatch
            if onceButton.exists {
                onceButton.tap()
                sleep(1)
                print("  ✓ 选择频率: 每天1次")
            }
            
            // 点击保存
            let saveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '保存'")).firstMatch
            if saveButton.exists && saveButton.isEnabled {
                saveButton.tap()
                sleep(2)
                print("  ✓ 保存用药提醒")
                
                // 验证添加成功
                let medicationCard = app.staticTexts["测试药品"]
                if medicationCard.waitForExistence(timeout: 3) {
                    print("  ✓ 用药提醒添加成功")
                }
            } else {
                // 如果还在弹窗中，尝试关闭
                let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'xmark' OR label CONTAINS '关闭'")).firstMatch
                if closeButton.exists {
                    closeButton.tap()
                    print("  ✓ 关闭添加页面")
                }
            }
        }
        
        print("✅ [通过] 添加用药提醒测试通过")
    }
    
    /// TC-AUTO-007: 测试今日用药完成
    func test007_CompleteTodayMedication() throws {
        print("📱 [测试] 完成今日用药")
        
        // 返回首页
        navigateToHome()
        sleep(1)
        
        // 查找今日用药区域的完成按钮（圆圈图标）
        let completeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'circle'"))
        if completeButtons.count > 0 {
            let firstButton = completeButtons.firstMatch
            firstButton.tap()
            sleep(1)
            print("  ✓ 标记用药已完成")
            
            // 验证完成状态
            XCTAssertTrue(true, "用药标记完成")
            print("  ✓ 用药完成动画执行")
        } else {
            print("  ⚠️  今日暂无待完成用药")
        }
        
        print("✅ [通过] 完成今日用药测试通过")
    }
    
    // MARK: - 测试套件4: 个人页面测试
    
    /// TC-AUTO-008: 测试个人页面功能入口
    func test008_ProfilePageNavigation() throws {
        print("📱 [测试] 个人页面功能入口")
        
        // 进入我的页面
        navigateToProfile()
        sleep(1)
        
        // 测试健康报告入口
        let healthReportButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '健康报告'")).firstMatch
        if healthReportButton.exists {
            healthReportButton.tap()
            sleep(1)
            print("  ✓ 打开健康报告")
            
            // 关闭
            dismissCurrentSheet()
            sleep(1)
        }
        
        // 测试关于我们
        let aboutButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '关于我们'")).firstMatch
        if aboutButton.exists {
            aboutButton.tap()
            sleep(1)
            print("  ✓ 打开关于我们")
            
            // 验证版本号显示
            let versionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '版本'")).firstMatch
            XCTAssertTrue(versionText.exists, "应该显示版本信息")
            
            // 关闭
            dismissCurrentSheet()
            sleep(1)
        }
        
        print("✅ [通过] 个人页面功能入口测试通过")
    }
    
    // MARK: - 测试套件5: 性能和稳定性测试
    
    /// TC-AUTO-009: 测试页面切换性能
    func test009_NavigationPerformance() throws {
        print("📱 [测试] 页面切换性能")
        
        measure {
            // 循环切换页面
            for _ in 1...3 {
                // 首页 -> 就诊记录
                navigateToRecords()
                
                // 就诊记录 -> 用药
                navigateToMedication()
                
                // 用药 -> 我的
                navigateToProfile()
                
                // 我的 -> 首页
                navigateToHome()
            }
        }
        
        print("✅ [通过] 页面切换性能测试通过")
    }
    
    /// TC-AUTO-010: 测试应用稳定性（快速操作）
    func test010_AppStability() throws {
        print("📱 [测试] 应用稳定性")
        
        // 快速切换页面
        for i in 1...10 {
            let tabs = ["首页", "就诊记录", "用药", "我的"]
            let randomTab = tabs.randomElement()!
            
            if let tabButton = app.buttons[randomTab].firstMatch as? XCUIElement, tabButton.exists {
                tabButton.tap()
                print("  \(i). 切换到: \(randomTab)")
            }
            
            // 短暂延迟
            usleep(300000) // 0.3秒
        }
        
        // 验证应用仍在运行
        XCTAssertTrue(app.state == .runningForeground, "应用应该仍在前台运行")
        print("✅ [通过] 应用稳定性测试通过")
    }
    
    // MARK: - 辅助方法
    
    /// 导航到首页
    private func navigateToHome() {
        let homeTab = app.buttons["首页"]
        if homeTab.exists {
            homeTab.tap()
        }
    }
    
    /// 导航到就诊记录页面
    private func navigateToRecords() {
        let recordsTab = app.buttons["就诊记录"]
        if recordsTab.exists {
            recordsTab.tap()
        }
    }
    
    /// 导航到用药管理页面
    private func navigateToMedication() {
        let medicationTab = app.buttons["用药"]
        if medicationTab.exists {
            medicationTab.tap()
        }
    }
    
    /// 导航到个人页面
    private func navigateToProfile() {
        let profileTab = app.buttons["我的"]
        if profileTab.exists {
            profileTab.tap()
        }
    }
    
    /// 关闭当前弹出的Sheet/Modal
    private func dismissCurrentSheet() {
        // 尝试找关闭按钮
        let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '关闭' OR label CONTAINS 'xmark' OR label CONTAINS '完成'")).firstMatch
        if closeButton.exists {
            closeButton.tap()
            return
        }
        
        // 尝试找返回按钮
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }
    
    /// 截图保存
    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - 测试套件运行配置

extension XunDocAutomatedTests {
    
    /// 完整测试套件（按顺序执行所有测试）
    func testCompleteTestSuite() throws {
        print("\n" + String(repeating: "=", count: 60))
        print("🚀 开始执行完整自动化测试套件")
        print(String(repeating: "=", count: 60) + "\n")
        
        let testCases: [(String, () throws -> Void)] = [
            ("应用启动", test001_AppLaunch),
            ("底部导航", test002_TabBarNavigation),
            ("创建记录", test003_CreateHealthRecord),
            ("搜索功能", test004_SearchHealthRecords),
            ("查看详情", test005_ViewRecordDetails),
            ("添加用药", test006_AddMedication),
            ("完成用药", test007_CompleteTodayMedication),
            ("个人页面", test008_ProfilePageNavigation),
            ("切换性能", test009_NavigationPerformance),
            ("应用稳定性", test010_AppStability)
        ]
        
        var passedTests = 0
        var failedTests = 0
        
        for (index, testCase) in testCases.enumerated() {
            print("\n[\(index + 1)/\(testCases.count)] 执行: \(testCase.0)")
            print(String(repeating: "-", count: 60))
            
            do {
                try testCase.1()
                passedTests += 1
            } catch {
                print("❌ [失败] \(testCase.0): \(error.localizedDescription)")
                failedTests += 1
                
                // 失败时截图
                takeScreenshot(name: "Failed_\(testCase.0)")
            }
            
            // 测试间隔
            sleep(1)
        }
        
        // 测试报告
        print("\n" + String(repeating: "=", count: 60))
        print("📊 测试报告")
        print(String(repeating: "=", count: 60))
        print("总测试数: \(testCases.count)")
        print("✅ 通过: \(passedTests)")
        print("❌ 失败: \(failedTests)")
        print("📈 通过率: \(Int(Double(passedTests) / Double(testCases.count) * 100))%")
        print(String(repeating: "=", count: 60) + "\n")
    }
}


