import SwiftUI

struct BankingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var opportunity: String?
    @State private var failed = false
    private let titles = ["orientation": "Review wallet basics", "survey": "Product interest survey", "delivery": "Check a demonstration dispatch"]
    var body: some View {
        PhoneShellView(title: "Banking", subtitle: "BANANA CREDITS") {
            if !appState.story.isWritable {
                AppErrorState(title: "Account unavailable", message: "The saved account needs recovery. Your account has not been reset.", retry: { _ = appState.story.load() })
            } else {
            AppScreenScroll {
                AppCard {
                    Text("Available balance").appText(.caption)
                    Text("\(appState.phoneLife.balance) BC").appText(.screenTitle).monospacedDigit()
                        .accessibilityIdentifier("bank.balance")
                    Text("Fictional credits • No real-money value").appText(.caption)
                }
                if appState.phoneLife.securityCompromised { DeviceSecurityCard() }
                DeviceCatalogueCopy(contentID: "content.device.mail.bank_welcome")
                AppSectionHeader("Opportunities")
                ForEach(PhoneLifeState.taskIDs, id: \.self) { task in
                    let done = appState.phoneLife.ledger.contains { $0.id == "credit.task." + task }
                    Button { opportunity = task } label: {
                        AppListRow(title: titles[task] ?? task, subtitle: done ? "Completed • 100 BC received" : "Optional • Earn 100 BC", symbol: done ? "checkmark.circle" : "briefcase")
                    }.buttonStyle(.appContent).disabled(done).accessibilityIdentifier("bank.task.\(task)")
                }
                AppSectionHeader("Activity")
                Text("Opening credit: +100 BC").appText(.body)
                ForEach(appState.phoneLife.ledger) { entry in
                    HStack {
                        Text(ledgerTitle(entry.id)).appText(.body).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text("\(entry.amount >= 0 ? "+" : "")\(entry.amount) BC").appText(.systemLabel)
                    }
                }
                HeadsetShopCard()
            }
            }
        }
        .sheet(item: Binding(get: { opportunity.map(DeviceOpportunity.init) }, set: { opportunity = $0?.id })) { item in
            PhoneShellView(title: titles[item.id] ?? "Opportunity") {
                AppScreenScroll {
                    DeviceCatalogueCopy(contentID: "content.device.web.task." + item.id)
                    if item.id == "survey" {
                        SurveyChoice()
                    }
                    Text("Complete once to receive 100 Banana Credits. Participation is optional and does not affect your investigation.").appText(.body)
                    Button("Complete opportunity • +100 BC") {
                        if case .failure = appState.story.earnDeviceCredits(task: item.id) { failed = true }
                        else { opportunity = nil }
                    }.buttonStyle(.appPrimary).accessibilityIdentifier("bank.task.complete")
                    Button("Cancel") { opportunity = nil }.buttonStyle(.modernPhone)
                }
            }
        }
        .alert("Account could not be updated", isPresented: $failed) { Button("OK", role: .cancel) {} }
    }
    private func ledgerTitle(_ id: String) -> String {
        switch id {
        case "credit.headset.purchase": return "Banana Vision reservation"
        case "credit.phishing.debit": return "Unrecognized prize-service debit"
        case "credit.phishing.recovery": return "Recovered disputed credits"
        default: return titles[String(id.dropFirst("credit.task.".count))] ?? "Account activity"
        }
    }

}
private struct DeviceOpportunity: Identifiable { let id: String }
private struct SurveyChoice: View {
    @State private var choice = "Creative space"
    var body: some View {
        Picker("Your interest", selection: $choice) {
            ForEach(["Creative space", "Workspace", "Entertainment"], id: \.self) { Text($0) }
        }.pickerStyle(.inline)
    }
}

struct HeadsetShopCard: View {
    @EnvironmentObject private var appState: AppState
    @State private var confirm = false
    @State private var failed = false
    var body: some View {
        AppCard {
            Image(asset: .vr001HeadsetHero).resizable().scaledToFit().accessibilityLabel("Banana Vision headset")
            Text("Banana Vision Store").appText(.sectionTitle)
            Text("300 Banana Credits • In-game reservation").appText(.body)
            if appState.story.isWritable { Text("Balance: \(appState.phoneLife.balance) BC").appText(.caption) }
            else { Text("Saved account unavailable").appText(.caption) }
            if appState.phoneLife.headsetPurchased {
                Label("Reservation confirmed", systemImage: "checkmark.seal").appText(.body)
                    .accessibilityIdentifier("shop.purchased")
            } else {
                Button("Reserve Banana Vision • 300 BC") { confirm = true }
                    .buttonStyle(.appPrimary).accessibilityIdentifier("shop.purchase")
                    .disabled(!appState.story.isWritable || appState.phoneLife.balance < PhoneLifeState.headsetPrice || appState.phoneLife.securityCompromised)
                if appState.phoneLife.securityCompromised { Text("Secure your account in Settings before purchasing.").appText(.caption) }
                else if appState.phoneLife.balance < PhoneLifeState.headsetPrice { Text("Open Banking for optional earning opportunities.").appText(.caption) }
            }
            Text("No real payment or physical delivery. Purchasing is optional.").appText(.caption)
        }
        .confirmationDialog("Reserve Banana Vision for 300 BC?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Confirm reservation") {
                if case .failure = appState.story.purchaseHeadset() { failed = true }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Your fictional balance will be reduced once. Your story access is unchanged.") }
        .alert("Reservation unavailable", isPresented: $failed) { Button("OK", role: .cancel) {} }
    }
}

struct DeviceSecurityCard: View {
    @EnvironmentObject private var appState: AppState
    @State private var confirm = false
    @State private var failed = false
    var body: some View {
        AppCard {
            Label(appState.phoneLife.securityCompromised ? "Unrecognized account session" : "Account protected",
                  systemImage: appState.phoneLife.securityCompromised ? "exclamationmark.shield" : "checkmark.shield").appText(.sectionTitle)
            Text(appState.phoneLife.securityCompromised ? "The prize service used your shared demonstration profile. Revoke its session to recover disputed credits." : "No unrecognized session is active on this fictional account.").appText(.body)
            if appState.phoneLife.securityCompromised {
                Button("Revoke prize-service access") { confirm = true }.buttonStyle(.appPrimary)
                    .accessibilityIdentifier("security.recover")
            }
        }
        .confirmationDialog("Secure this account?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Revoke and recover credits") {
                if case .failure = appState.story.recoverDeviceAccount() { failed = true }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Recovery could not be saved", isPresented: $failed) { Button("OK", role: .cancel) {} }
    }
}

struct DeviceCatalogueCopy: View {
    @EnvironmentObject private var appState: AppState
    let contentID: String
    var body: some View {
        if let item = appState.content.catalogue?.itemsByID[contentID],
           appState.content.availability(for: contentID).isAvailable,
           let version = appState.content.currentVersion(for: item.id) {
            StoryReadableContent(version: version)
        }
    }
}

struct DeviceLifeActions: View {
    let contentID: String
    var body: some View {
        if contentID == "content.device.web.store" { HeadsetShopCard() }
        if contentID == "content.device.web.security" { DeviceSecurityCard() }
        if contentID == "content.device.web.prize" { PrizeOfferCard() }
        if contentID == "content.device.web.home" || contentID == "content.device.web.company" {
            Image(asset: contentID == "content.device.web.home" ? .bc001PrimaryLogo : .photo001HQExterior)
                .resizable().scaledToFit().accessibilityLabel(contentID == "content.device.web.home" ? "Banana Corp corporate mark" : "Banana Corp headquarters")
        }
        if ["content.device.mail.prize", "content.device.mail.prize_reminder"].contains(contentID) {
            NavigationLink { PrizeOfferView() } label: {
                Label("Visit reward portal", systemImage: "gift").frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.modernPhone).accessibilityIdentifier("mail.prize.open")
        }
    }
}
private struct PrizeOfferView: View {
    var body: some View {
        PhoneShellView(title: "Vision Rewards", subtitle: "banana-prizes.example") {
            AppScreenScroll {
                DeviceCatalogueCopy(contentID: "content.device.web.prize")
                PrizeOfferCard()
            }
        }
    }
}
private struct PrizeOfferCard: View {
    @EnvironmentObject private var appState: AppState
    @State private var share = false
    @State private var failed = false
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Image(asset: .vr001HeadsetHero).resizable().scaledToFit().accessibilityLabel("Headset prize advertisement")
                AppCard {
                    Text("Device owner • BNC-DEMO").appText(.systemLabel)
                    Text("Demonstration account profile. No personal information is requested.").appText(.caption)
                }
                if appState.phoneLife.ledger.contains(where: { $0.id == "credit.phishing.debit" }) {
                    DeviceSecurityCard()
                    Text("The offer did not create a headset reservation. Check Banking for account activity.").appText(.body)
                } else {
                    Button("Share demonstration profile") { share = true }.buttonStyle(.appPrimary)
                        .accessibilityIdentifier("prize.share")
                }
        }
        .confirmationDialog("Share the on-phone profile?", isPresented: $share, titleVisibility: .visible) {
            Button("Share profile") { if case .failure = appState.story.submitFictionalPrizeProfile() { failed = true } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Recipient: Vision Rewards Desk. This affects only your fictional account. You can decline and keep investigating.") }
        .alert("Profile sharing could not be saved", isPresented: $failed) { Button("OK", role: .cancel) {} }
    }
}
