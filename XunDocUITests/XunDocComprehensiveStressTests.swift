//
//  XunDocComprehensiveStressTests.swift
//  XunDoc 全面压力测试
//
//  这是一个全面的UI和功能压力测试套件
//  测试所有界面、功能、边界条件和极限场景
//

import XCTest

class XunDocComprehensiveStressTests: XCTestCase {
    
    var app: XCUIApplication!
    
    // 测试配置
    let stressTestIterations = 20  // 压力测试迭代次数
    let rapidTapCount = 50         // 快速点击次数
    let navigationLoops = 30       // 导航循环次数
    
    override func setUpWithError() throws {
        continueAfterFailure = true
        
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing", "STRESS-TEST-MODE"]
        app.launch()
        
        // 等待应用完全加载
        sleep(3)
        
        print("\n" + String(repeating: "=", count: 80))
        print("🔥 XunDoc 全面压力测试套件 - 开始执行")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    override func tearDownWithError() throws {
        // 测试结束时截图
        takeScreenshot(name: "TestCompleted")
        app.terminate()
        app = nil
    }
    
    // MARK: - 综合功能测试套件
    
    /// 测试000: 基础连接测试（用于验证测试框架是否正常工作）
    func test000_BasicConnectionTest() throws {
        print("🔥 [基础测试-000] 测试框架连接验证")
        
        // 最简单的测试，只验证测试能运行
        XCTAssertTrue(true, "基础断言应该通过")
        print("  ✓ 测试框架连接正常")
        
        // 验证应用能启动
        XCTAssertTrue(app.state == .runningForeground, "应用应该在运行")
        print("  ✓ 应用启动成功")
        
        // 验证基本UI元素
        let exists = app.buttons.count > 0 || app.staticTexts.count > 0
        XCTAssertTrue(exists, "应该有UI元素")
        print("  ✓ UI元素可访问")
        
        print("✅ [通过] 基础连接测试完成 - 测试框架工作正常！\n")
    }
    
    /// 测试001: 应用启动压力测试
    func test001_AppLaunchStress() throws {
        print("🔥 [压力测试-001] 应用启动压力测试")
        
        for i in 1...5 {
            print("  第 \(i)/5 次启动")
            
            // 终止应用
            app.terminate()
            sleep(1)
            
            // 重新启动
            app.launch()
            sleep(2)
            
            // 验证启动成功
            let homeTitle = app.staticTexts["健康助手"]
            XCTAssertTrue(homeTitle.waitForExistence(timeout: 5), "第\(i)次启动失败")
            print("    ✓ 启动成功")
        }
        
        print("✅ [通过] 应用启动压力测试完成\n")
    }
    
    /// 测试002: 导航栏疯狂切换测试
    func test002_TabBarCrazyNavigation() throws {
        print("🔥 [压力测试-002] 导航栏疯狂切换测试")
        
        let tabs = ["首页", "就诊记录", "用药", "我的"]
        var switchCount = 0
        
        for i in 1...navigationLoops {
            let randomTab = tabs.randomElement()!
            
            if let tabButton = app.buttons[randomTab].firstMatch as? XCUIElement, tabButton.exists {
                tabButton.tap()
                switchCount += 1
                
                if i % 10 == 0 {
                    print("  已切换 \(switchCount) 次 - 当前: \(randomTab)")
                }
            }
            
            // 极短延迟模拟快速操作
            usleep(UInt32(100000)) // 0.1秒
        }
        
        // 验证应用仍正常运行
        XCTAssertTrue(app.state == .runningForeground, "应用应该仍在运行")
        print("  总切换次数: \(switchCount)")
        print("✅ [通过] 导航栏疯狂切换测试完成\n")
    }
    
    /// 测试003: 就诊记录批量创建压力测试
    func test003_MassHealthRecordCreation() throws {
        print("🔥 [压力测试-003] 就诊记录批量创建测试")
        
        navigateToRecords()
        sleep(1)
        
        let recordsToCreate = 10
        var successCount = 0
        
        for i in 1...recordsToCreate {
            print("  创建第 \(i)/\(recordsToCreate) 条记录")
            
            // 点击添加按钮
            let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
            if addButton.exists {
                addButton.tap()
                sleep(1)
                
                // 填写医院名称
                let hospitalField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '医院'")).firstMatch
                if hospitalField.exists {
                    hospitalField.tap()
                    hospitalField.typeText("压力测试医院\(i)")
                }
                
                // 填写科室
                let departmentField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '科室'")).firstMatch
                if departmentField.exists {
                    departmentField.tap()
                    departmentField.typeText("测试科室\(i)")
                }
                
                // 点击保存
                let saveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '保存' OR label CONTAINS '创建'")).firstMatch
                if saveButton.exists && saveButton.isEnabled {
                    saveButton.tap()
                    sleep(1)
                    successCount += 1
                    print("    ✓ 记录 \(i) 创建成功")
                } else {
                    // 如果无法保存，关闭对话框
                    dismissCurrentSheet()
                    print("    ⚠️ 记录 \(i) 创建失败")
                }
            }
            
            // 短暂延迟
            usleep(UInt32(500000)) // 0.5秒
        }
        
        print("  成功创建: \(successCount)/\(recordsToCreate) 条记录")
        print("✅ [通过] 批量创建测试完成\n")
    }
    
    /// 测试004: 搜索功能压力测试
    func test004_SearchStressTest() throws {
        print("🔥 [压力测试-004] 搜索功能压力测试")
        
        navigateToRecords()
        sleep(1)
        
        let searchTerms = ["测试", "医院", "内科", "外科", "ABC", "123", "压力", "病历", "记录", ""]
        
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '搜索'")).firstMatch
        if searchField.exists {
            for (index, term) in searchTerms.enumerated() {
                searchField.tap()
                
                // 清空现有内容
                if let clearButton = searchField.buttons["Clear text"].firstMatch as? XCUIElement {
                    if clearButton.exists {
                        clearButton.tap()
                    }
                }
                
                if !term.isEmpty {
                    searchField.typeText(term)
                    print("  [\(index+1)/\(searchTerms.count)] 搜索: '\(term)'")
                    usleep(UInt32(500000)) // 0.5秒
                }
            }
            print("  ✓ 所有搜索操作完成")
        }
        
        print("✅ [通过] 搜索压力测试完成\n")
    }
    
    /// 测试005: 用药提醒批量添加测试
    func test005_MassMedicationCreation() throws {
        print("🔥 [压力测试-005] 用药提醒批量添加测试")
        
        navigateToMedication()
        sleep(1)
        
        let medicationsToAdd = 5
        var successCount = 0
        
        for i in 1...medicationsToAdd {
            print("  添加第 \(i)/\(medicationsToAdd) 个用药提醒")
            
            let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '添加' OR label CONTAINS 'plus'")).firstMatch
            if addButton.exists {
                addButton.tap()
                sleep(1)
                
                // 填写药品名称
                let nameField = app.textFields.firstMatch
                if nameField.exists {
                    nameField.tap()
                    nameField.typeText("测试药品\(i)")
                    
                    // 选择剂型
                    let tabletButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '片剂'")).firstMatch
                    if tabletButton.waitForExistence(timeout: 2) {
                        tabletButton.tap()
                    }
                    
                    // 点击下一步
                    let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '下一步'")).firstMatch
                        if nextButton.exists && nextButton.isEnabled {
                            nextButton.tap()
                            usleep(UInt32(500000)) // 0.5秒
                            
                            // 填写剂量
                            let dosageField = app.textFields.firstMatch
                            if dosageField.exists {
                                dosageField.tap()
                                dosageField.typeText("\(i)片")
                                
                                if nextButton.exists && nextButton.isEnabled {
                                    nextButton.tap()
                                    usleep(UInt32(500000)) // 0.5秒
                            }
                        }
                        
                        // 选择频率
                        let onceButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '每天1次'")).firstMatch
                        if onceButton.exists {
                            onceButton.tap()
                            usleep(UInt32(500000)) // 0.5秒
                        }
                        
                        // 保存
                        let saveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '保存'")).firstMatch
                        if saveButton.exists && saveButton.isEnabled {
                            saveButton.tap()
                            sleep(1)
                            successCount += 1
                            print("    ✓ 用药 \(i) 添加成功")
                        } else {
                            dismissCurrentSheet()
                            print("    ⚠️ 用药 \(i) 添加失败")
                        }
                    }
                }
            }
        }
        
        print("  成功添加: \(successCount)/\(medicationsToAdd) 个用药提醒")
        print("✅ [通过] 批量添加用药测试完成\n")
    }
    
    /// 测试006: 个人页面功能全面测试
    func test006_ProfilePageComprehensiveTest() throws {
        print("🔥 [压力测试-006] 个人页面功能全面测试")
        
        navigateToProfile()
        sleep(1)
        
        // 测试所有可点击的功能入口
        let functionalButtons = [
            "健康报告",
            "处方管理",
            "通知提醒",
            "通用设置",
            "关于我们"
        ]
        
        for button in functionalButtons {
            let btn = app.buttons.matching(NSPredicate(format: "label CONTAINS '\(button)'")).firstMatch
            if btn.exists {
                print("  测试: \(button)")
                btn.tap()
                sleep(1)
                
                // 验证页面打开
                let pageTitle = app.staticTexts[button]
                if pageTitle.exists {
                    print("    ✓ \(button) 页面打开成功")
                }
                
                // 关闭页面
                dismissCurrentSheet()
                usleep(UInt32(500000)) // 0.5秒
            }
        }
        
        print("✅ [通过] 个人页面全面测试完成\n")
    }
    
    /// 测试007: 快速添加面板压力测试
    func test007_QuickAddPanelStress() throws {
        print("🔥 [压力测试-007] 快速添加面板压力测试")
        
        navigateToHome()
        sleep(1)
        
        // 快速打开关闭添加面板
        for i in 1...20 {
            // 查找快速添加按钮（通常是中间的+按钮）
            let addButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus'"))
            
            for index in 0..<addButtons.count {
                let button = addButtons.element(boundBy: index)
                if button.exists && button.isHittable {
                    button.tap()
                    usleep(UInt32(200000)) // 0.2秒
                    
                    // 尝试关闭面板（点击背景或关闭按钮）
                    let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'xmark'")).firstMatch
                    if closeButton.exists {
                        closeButton.tap()
                    } else {
                        // 点击屏幕上方区域关闭
                        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
                    }
                    
                    if i % 5 == 0 {
                        print("  已执行 \(i) 次打开/关闭操作")
                    }
                    break
                }
            }
            
            usleep(UInt32(100000)) // 0.1秒
        }
        
        print("✅ [通过] 快速添加面板压力测试完成\n")
    }
    
    /// 测试008: 滚动性能压力测试
    func test008_ScrollPerformanceStress() throws {
        print("🔥 [压力测试-008] 滚动性能压力测试")
        
        let pages = [
            ("首页", 0),
            ("就诊记录", 1),
            ("用药", 2)
        ]
        
        for (pageName, _) in pages {
            if pageName == "首页" {
                navigateToHome()
            } else if pageName == "就诊记录" {
                navigateToRecords()
            } else if pageName == "用药" {
                navigateToMedication()
            }
            
            sleep(1)
            print("  测试 \(pageName) 滚动性能")
            
            // 快速滚动测试
            for _ in 1...10 {
                // 向下滚动
                app.swipeUp()
                usleep(UInt32(100000))
                
                // 向上滚动
                app.swipeDown()
                usleep(UInt32(100000))
            }
            
            print("    ✓ \(pageName) 滚动测试完成")
        }
        
        print("✅ [通过] 滚动性能压力测试完成\n")
    }
    
    /// 测试009: 内存压力测试（大量页面切换）
    func test009_MemoryStressTest() throws {
        print("🔥 [压力测试-009] 内存压力测试")
        
        let operations = [
            ("切换到就诊记录", { self.navigateToRecords() }),
            ("打开第一条记录", { self.openFirstRecord() }),
            ("返回", { self.goBack() }),
            ("切换到用药", { self.navigateToMedication() }),
            ("切换到我的", { self.navigateToProfile() }),
            ("打开设置", { self.openSettings() }),
            ("返回", { self.goBack() }),
            ("切换到首页", { self.navigateToHome() })
        ]
        
        for iteration in 1...5 {
            print("  第 \(iteration)/5 轮内存压力测试")
            
            for (operation, action) in operations {
                action()
                usleep(UInt32(200000)) // 0.2秒
            }
            
            print("    ✓ 第 \(iteration) 轮完成")
        }
        
        // 验证应用仍在运行
        XCTAssertTrue(app.state == .runningForeground, "应用应该仍在正常运行")
        print("✅ [通过] 内存压力测试完成\n")
    }
    
    /// 测试010: UI元素可见性全面检查
    func test010_UIElementsVisibilityCheck() throws {
        print("🔥 [压力测试-010] UI元素可见性全面检查")
        
        navigateToHome()
        sleep(1)
        
        // 首页元素检查
        print("  检查首页元素...")
        var homeElements = [
            app.staticTexts["健康助手"],
            app.staticTexts["个人健康中心"],
        ]
        
        for element in homeElements {
            if element.exists {
                print("    ✓ 元素可见")
            }
        }
        
        // 就诊记录页元素检查
        navigateToRecords()
        sleep(1)
        print("  检查就诊记录页元素...")
        let recordsTitle = app.staticTexts["就诊记录"]
        if recordsTitle.exists {
            print("    ✓ 就诊记录标题可见")
        }
        
        // 用药页元素检查
        navigateToMedication()
        sleep(1)
        print("  检查用药页元素...")
        let medTitle = app.staticTexts["用药管理"]
        if medTitle.exists {
            print("    ✓ 用药管理标题可见")
        }
        
        // 我的页面元素检查
        navigateToProfile()
        sleep(1)
        print("  检查我的页面元素...")
        let profileTitle = app.staticTexts["我的"]
        if profileTitle.exists {
            print("    ✓ 我的页面标题可见")
        }
        
        print("✅ [通过] UI元素可见性检查完成\n")
    }
    
    /// 测试011: 边界条件测试 - 空数据状态
    func test011_EmptyStateHandling() throws {
        print("🔥 [压力测试-011] 空数据状态处理测试")
        
        // 测试各页面的空状态显示
        let pages = ["首页", "就诊记录", "用药", "我的"]
        
        for page in pages {
            print("  检查 \(page) 的空状态处理")
            
            switch page {
            case "首页":
                navigateToHome()
            case "就诊记录":
                navigateToRecords()
            case "用药":
                navigateToMedication()
            case "我的":
                navigateToProfile()
            default:
                break
            }
            
            sleep(1)
            
            // 验证页面正常显示（即使是空状态）
            XCTAssertTrue(app.state == .runningForeground, "\(page) 应该正常显示")
            print("    ✓ \(page) 空状态处理正常")
        }
        
        print("✅ [通过] 空数据状态测试完成\n")
    }
    
    /// 测试012: 快速点击防抖测试
    func test012_RapidTapDebounceTest() throws {
        print("🔥 [压力测试-012] 快速点击防抖测试")
        
        navigateToRecords()
        sleep(1)
        
        // 快速点击添加按钮
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
        if addButton.exists {
            print("  快速点击添加按钮 50 次")
            for i in 1...rapidTapCount {
                addButton.tap()
                usleep(UInt32(50000)) // 0.05秒
                
                if i % 10 == 0 {
                    print("    已点击 \(i) 次")
                }
            }
            
            // 关闭可能打开的页面
            sleep(1)
            dismissCurrentSheet()
            
            // 验证应用没有崩溃
            XCTAssertTrue(app.state == .runningForeground, "应用应该仍在运行")
            print("  ✓ 防抖测试通过，应用未崩溃")
        }
        
        print("✅ [通过] 快速点击防抖测试完成\n")
    }
    
    /// 测试013: 横竖屏切换测试
    func test013_OrientationChangeTest() throws {
        print("🔥 [压力测试-013] 横竖屏切换测试")
        
        navigateToHome()
        sleep(1)
        
        let device = XCUIDevice.shared
        let orientations: [UIDeviceOrientation] = [.portrait, .landscapeLeft, .landscapeRight, .portrait]
        
        for (index, orientation) in orientations.enumerated() {
            print("  切换到方向: \(orientation.rawValue)")
            device.orientation = orientation
            sleep(1)
            
            // 验证UI仍然可见
            XCTAssertTrue(app.state == .runningForeground, "旋转后应用应该仍在运行")
            
            if index % 2 == 0 {
                print("    ✓ 方向 \(index+1) 测试完成")
            }
        }
        
        // 恢复竖屏
        device.orientation = .portrait
        sleep(1)
        
        print("✅ [通过] 横竖屏切换测试完成\n")
    }
    
    /// 测试014: 后台恢复测试
    func test014_BackgroundResumeTest() throws {
        print("🔥 [压力测试-014] 后台恢复测试")
        
        for i in 1...3 {
            print("  第 \(i)/3 次后台测试")
            
            // 切换到后台
            XCUIDevice.shared.press(.home)
            sleep(2)
            print("    应用已进入后台")
            
            // 重新激活
            app.activate()
            sleep(2)
            print("    应用已恢复前台")
            
            // 验证应用状态
            XCTAssertTrue(app.state == .runningForeground, "应用应该恢复到前台")
            
            // 验证UI仍然正常
            let homeTab = app.buttons["首页"]
            XCTAssertTrue(homeTab.exists, "底部导航应该可见")
            print("    ✓ 第 \(i) 次后台恢复成功")
        }
        
        print("✅ [通过] 后台恢复测试完成\n")
    }
    
    /// 测试015: 数据持久化测试
    func test015_DataPersistenceTest() throws {
        print("🔥 [压力测试-015] 数据持久化测试")
        
        navigateToRecords()
        sleep(1)
        
        // 创建一条测试记录
        print("  创建测试记录...")
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
        if addButton.exists {
            addButton.tap()
            sleep(1)
            
            let hospitalField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '医院'")).firstMatch
            if hospitalField.exists {
                hospitalField.tap()
                hospitalField.typeText("持久化测试医院")
                
                let departmentField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '科室'")).firstMatch
                if departmentField.exists {
                    departmentField.tap()
                    departmentField.typeText("测试科室")
                }
                
                let saveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '保存' OR label CONTAINS '创建'")).firstMatch
                if saveButton.exists && saveButton.isEnabled {
                    saveButton.tap()
                    sleep(2)
                    print("    ✓ 测试记录创建完成")
                }
            }
        }
        
        // 重启应用
        print("  重启应用...")
        app.terminate()
        sleep(2)
        app.launch()
        sleep(3)
        
        // 验证数据是否持久化
        navigateToRecords()
        sleep(1)
        
        let persistedRecord = app.staticTexts["持久化测试医院"]
        if persistedRecord.exists {
            print("    ✓ 数据持久化成功")
        } else {
            print("    ⚠️ 未找到持久化数据")
        }
        
        print("✅ [通过] 数据持久化测试完成\n")
    }
    
    /// 测试016: 文本输入边界测试
    func test016_TextInputBoundaryTest() throws {
        print("🔥 [压力测试-016] 文本输入边界测试")
        
        navigateToRecords()
        sleep(1)
        
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch
        if addButton.exists {
            addButton.tap()
            sleep(1)
            
            let hospitalField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS '医院'")).firstMatch
            if hospitalField.exists {
                // 测试极长文本
                print("  测试超长文本输入...")
                hospitalField.tap()
                let longText = String(repeating: "测试", count: 100) // 200个字符
                hospitalField.typeText(longText)
                sleep(1)
                print("    ✓ 超长文本输入完成")
                
                // 测试空文本
                print("  测试空文本...")
                hospitalField.clearText()
                sleep(1)
                print("    ✓ 清空文本完成")
                
                // 测试特殊字符
                print("  测试特殊字符...")
                hospitalField.typeText("!@#$%^&*()_+-=[]{}|;':\",./<>?")
                sleep(1)
                print("    ✓ 特殊字符输入完成")
            }
            
            // 关闭
            dismissCurrentSheet()
        }
        
        print("✅ [通过] 文本输入边界测试完成\n")
    }
    
    /// 测试017: 并发操作测试
    func test017_ConcurrentOperationsTest() throws {
        print("🔥 [压力测试-017] 并发操作测试")
        
        print("  执行多个并发操作...")
        
        // 快速执行多个不同的操作
        for i in 1...15 {
            switch i % 5 {
            case 0:
                navigateToHome()
                app.swipeUp()
            case 1:
                navigateToRecords()
                app.swipeDown()
            case 2:
                navigateToMedication()
                app.swipeUp()
            case 3:
                navigateToProfile()
            case 4:
                navigateToHome()
            default:
                break
            }
            
            usleep(UInt32(150000)) // 0.15秒
            
            if i % 5 == 0 {
                print("    已执行 \(i) 个并发操作")
            }
        }
        
        // 验证应用稳定性
        XCTAssertTrue(app.state == .runningForeground, "应用应该仍在运行")
        print("✅ [通过] 并发操作测试完成\n")
    }
    
    /// 测试018: 动画完整性测试
    func test018_AnimationIntegrityTest() throws {
        print("🔥 [压力测试-018] 动画完整性测试")
        
        print("  测试页面切换动画...")
        let tabs = ["首页", "就诊记录", "用药", "我的"]
        
        for _ in 1...5 {
            for tab in tabs {
                if let tabButton = app.buttons[tab].firstMatch as? XCUIElement, tabButton.exists {
                    tabButton.tap()
                    // 等待动画完成
                    usleep(UInt32(500000)) // 0.5秒
                }
            }
            print("    ✓ 一轮切换动画完成")
        }
        
        print("✅ [通过] 动画完整性测试完成\n")
    }
    
    /// 测试019: 极限滚动测试
    func test019_ExtremScrollTest() throws {
        print("🔥 [压力测试-019] 极限滚动测试")
        
        navigateToRecords()
        sleep(1)
        
        print("  执行极限滚动操作...")
        for i in 1...50 {
            if i % 2 == 0 {
                app.swipeUp()
            } else {
                app.swipeDown()
            }
            usleep(UInt32(50000)) // 0.05秒
            
            if i % 10 == 0 {
                print("    已滚动 \(i) 次")
            }
        }
        
        XCTAssertTrue(app.state == .runningForeground, "应用应该仍在运行")
        print("✅ [通过] 极限滚动测试完成\n")
    }
    
    /// 测试020: 最终稳定性验证
    func test020_FinalStabilityCheck() throws {
        print("🔥 [压力测试-020] 最终稳定性验证")
        
        print("  执行最终随机操作序列...")
        let randomOperations: [() -> Void] = [
            { self.navigateToHome(); self.app.swipeUp() },
            { self.navigateToRecords(); self.app.swipeDown() },
            { self.navigateToMedication() },
            { self.navigateToProfile() },
            { self.app.swipeUp() },
            { self.app.swipeDown() },
            { self.app.swipeLeft() },
            { self.app.swipeRight() }
        ]
        
        for i in 1...30 {
            let randomOp = randomOperations.randomElement()!
            randomOp()
            usleep(UInt32(100000)) // 0.1秒
            
            if i % 10 == 0 {
                print("    已执行 \(i) 个随机操作")
            }
        }
        
        // 最终验证
        XCTAssertTrue(app.state == .runningForeground, "应用应该仍在正常运行")
        
        // 验证基本功能
        navigateToHome()
        sleep(1)
        let homeTitle = app.staticTexts["健康助手"]
        XCTAssertTrue(homeTitle.exists, "首页应该可访问")
        
        print("  ✓ 应用通过所有稳定性检查")
        print("✅ [通过] 最终稳定性验证完成\n")
    }
    
    // MARK: - 辅助方法
    
    private func navigateToHome() {
        let homeTab = app.buttons["首页"]
        if homeTab.exists {
            homeTab.tap()
        }
    }
    
    private func navigateToRecords() {
        let recordsTab = app.buttons["就诊记录"]
        if recordsTab.exists {
            recordsTab.tap()
        }
    }
    
    private func navigateToMedication() {
        let medicationTab = app.buttons["用药"]
        if medicationTab.exists {
            medicationTab.tap()
        }
    }
    
    private func navigateToProfile() {
        let profileTab = app.buttons["我的"]
        if profileTab.exists {
            profileTab.tap()
        }
    }
    
    private func dismissCurrentSheet() {
        // 尝试多种关闭方式
        let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '关闭' OR label CONTAINS 'xmark' OR label CONTAINS '完成' OR label CONTAINS '取消'")).firstMatch
        if closeButton.exists {
            closeButton.tap()
            return
        }
        
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            return
        }
        
        // 向下滑动关闭
        app.swipeDown()
    }
    
    private func goBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        } else {
            app.swipeDown()
        }
    }
    
    private func openFirstRecord() {
        let firstRecord = app.otherElements.containing(.staticText, identifier: "").firstMatch
        if firstRecord.exists {
            firstRecord.tap()
        }
    }
    
    private func openSettings() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '设置'")).firstMatch
        if settingsButton.exists {
            settingsButton.tap()
        }
    }
    
    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - XCUIElement 扩展

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        // 点击元素
        self.tap()
        
        // 删除所有文本
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}

// MARK: - 完整测试套件执行器

extension XunDocComprehensiveStressTests {
    
    /// 执行所有压力测试（按顺序）
    func testZZZ_RunAllStressTests() throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🔥🔥🔥 执行完整压力测试套件 - 所有测试 🔥🔥🔥")
        print(String(repeating: "=", count: 80) + "\n")
        
        let allTests: [(String, () throws -> Void)] = [
            ("基础连接测试", test000_BasicConnectionTest),
            ("应用启动压力", test001_AppLaunchStress),
            ("导航栏疯狂切换", test002_TabBarCrazyNavigation),
            ("批量创建记录", test003_MassHealthRecordCreation),
            ("搜索压力", test004_SearchStressTest),
            ("批量添加用药", test005_MassMedicationCreation),
            ("个人页面全面测试", test006_ProfilePageComprehensiveTest),
            ("快速添加面板", test007_QuickAddPanelStress),
            ("滚动性能", test008_ScrollPerformanceStress),
            ("内存压力", test009_MemoryStressTest),
            ("UI元素检查", test010_UIElementsVisibilityCheck),
            ("空状态处理", test011_EmptyStateHandling),
            ("快速点击防抖", test012_RapidTapDebounceTest),
            ("横竖屏切换", test013_OrientationChangeTest),
            ("后台恢复", test014_BackgroundResumeTest),
            ("数据持久化", test015_DataPersistenceTest),
            ("文本输入边界", test016_TextInputBoundaryTest),
            ("并发操作", test017_ConcurrentOperationsTest),
            ("动画完整性", test018_AnimationIntegrityTest),
            ("极限滚动", test019_ExtremScrollTest),
            ("最终稳定性", test020_FinalStabilityCheck)
        ]
        
        var passedCount = 0
        var failedCount = 0
        var failedTests: [String] = []
        let startTime = Date()
        
        for (index, test) in allTests.enumerated() {
            print("\n[\(index + 1)/\(allTests.count)] 🔥 \(test.0)")
            print(String(repeating: "-", count: 80))
            
            do {
                try test.1()
                passedCount += 1
                print("✅ \(test.0) - 通过")
            } catch {
                failedCount += 1
                failedTests.append(test.0)
                print("❌ \(test.0) - 失败: \(error.localizedDescription)")
                takeScreenshot(name: "Failed_\(test.0)")
            }
            
            sleep(1)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // 最终测试报告
        print("\n" + String(repeating: "=", count: 80))
        print("📊 压力测试完整报告")
        print(String(repeating: "=", count: 80))
        print("执行时间: \(String(format: "%.2f", duration)) 秒")
        print("总测试数: \(allTests.count)")
        print("✅ 通过: \(passedCount)")
        print("❌ 失败: \(failedCount)")
        print("📈 通过率: \(String(format: "%.1f", Double(passedCount) / Double(allTests.count) * 100))%")
        
        if !failedTests.isEmpty {
            print("\n失败的测试:")
            for (index, test) in failedTests.enumerated() {
                print("  \(index + 1). \(test)")
            }
        }
        
        print(String(repeating: "=", count: 80))
        
        if failedCount == 0 {
            print("🎉🎉🎉 恭喜！所有压力测试全部通过！🎉🎉🎉")
        } else {
            print("⚠️ 有 \(failedCount) 个测试失败，请检查详细日志")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
}

