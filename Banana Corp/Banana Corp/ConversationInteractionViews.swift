import SwiftUI

/// One local conversation surface; saved entries remain owned by AppState's store.
struct DeviceConversationPanel: View {
    @EnvironmentObject private var appState: AppState
    let channel: String
    let title: String
    let responder: String
    let inputLabel: String
    var answer: ((String) -> String?)?
    var onAnswered: ((String?) -> Void)?
    @State private var draft = ""
    @State private var failure = false
    @FocusState private var isComposing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            AppSectionHeader(title)
            let entries = appState.conversationEntries(channel: channel)
            if entries.count > 6 {
                DisclosureGroup("Earlier messages (\(entries.count - 6))") {
                    ForEach(Array(entries.dropLast(6)), id: \.id) { entry in
                        conversationRow(entry)
                    }
                }
                .tint(AppTheme.Colors.text)
                .accessibilityIdentifier("device.chat.\(channel).history")
            }
            ForEach(Array(entries.suffix(6)), id: \.id) { entry in
                conversationRow(entry)
            }
            HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
                TextField(inputLabel, text: $draft,
                          prompt: Text(inputLabel).foregroundStyle(AppTheme.Colors.text),
                          axis: .vertical)
                    .lineLimit(1...5)
                    .appText(.body)
                    .padding(AppTheme.Spacing.md)
                    .frame(minHeight: AppTheme.Layout.touchTarget)
                    .background(AppTheme.Colors.surface, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                    .focused($isComposing)
                    .submitLabel(.send)
                    .onSubmit(send)
                    .accessibilityLabel(inputLabel)
                    .accessibilityIdentifier("device.chat.\(channel).input")
                    .onChange(of: draft) { _, value in
                        if value.utf8.count > 512 {
                            var bounded = value
                            while bounded.utf8.count > 512 { bounded.removeLast() }
                            draft = bounded
                        }
                    }
                Button(action: send) {
                    Label("Send", systemImage: "arrow.up.circle.fill")
                        .frame(minHeight: AppTheme.Layout.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.modernPhone)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !appState.story.isWritable)
                .accessibilityIdentifier("device.chat.\(channel).send")
            }
        }
        .alert("Message could not be saved", isPresented: $failure) { Button("OK", role: .cancel) {} }
            message: { Text("Your message remains in the composer. Existing progress has not been reset.") }
    }

    private func conversationRow(_ entry: DeviceConversationEntry) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(entry.isPlayer ? "You" : responder).appText(.systemLabel)
                Text(entry.text).appText(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(entry.isPlayer ? .leading : .trailing, AppTheme.Spacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("device.chat.\(channel).entry.\(entry.id)")
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let answerID = answer?(text)
        switch appState.sendDeviceMessage(channel: channel, text: text, answerID: answerID) {
        case .success:
            draft = ""
            isComposing = false
            onAnswered?(answerID)
        case .failure: failure = true
        }
    }
}
