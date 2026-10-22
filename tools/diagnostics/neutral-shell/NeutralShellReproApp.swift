import SwiftUI

enum AppMotion {
    static let opening = Animation.easeOut(duration: 0.32)
    static let closing = Animation.easeInOut(duration: 0.28)
    static let reduced = Animation.easeOut(duration: 0.12)
    static let press = Animation.easeOut(duration: 0.12)
    static let selection = Animation.easeOut(duration: 0.18)
    static let reorder = Animation.snappy(duration: 0.20, extraBounce: 0)
    static let editWiggle = Animation.easeInOut(duration: 0.18)

    static func appTransition(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top)
        )
    }
}

struct AppPressFeedback: ViewModifier {
    let isPressed: Bool
    var scale: CGFloat = 0.98
    var pressedOpacity: Double = 0.92
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let pressed = isPressed && isEnabled
        content
            .scaleEffect(pressed && !reduceMotion ? scale : 1)
            .opacity(pressed ? pressedOpacity : 1)
            .animation(reduceMotion ? nil : AppMotion.press, value: pressed)
    }
}

/// For actionable cards/rows and icons; passive reading surfaces stay passive.
struct AppContentButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.99
    var pressedOpacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(AppPressFeedback(
            isPressed: configuration.isPressed,
            scale: scale,
            pressedOpacity: pressedOpacity
        ))
    }
}

extension ButtonStyle where Self == AppContentButtonStyle {
    static var appContent: AppContentButtonStyle { AppContentButtonStyle() }
    static var appIcon: AppContentButtonStyle { AppContentButtonStyle(scale: 0.96, pressedOpacity: 0.88) }
}


// Explicit neutral fixture: no Banana Corp story, assets, persistence or actual player data.
@main
struct NeutralShellReproApp: App {
    @StateObject private var state = NeutralOSState()
    var body: some Scene { WindowGroup { NeutralOS().environmentObject(state).preferredColorScheme(.dark) } }
}

@MainActor
final class NeutralOSState: ObservableObject {
    enum Phase: Equatable { case home, opening, active, closing }
    @Published private(set) var phase: Phase = .home
    @Published private(set) var route: Int?
    @Published private(set) var transitionID: UInt = 0
    @Published var editing = false
    func open(_ id: Int) {
        guard phase == .home, !editing else { return }
        route = id; phase = .opening; transitionID &+= 1
    }
    func home() {
        editing = false
        guard phase == .opening || phase == .active else { return }
        route = nil; phase = .closing; transitionID &+= 1
    }
    func complete(_ id: UInt) {
        guard id == transitionID else { return }
        if phase == .opening { phase = .active }
        else if phase == .closing { phase = .home }
    }
    func beginEditing() { if phase == .home { editing = true } }
}

struct NeutralOS: View {
    @EnvironmentObject private var state: NeutralOSState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presented: Int?
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            NeutralHome()
                .scaleEffect(reduceMotion || presented == nil ? 1 : 0.99)
                .opacity(presented == nil ? 1 : 0.95)
                .allowsHitTesting(state.phase == .home)
                .accessibilityHidden(state.phase != .home)
            if let route = presented {
                NavigationStack { NeutralApplication(route: route) }
                    .id(route)
                    .statusBarHidden(true)
                    .transition(AppMotion.appTransition(reduceMotion: reduceMotion))
                    .allowsHitTesting(state.phase == .active)
                    .zIndex(1)
            }
        }
        .clipped()
        .statusBarHidden(true)
        .onChange(of: state.transitionID) { _, id in
            let animation = reduceMotion ? AppMotion.reduced : (state.phase == .closing ? AppMotion.closing : AppMotion.opening)
            withAnimation(animation, completionCriteria: .removed) { presented = state.route }
                completion: { state.complete(id) }
        }
        .onAppear { presented = state.route; state.complete(state.transitionID) }
        .onDisappear { state.complete(state.transitionID) }
    }
}

struct NeutralClock: View {
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now = Date()
    var body: some View {
        HStack { Text("NEUTRAL FIXTURE"); Spacer(); Text(now, style: .time).monospacedDigit() }
            .font(.body.weight(.semibold))
            .frame(minHeight: 56)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .onReceive(timer) { _ in now = Date() }
    }
}

struct NeutralShell<Content: View>: View {
    let title: String?
    var homeStrip = true
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 8) {
                NeutralClock()
                if let title { Text(title).font(.title.bold()).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24).padding(.vertical, 8) }
                content().frame(maxWidth: .infinity, maxHeight: .infinity)
                if homeStrip { NeutralHomeStrip() }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .statusBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct NeutralHomeStrip: View {
    @EnvironmentObject private var state: NeutralOSState
    var body: some View {
        Button(action: state.home) {
            Capsule().fill(.white.opacity(0.85)).frame(width: 110, height: 5)
                .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.appContent)
        .highPriorityGesture(DragGesture(minimumDistance: 16).onEnded { value in
            let d = value.translation
            guard d.width.isFinite, d.height.isFinite, d.height < -24, abs(d.height) > abs(d.width) else { return }
            state.home()
        })
        .accessibilityLabel("Neutral Home")
        .accessibilityIdentifier("neutral.home")
    }
}

struct NeutralIcon: View {
    @EnvironmentObject private var state: NeutralOSState
    let id: Int
    let size: CGFloat
    var body: some View {
        Button { guard !state.editing else { return }; state.open(id) } label: {
            VStack(spacing: 7) {
                RoundedRectangle(cornerRadius: size * 0.25).fill(.purple.opacity(0.35))
                    .frame(width: size, height: size)
                    .overlay { Text("\(id)").font(.title2).accessibilityHidden(true) }
                Text("Item \(id)").font(.caption).frame(height: 32, alignment: .top)
            }.frame(maxWidth: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.appIcon)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.4).onEnded { _ in state.beginEditing() })
        .accessibilityLabel("Neutral item \(id)")
        .accessibilityIdentifier("neutral.app.\(id)")
    }
}

struct NeutralHome: View {
    @EnvironmentObject private var state: NeutralOSState
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    var body: some View {
        NeutralShell(title: nil, homeStrip: false) {
            GeometryReader { geometry in
                let width = min(geometry.size.width - 24, 440)
                let size = min(64, max(44, (width - 48) / 4))
                VStack(spacing: 12) {
                    HStack {
                        Text(state.editing ? "Neutral editing" : "Neutral launcher")
                        Spacer()
                        if state.editing { Button("Done") { state.editing = false } }
                    }.frame(height: 44)
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(0..<15) { NeutralIcon(id: $0, size: size) }
                        }.padding(.top, 4).padding(.bottom, 20)
                    }.scrollIndicators(.hidden)
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(15..<19) { NeutralIcon(id: $0, size: size) }
                    }.padding(12).background(.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 28)).padding(.bottom, 8)
                }.frame(width: width).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }.onDisappear { state.editing = false }
    }
}

struct NeutralApplication: View {
    let route: Int
    var body: some View {
        NeutralShell(title: "Neutral item \(route)") {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Neutral app \(route)").accessibilityIdentifier("neutral.destination.\(route)")
                    ForEach(0..<16) { Text("Neutral row \($0)").frame(maxWidth: .infinity, alignment: .leading).padding(20).background(.purple.opacity(0.2), in: RoundedRectangle(cornerRadius: 16)) }
                }.padding(24)
            }.scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively)
        }
    }
}
