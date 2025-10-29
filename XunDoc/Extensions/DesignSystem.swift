//
//  DesignSystem.swift
//  XunDoc
//
//  统一设计系统 - 颜色、字体、阴影等
//  设计理念：温暖现代主义 - 大地色调与流体动画的结合
//

import SwiftUI

// MARK: - 颜色系统 - 独特的大地色调配色
extension Color {
    // 主题色 - 温暖的大地色系
    static let warmTerracotta = Color(red: 214/255, green: 93/255, blue: 74/255)      // 赤陶橙
    static let deepOlive = Color(red: 106/255, green: 115/255, blue: 74/255)          // 深橄榄绿
    static let goldenSand = Color(red: 219/255, green: 172/255, blue: 107/255)        // 金沙色
    static let richEarth = Color(red: 139/255, green: 94/255, blue: 60/255)           // 泥土棕
    static let dustyRose = Color(red: 194/255, green: 123/255, blue: 128/255)         // 灰玫瑰
    static let sageMist = Color(red: 148/255, green: 162/255, blue: 141/255)          // 雾鼠尾草
    
    // 功能主色调 - 用赤陶橙作为主要强调色
    static let accentPrimary = warmTerracotta
    static let accentSecondary = deepOlive
    static let accentTertiary = goldenSand
    
    // 背景色 - 温暖的渐变背景
    static var appBackgroundColor: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 26/255, green: 24/255, blue: 22/255, alpha: 1.0) // 深咖啡色
            } else {
                return UIColor(red: 249/255, green: 246/255, blue: 240/255, alpha: 1.0) // 温暖的米白色
            }
        })
    }
    
    static var cardBackgroundColor: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 38/255, green: 35/255, blue: 32/255, alpha: 1.0) // 深暖灰
            } else {
                return UIColor(red: 255/255, green: 254/255, blue: 251/255, alpha: 1.0) // 柔和白色
            }
        })
    }
    
    static var secondaryBackgroundColor: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 48/255, green: 44/255, blue: 40/255, alpha: 1.0) // 中暖灰
            } else {
                return UIColor(red: 242/255, green: 237/255, blue: 227/255, alpha: 1.0) // 浅沙色
            }
        })
    }
    
    // 文本色 - 温暖的文本色调
    static var textPrimary: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 245/255, green: 240/255, blue: 230/255, alpha: 1.0) // 温暖的浅米色
            } else {
                return UIColor(red: 52/255, green: 45/255, blue: 36/255, alpha: 1.0) // 深褐色
            }
        })
    }
    
    static var textSecondary: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 180/255, green: 165/255, blue: 145/255, alpha: 1.0) // 暖灰
            } else {
                return UIColor(red: 120/255, green: 105/255, blue: 88/255, alpha: 1.0) // 中褐色
            }
        })
    }
    
    static var textTertiary: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 140/255, green: 130/255, blue: 115/255, alpha: 1.0)
            } else {
                return UIColor(red: 160/255, green: 145/255, blue: 125/255, alpha: 1.0)
            }
        })
    }
    
    // 分隔线 - 温暖色调
    static var dividerColor: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 70/255, green: 65/255, blue: 58/255, alpha: 1.0)
            } else {
                return UIColor(red: 228/255, green: 220/255, blue: 205/255, alpha: 1.0) // 浅沙色分隔线
            }
        })
    }
    
    // 状态色 - 大地色系的状态颜色
    static let successColor = Color(red: 106/255, green: 153/255, blue: 78/255)    // 深绿
    static let warningColor = Color(red: 218/255, green: 165/255, blue: 32/255)    // 金色
    static let errorColor = Color(red: 204/255, green: 85/255, blue: 68/255)       // 砖红
    static let infoColor = Color(red: 100/255, green: 130/255, blue: 145/255)      // 蓝灰
}

// MARK: - 阴影样式 - 温暖色调的阴影
struct CardShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: colorScheme == .dark 
                    ? Color.black.opacity(0.5) 
                    : Color(red: 139/255, green: 94/255, blue: 60/255).opacity(0.08), // 泥土棕的阴影
                radius: colorScheme == .dark ? 14 : 10,
                x: 0,
                y: colorScheme == .dark ? 6 : 3
            )
    }
}

struct FloatingShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: colorScheme == .dark 
                    ? Color.black.opacity(0.7) 
                    : Color(red: 139/255, green: 94/255, blue: 60/255).opacity(0.15),
                radius: colorScheme == .dark ? 20 : 16,
                x: 0,
                y: colorScheme == .dark ? 10 : 6
            )
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(CardShadow())
    }
    
    func floatingShadow() -> some View {
        modifier(FloatingShadow())
    }
}

// MARK: - 字体系统 - 独特的排版层次
// 使用 SF Rounded 创造温暖友好的感觉，配合优雅的衬线字体 New York 作为标题
extension Font {
    // 主标题 - 使用 New York 衬线字体，更专业优雅
    static func appTitle() -> Font {
        .system(size: 32, weight: .bold, design: .serif)
    }
    
    // 大标题 - 用于特殊强调
    static func appLargeTitle() -> Font {
        .system(size: 38, weight: .heavy, design: .serif)
    }
    
    // 小节标题 - 使用圆润字体
    static func appHeadline() -> Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }
    
    // 副标题
    static func appSubheadline() -> Font {
        .system(size: 17, weight: .medium, design: .rounded)
    }
    
    // 正文 - 易读的圆润字体
    static func appBody() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }
    
    // 说明文字
    static func appCaption() -> Font {
        .system(size: 14, weight: .regular, design: .rounded)
    }
    
    // 小字
    static func appSmall() -> Font {
        .system(size: 12, weight: .medium, design: .rounded)
    }
    
    // 数字显示 - 使用等宽字体
    static func appLargeNumber() -> Font {
        .system(size: 42, weight: .bold, design: .rounded)
            .monospacedDigit()
    }
    
    // 标签文字 - 全大写小字
    static func appLabel() -> Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }
}

// MARK: - 统一卡片样式 - 有机流体形状
struct ModernCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24 // 更大的圆角
    
    @Environment(\.colorScheme) var colorScheme
    
    init(padding: CGFloat = 20, cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cardBackgroundColor)
            )
            .cardShadow()
    }
}

// MARK: - 统一按钮样式
struct PrimaryButton: ButtonStyle {
    var color: Color = .accentPrimary
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appSubheadline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? color : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct SecondaryButton: ButtonStyle {
    var color: Color = .accentPrimary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appSubheadline())
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 图标背景
struct IconBackground: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    init(icon: String, color: Color, size: CGFloat = 48) {
        self.icon = icon
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.45))
                .foregroundColor(color)
        }
    }
}

// MARK: - 统一Header
struct ModernNavigationBar<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing
    
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            leading
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appTitle())
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.appCaption())
                        .foregroundColor(.accentPrimary)
                }
            }
            
            Spacer()
            
            trailing
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.appBackgroundColor)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(.accentPrimary.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.appHeadline())
                    .foregroundColor(.textPrimary)
                
                Text(message)
                    .font(.appBody())
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButton(color: .accentPrimary))
                .frame(width: 200)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackgroundColor)
    }
}

// MARK: - 加载视图
struct LoadingView: View {
    var message: String = "加载中..."
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.appBody())
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackgroundColor.opacity(0.9))
    }
}

// MARK: - 标签样式
struct TagView: View {
    let text: String
    let color: Color
    var isOutline: Bool = false
    
    var body: some View {
        Text(text)
            .font(.appSmall())
            .foregroundColor(isOutline ? color : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isOutline ? Color.clear : color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: isOutline ? 1 : 0)
                    )
            )
    }
}

// MARK: - 分隔线
struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.dividerColor)
            .frame(height: 0.5)
    }
}

// MARK: - 圆角特定角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 渐变背景 - 温暖的有机渐变
struct GradientBackground: View {
    let colors: [Color]
    var startPoint: UnitPoint = .topLeading
    var endPoint: UnitPoint = .bottomTrailing
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        .ignoresSafeArea()
    }
}

// MARK: - 温暖大地色渐变背景
struct WarmEarthGradient: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 26/255, green: 24/255, blue: 22/255),
                        Color(red: 32/255, green: 28/255, blue: 24/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // 浅色模式：柔和的大地色渐变
                LinearGradient(
                    colors: [
                        Color(red: 252/255, green: 248/255, blue: 242/255),
                        Color(red: 247/255, green: 242/255, blue: 232/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 流体动画按钮
struct FluidButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    init(title: String, icon: String? = nil, color: Color = .accentPrimary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.appSubheadline())
                }
                Text(title)
                    .font(.appSubheadline())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(color)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - 脉冲动画圆点（用于活跃状态指示）
struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.8 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - 波纹加载指示器
struct RippleLoadingIndicator: View {
    @State private var isAnimating = false
    let color: Color
    
    init(color: Color = .accentPrimary) {
        self.color = color
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 3)
                    .scaleEffect(isAnimating ? 1.2 : 0.5)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.3),
                        value: isAnimating
                    )
            }
        }
        .frame(width: 50, height: 50)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 有机形状卡片（不规则圆角）
struct OrganicCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .cardBackgroundColor
    
    init(backgroundColor: Color = .cardBackgroundColor, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(backgroundColor)
            )
            .cardShadow()
    }
}

// MARK: - 玻璃态效果（毛玻璃背景）
struct GlassCard<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.05)
                          : Color.white.opacity(0.7))
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(24)
            .cardShadow()
    }
}

// MARK: - 渐入动画修饰符
struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

extension View {
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
}

// MARK: - 滑入动画修饰符
struct SlideInModifier: ViewModifier {
    let delay: Double
    let edge: Edge
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: edge == .leading ? -offset : (edge == .trailing ? offset : 0),
                   y: edge == .top ? -offset : (edge == .bottom ? offset : 0))
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

extension View {
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInModifier(delay: delay, edge: edge))
    }
}

// MARK: - 科技网格背景
struct TechGridBackground: View {
    @Environment(\.colorScheme) var colorScheme
    let gridSize: CGFloat = 40
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // 垂直线
                let columns = Int(geometry.size.width / gridSize)
                for i in 0...columns {
                    let x = CGFloat(i) * gridSize
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // 水平线
                let rows = Int(geometry.size.height / gridSize)
                for i in 0...rows {
                    let y = CGFloat(i) * gridSize
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(
                colorScheme == .dark 
                    ? Color.warmTerracotta.opacity(0.06) 
                    : Color.gray.opacity(0.08),
                lineWidth: 0.5
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - 扫描线效果
struct ScanLineEffect: View {
    @State private var offset: CGFloat = -400
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark 
                            ? [Color.clear, Color.warmTerracotta.opacity(0.3), Color.clear]
                            : [Color.clear, Color.warmTerracotta.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 100)
                .blur(radius: 20)
                .offset(y: offset)
                .onAppear {
                    withAnimation(
                        .linear(duration: 3)
                        .repeatForever(autoreverses: false)
                    ) {
                        offset = geometry.size.height + 400
                    }
                }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - 霓虹脉冲边框
struct NeonBorderModifier: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: colorScheme == .dark 
                                ? [color, color.opacity(0.3), color]
                                : [color.opacity(0.5), color.opacity(0.2), color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .opacity(isAnimating ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: 1)
                    .blur(radius: 8)
                    .opacity(colorScheme == .dark ? (isAnimating ? 0.6 : 0.3) : 0)
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func neonBorder(color: Color = .warmTerracotta, cornerRadius: CGFloat = 16) -> some View {
        modifier(NeonBorderModifier(color: color, cornerRadius: cornerRadius))
    }
}

// MARK: - 粒子闪烁效果
struct ParticleField: View {
    @State private var particles: [Particle] = []
    @Environment(\.colorScheme) var colorScheme
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var size: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.warmTerracotta)
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                startAnimation()
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                opacity: Double.random(in: 0.2...0.6),
                size: CGFloat.random(in: 1...3)
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                withAnimation(.easeInOut(duration: Double.random(in: 0.5...2.0))) {
                    particles[i].opacity = Double.random(in: 0.1...0.7)
                }
            }
        }
    }
}

// MARK: - 数据流动效果
struct DataStreamEffect: View {
    @State private var offset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    let color: Color
    
    init(color: Color = .warmTerracotta) {
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                ForEach(0..<20) { index in
                    HStack(spacing: 2) {
                        ForEach(0..<Int(geometry.size.width / 8)) { _ in
                            Rectangle()
                                .fill(color.opacity(Double.random(in: 0.05...0.2)))
                                .frame(width: 6, height: 2)
                        }
                    }
                    .offset(x: offset)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 15)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = -geometry.size.width
                }
            }
        }
        .allowsHitTesting(false)
        .opacity(colorScheme == .dark ? 0.3 : 0.1)
        .ignoresSafeArea()
    }
}

// MARK: - 键盘管理扩展
extension View {
    /// 点击视图时隐藏键盘
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
    
    /// 隐藏键盘
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - 键盘消失手势
struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    /// 为视图添加点击隐藏键盘的功能
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

