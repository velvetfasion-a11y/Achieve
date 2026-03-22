import AuthenticationServices
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    @State private var isExporting = false
    @State private var exportDocument = ExportJSONDocument(data: Data())
    @State private var exportFileName = "achieve-export.json"
    @State private var showingResetAlert = false
    @State private var showingEmailSignIn = false
    @State private var googleDisplayName = "Google User"
    @State private var errorMessage: String?

    private let presetColors = ["#3F2A6B", "#E8B923", "#C84B6F", "#10B981", "#1E3A8A"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                profileHeader
                accountSection
                colorSection
                settingsSection
                exportSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFileName
        ) { _ in }
        .alert(
            "Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { presenting in
                    if !presenting { errorMessage = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Delete all data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                store.resetAllData()
            }
        } message: {
            Text("This removes habits, notes, chat, and saved photos from this device.")
        }
        .sheet(isPresented: $showingEmailSignIn) {
            EmailSignInSheet { name, email in
                store.signInWithEmail(displayName: name, email: email)
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)
                Text("🙂")
                    .font(.system(size: 42))
            }
            Text(store.profileName)
                .font(.title3.bold())
            Text(store.loginStateText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var accountSection: some View {
        VStack(spacing: 6) {
            if store.isLoggedIn {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account synced across your devices when iCloud is available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let email = store.userSession?.email {
                        Label(email, systemImage: "envelope")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("Sign Out", role: .destructive) {
                        store.signOut()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sign in to sync habits and journal data.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)

                    Button {
                        store.signInWithGoogle(displayName: googleDisplayName)
                    } label: {
                        Label("Continue with Google", systemImage: "g.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.accentColor)

                    Button {
                        showingEmailSignIn = true
                    } label: {
                        Label("Continue with Email", systemImage: "envelope")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Empire Color")
                .font(.title3.weight(.bold))

            HStack {
                ForEach(presetColors, id: \.self) { hex in
                    Button {
                        store.accentHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(store.accentHex == hex ? Color.primary : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            ColorPicker("Custom Accent", selection: Binding(
                get: { store.accentColor },
                set: { color in
                    let uiColor = UIColor(color)
                    store.accentHex = uiColor.toHexString() ?? "#3F2A6B"
                }
            ))
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                metricCard(value: "\(store.lifetimeFrequencyScore)%", label: "Lifetime")
                metricCard(value: "\(store.streakCount)", label: "Streak")
            }

            NavigationLink {
                SettingsView()
                    .environmentObject(store)
            } label: {
                HStack {
                    Text("Open Settings")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func metricCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(store.accentColor)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("Export My Data") {
                exportData()
            }
            .buttonStyle(.borderedProminent)
            .tint(store.accentColor)

            Button("Sign out / delete local data", role: .destructive) {
                showingResetAlert = true
            }
            .buttonStyle(.bordered)
        }
    }

    private func exportData() {
        do {
            exportDocument = ExportJSONDocument(data: try store.exportData())
            exportFileName = "achieve-export-\(Date.now.formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).json"
            isExporting = true
        } catch {
            errorMessage = "Could not prepare export: \(error.localizedDescription)"
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple sign in failed."
                return
            }

            let formatter = PersonNameComponentsFormatter()
            let fullName = credential.fullName.flatMap { formatter.string(from: $0) }
            let displayName = fullName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? fullName!.trimmingCharacters(in: .whitespacesAndNewlines)
                : "Apple User"

            store.signInWithApple(displayName: displayName, email: credential.email)
        case .failure:
            errorMessage = "Apple sign in failed."
        }
    }
}

private struct EmailSignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    let onSignIn: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Email Sign In") {
                    TextField("Display name", text: $name)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Email")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign In") {
                        onSignIn(
                            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Email User" : name,
                            email.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppStore.preview)
    }
}
