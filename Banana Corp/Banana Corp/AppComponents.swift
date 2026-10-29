import SwiftUI

// Reading surfaces stay opaque. Glass is reserved for small navigation/action controls.
struct AppCard<Content: View>: View {
    var padding: CGFloat = AppTheme.Spacing.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.Colors.surface,
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
            )
    }
}

struct AppScreenHeader: View {
    @Environment(\.osPresentation) private var presentation
    @Environment(\.osAppRoute) private var appRoute
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            OSStoryText(
                text: title,
                target: appRoute.map { .screenTitle($0) },
                displayNameOverride: appRoute.flatMap { presentation.resolved(at: Date()).apps[$0]?.displayName }
            )
            .appText(.screenTitle)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).appText(.caption, color: AppTheme.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

struct AppSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .appText(.sectionTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct AppScreenScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg, content: content)
                .frame(maxWidth: AppTheme.Layout.readingWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct AppEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var symbolSize: CGFloat = 40

    var body: some View {
        AppCard {
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: symbol)
                    .font(.system(size: symbolSize, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
                    .frame(minHeight: max(64, symbolSize + 16))
                    .accessibilityHidden(true)
                Text(title).appText(.sectionTitle)
                Text(message).appText(.body)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
        }
    }
}

struct AppLoadingState: View {
    let message: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ProgressView().tint(AppTheme.Colors.accent)
            Text(message).appText(.body)
        }
        .padding(AppTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}

struct AppErrorState: View {
    let title: String
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AppEmptyState(symbol: "exclamationmark.circle", title: title, message: message)
            if let retry {
                Button("Try again", action: retry).buttonStyle(.appPrimary)
            }
        }
    }
}

struct AppNotificationBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : String(count))
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.Colors.text)
                .padding(.horizontal, 6)
                .frame(minWidth: 20, minHeight: 20)
                .background(AppTheme.Colors.highlight, in: Capsule())
                .accessibilityLabel("\(count) unread notifications")
        }
    }
}

/// A passive row by default; its caller supplies navigation only when content exists.
struct AppListRow: View {
    let title: String
    var subtitle: String?
    var detail: String?
    var metadata: String?
    var symbol: String?
    var isUnread = false
    var badgeCount = 0

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).appText(.body).fontWeight(isUnread ? .semibold : .regular)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if let metadata {
                        Text(metadata).appText(.caption, color: AppTheme.Colors.secondaryText)
                    }
                }
                if let subtitle { Text(subtitle).appText(.systemLabel) }
                if let detail { Text(detail).appText(.body, color: AppTheme.Colors.secondaryText) }
            }
            if isUnread {
                Circle().fill(AppTheme.Colors.accent).frame(width: 7, height: 7).padding(.top, 8)
                    .accessibilityLabel("Unread")
            }
            AppNotificationBadge(count: badgeCount)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .frame(minHeight: AppTheme.Layout.touchTarget)
        .accessibilityElement(children: .combine)
    }
}

struct AppCardButton<Content: View>: View {
    let label: String
    let action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Button(action: action) {
            AppCard(content: content)
        }
        .buttonStyle(.appContent)
        .accessibilityLabel(label)
    }
}

struct AppListButton: View {
    let row: AppListRow
    let action: () -> Void

    var body: some View {
        Button(action: action) { row }
            .buttonStyle(.appContent)
    }
}

struct AppTextInput: View {
    let label: String
    @Binding var text: String
    var symbol: String?
    var axis: Axis = .horizontal
    var keyboard: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            if let symbol {
                Image(systemName: symbol).foregroundStyle(AppTheme.Colors.secondaryText).accessibilityHidden(true)
            }
            TextField(label, text: $text, prompt: Text(label).foregroundColor(AppTheme.Colors.secondaryText), axis: axis)
                .appText(.body)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .submitLabel(submitLabel)
                .lineLimit(1...4)
                .accessibilityLabel(label)
        }
        .padding(AppTheme.Spacing.md)
        .frame(minHeight: AppTheme.Layout.touchTarget)
        .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.Colors.separator, lineWidth: 1))
        .opacity(isEnabled ? 1 : 0.65)
    }
}

struct AppSearchField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        // The placeholder and query must be able to wrap at accessibility text sizes.
        AppTextInput(label: label, text: $text, symbol: "magnifyingglass", axis: .vertical, submitLabel: .search)
    }
}

/// Nil actions explicitly represent unavailable controls, rather than no-op buttons.
struct AppNavigationControl: View {
    let label: String
    let symbol: String
    var action: (() -> Void)?

    var body: some View {
        Button { action?() } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(minWidth: AppTheme.Layout.touchTarget, minHeight: AppTheme.Layout.touchTarget)
        }
        .buttonStyle(.modernPhone)
        .disabled(action == nil)
        .accessibilityLabel(label)
    }
}

struct AppFloatingAction: View {
    let title: String
    let symbol: String
    var action: (() -> Void)?

    var body: some View {
        Button { action?() } label: {
            Label(title, systemImage: symbol)
        }
        .buttonStyle(.modernPhoneProminent)
        .disabled(action == nil)
    }
}

struct AppBottomActionArea<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: AppTheme.Layout.readingWidth)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.background)
            .overlay(alignment: .top) {
                Rectangle().fill(AppTheme.Colors.separator).frame(height: 1)
            }
    }
}

struct AppMessageComposer: View {
    let prompt: String
    let unavailableReason: String
    @Binding var text: String
    var onSend: (() -> Void)?

    var body: some View {
        AppBottomActionArea {
            HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
                AppTextInput(label: prompt, text: $text, axis: .vertical, submitLabel: .send)
                    .disabled(onSend == nil)
                    .accessibilityHint(onSend == nil ? unavailableReason : "")
                    .onSubmit { sendIfReady() }
                AppNavigationControl(
                    label: "Send",
                    symbol: "arrow.up",
                    action: canSend ? onSend : nil
                )
            }
        }
    }

    private var canSend: Bool {
        onSend != nil && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendIfReady() { if canSend { onSend?() } }
}

struct AppSegmentedControl: View {
    let label: String
    let options: [String]
    @Binding var selection: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(options, id: \.self) { Text($0).tag($0) }
        }
        .pickerStyle(.segmented)
        .tint(AppTheme.Colors.accent)
        .frame(minHeight: AppTheme.Layout.touchTarget)
        .animation(reduceMotion ? nil : AppMotion.selection, value: selection)
    }
}

struct AppToggleRow: View {
    let title: String
    var detail: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title).appText(.body)
                if let detail { Text(detail).appText(.caption, color: AppTheme.Colors.secondaryText) }
            }
        }
        .tint(AppTheme.Colors.accent)
        .frame(minHeight: AppTheme.Layout.touchTarget)
    }
}

struct AppMediaGrid<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12, content: content)
    }
}

struct AppScorePanel: View {
    let label: String
    let value: String
    var color: Color = AppTheme.Colors.text

    var body: some View {
        AppCard(padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(label).appText(.caption, color: AppTheme.Colors.secondaryText)
                Text(value).appText(.sectionTitle, color: color).monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct AppGameOverlay: View {
    let title: String
    var message: String?
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        AppCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Text(title).appText(.sectionTitle)
                if let message {
                    Text(message).appText(.body, color: AppTheme.Colors.secondaryText)
                }
                Button(actionTitle, action: action).buttonStyle(.appPrimary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: 320)
        .padding(AppTheme.Spacing.lg)
    }
}

/// Native presentations retain platform accessibility and keyboard/dismissal behavior.
extension View {
    func appAlert(title: String, message: String, isPresented: Binding<Bool>) -> some View {
        alert(title, isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message)
        }
    }

    func appConfirmation(
        title: String,
        message: String,
        actionTitle: String,
        isPresented: Binding<Bool>,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        modifier(AppConfirmationModifier(
            title: title,
            message: message,
            actionTitle: actionTitle,
            isPresented: isPresented,
            role: role,
            action: action
        ))
    }
}

#if DEBUG
// An interactive component catalogue, isolated from app routes and ARG data.
private struct AppComponentsPreview: View {
    @State private var query = ""
    @State private var draft = ""
    @State private var selected = "First"
    @State private var toggled = false
    @State private var showsAlert = false
    @State private var showsConfirmation = false

    var body: some View {
        PhoneShellView(title: "Component preview", showsHomeIndicator: false) {
            VStack(spacing: 0) {
                AppScreenScroll {
                    AppSearchField(label: "Preview search", text: $query)
                    AppSectionHeader("Inputs")
                    AppCard {
                        VStack(spacing: AppTheme.Spacing.md) {
                            AppToggleRow(title: "Preview toggle", detail: "Preview only", isOn: $toggled)
                            AppSegmentedControl(label: "Preview options", options: ["First", "Second"], selection: $selected)
                        }
                    }
                    AppSectionHeader("Interactive surfaces")
                    AppCardButton(label: "Preview card", action: { showsAlert = true }) {
                        Text("Preview card").appText(.body)
                    }
                    AppListButton(
                        row: AppListRow(title: "Preview interactive row", symbol: "square"),
                        action: { showsAlert = true }
                    )
                    AppSectionHeader("Rows and states")
                    AppCard {
                        AppListRow(
                            title: "Preview row",
                            subtitle: "Preview subtitle",
                            detail: "Preview detail",
                            metadata: "Preview time",
                            symbol: "envelope",
                            isUnread: true,
                            badgeCount: 120
                        )
                    }
                    AppLoadingState(message: "Preview loading state")
                    AppErrorState(title: "Preview error state", message: "Preview only")
                    AppSectionHeader("Media layout")
                    AppMediaGrid {
                        ForEach(0..<4) { _ in
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                        }
                    }
                    ViewThatFits {
                        HStack {
                            Button("Preview alert") { showsAlert = true }.buttonStyle(.appPrimary)
                            Button("Preview dialog") { showsConfirmation = true }.buttonStyle(.modernPhone)
                        }
                        VStack {
                            Button("Preview alert") { showsAlert = true }.buttonStyle(.appPrimary)
                            Button("Preview dialog") { showsConfirmation = true }.buttonStyle(.modernPhone)
                        }
                    }
                    AppFloatingAction(title: "Preview action", symbol: "plus", action: { showsAlert = true })
                }
                AppMessageComposer(
                    prompt: "Preview message",
                    unavailableReason: "",
                    text: $draft,
                    onSend: { draft = "" }
                )
            }
        }
        .appAlert(title: "Preview alert", message: "Preview only", isPresented: $showsAlert)
        .appConfirmation(
            title: "Preview confirmation",
            message: "Clear the preview fields?",
            actionTitle: "Clear",
            isPresented: $showsConfirmation,
            action: { query = ""; draft = "" }
        )
        .preferredColorScheme(.dark)
    }
}

#Preview("Shared components") {
    AppComponentsPreview()
}

#Preview("Shared components, large text") {
    AppComponentsPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif


/// App-local controls never open external URLs or change story/read state.
struct BrowserChrome: View {
    @Binding var address: String
    var homeLabel = "Browser Home"
    var onBack: (() -> Void)?
    let onHome: () -> Void
    let onRefresh: () -> Void
    let onGo: () -> Void
    var notice: String?
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "globe").foregroundStyle(AppTheme.Colors.accent).accessibilityHidden(true)
                TextField("Address or search local pages", text: $address, axis: .vertical)
                    .lineLimit(1...4)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .submitLabel(.go).onSubmit(onGo)
                    .accessibilityIdentifier("browser.address")
                    .accessibilityLabel("Address or search local pages")
                Button(action: onGo) {
                    Image(systemName: "arrow.right").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.appContent).accessibilityLabel("Go").accessibilityIdentifier("browser.go")
            }
            .padding(.leading, 12)
            .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.Colors.separator))
            HStack {
                chromeButton("Back", symbol: "chevron.left", id: onBack == nil ? "browser.back" : "story.back", action: onBack)
                Spacer()
                chromeButton(homeLabel, symbol: "house", id: "browser.home", action: onHome)
                Spacer()
                OSStoryText(text: "Browser", target: .screenTitle(.browser)).appText(.caption, color: AppTheme.Colors.secondaryText)
                Spacer()
                chromeButton("Refresh", symbol: "arrow.clockwise", id: "browser.refresh", action: onRefresh)
            }
            if let notice { Text(notice).appText(.caption, color: AppTheme.Colors.secondaryText).fixedSize(horizontal: false, vertical: true) }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(AppTheme.Colors.background)
    }
    private func chromeButton(_ label: String, symbol: String, id: String, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Image(systemName: symbol).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(.appContent).disabled(action == nil)
            .accessibilityLabel(label).accessibilityIdentifier(id)
    }
}

struct MailChrome: View {
    let title: String
    var inboxLabel = "Inbox"
    var onBack: (() -> Void)?
    let onInbox: () -> Void
    let onRefresh: () -> Void
    var notice: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button { onBack?() } label: {
                    Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.disabled(onBack == nil).accessibilityLabel("Back")
                    .accessibilityIdentifier(onBack == nil ? "mail.back" : "story.back")
                OSStoryText(text: title, target: .screenTitle(.email)).appText(.screenTitle).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Button(action: onInbox) {
                    Image(systemName: "tray").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.accessibilityLabel(inboxLabel).accessibilityIdentifier("mail.inbox")
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.accessibilityLabel("Refresh mail").accessibilityIdentifier("mail.refresh")
            }.buttonStyle(.appContent)
            if let notice { Text(notice).appText(.caption, color: AppTheme.Colors.secondaryText).fixedSize(horizontal: false, vertical: true) }
        }.padding(.horizontal, 8).padding(.vertical, 4)
    }
}

struct MailSourceRow: View {
    let version: StoryContentVersion
    let unread: Bool
    let timestamp: String?
    private var sender: String {
        if case .email(let payload) = version.payload { return payload.sender }
        return version.source ?? "Email"
    }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.Colors.accent.opacity(0.18))
                Text(String(sender.prefix(1))).appText(.sectionTitle)
            }.frame(width: 40, height: 40).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(sender).appText(.systemLabel).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    if unread { Circle().fill(AppTheme.Colors.highlight).frame(width: 7, height: 7).accessibilityLabel("Unread") }
                }
                Text(version.title).appText(.sectionTitle).fixedSize(horizontal: false, vertical: true)
                if let subtitle = version.subtitle { Text(subtitle).appText(.caption).fixedSize(horizontal: false, vertical: true) }
                if let timestamp { Text(timestamp).appText(.caption, color: AppTheme.Colors.secondaryText) }
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.Colors.secondaryText).accessibilityHidden(true)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
    }
}
