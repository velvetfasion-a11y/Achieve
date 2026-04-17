import AuthenticationServices
import SwiftUI

struct UserProfilePage: View {
    @EnvironmentObject private var store: AppStore

    @State private var showingAddNote = false
    @State private var expandedNote: Note?
    @State private var showingResetAlert = false
    @State private var showingEmailSignIn = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @State private var noteToDelete: Note?

    var body: some View {
        ZStack {
            Color(hex: "#0D0D0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    profileHeaderSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.5).delay(0.05), value: appeared)

                    loginSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.5).delay(0.1), value: appeared)

                    statsSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.5).delay(0.15), value: appeared)

                    notesSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.5).delay(0.2), value: appeared)

                    dangerSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(duration: 0.5).delay(0.25), value: appeared)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .sheet(isPresented: $showingAddNote) {
            AddNoteSheet { text in store.addNote(text) }
        }
        .sheet(item: $expandedNote) { note in
            NoteDetailSheet(note: note) {
                store.deleteNote(note)
                expandedNote = nil
            }
        }
        .sheet(isPresented: $showingEmailSignIn) {
            ProfileEmailSignInSheet { name, email in
                store.signInWithEmail(displayName: name, email: email)
            }
        }
        .alert("Delete all data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { store.resetAllData() }
        } message: {
            Text("Removes habits, notes, events and journal from this device.")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Profile Header

    private var profileHeaderSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#C9A84C").opacity(0.15))
                    .frame(width: 68, height: 68)
                Circle()
                    .stroke(Color(hex: "#C9A84C").opacity(0.4), lineWidth: 1)
                    .frame(width: 68, height: 68)
                Text(avatarInitial)
                    .font(.title.bold())
                    .foregroundStyle(Color(hex: "#C9A84C"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(store.profileName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(store.loginStateText)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#888888"))
                if let email = store.userSession?.email {
                    Text(email)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#666666"))
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#2A2A2A"), lineWidth: 0.5)
        )
    }

    private var avatarInitial: String {
        String(store.profileName.prefix(1).uppercased())
    }

    // MARK: - Login Section

    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("ACCOUNT")

            if store.isLoggedIn {
                loggedInView
            } else {
                loggedOutView
            }
        }
    }

    private var loggedInView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color(hex: "#C9A84C"))
                Text("Synced across your devices")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#CCCCCC"))
                Spacer()
            }
            .padding(14)
            .background(Color(hex: "#C9A84C").opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#C9A84C").opacity(0.25), lineWidth: 0.5))

            PressScaleButton(disabled: false) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.signOut()
            } label: {
                Text("Sign Out")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(hex: "#FF6B6B"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#FF6B6B").opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#FF6B6B").opacity(0.3), lineWidth: 0.5))
            }
        }
    }

    private var loggedOutView: some View {
        VStack(spacing: 10) {
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color(hex: "#3A3A3A"), lineWidth: 0.5)
            )

            PressScaleButton(disabled: false) {
                store.signInWithGoogle(displayName: "Google User")
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color(hex: "#C9A84C"))
                    Text("Continue with Google")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "#2A2A2A"), lineWidth: 0.5))
            }

            PressScaleButton(disabled: false) {
                showingEmailSignIn = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.body)
                        .foregroundStyle(Color(hex: "#888888"))
                    Text("Continue with Email")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#AAAAAA"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#161616"), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "#252525"), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("OVERVIEW")
            HStack(spacing: 12) {
                statCard(value: "\(store.lifetimeFrequencyScore)%", label: "Lifetime Score", symbol: "chart.bar.fill")
                statCard(value: "\(store.streakCount)", label: "Day Streak", symbol: "flame.fill")
                statCard(value: "\(store.calendarEvents.count)", label: "Events", symbol: "calendar")
            }
        }
    }

    private func statCard(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(Color(hex: "#C9A84C").opacity(0.7))
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color(hex: "#C9A84C"))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color(hex: "#888888"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#2A2A2A"), lineWidth: 0.5)
        )
    }

    // MARK: - Notes Sticker Grid

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("NOTES")
                Spacer()
                PressScaleButton(disabled: false) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "#0D0D0D"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#C9A84C"), in: Circle())
                }
            }

            if store.notes.isEmpty {
                emptyNotesPlaceholder
            } else {
                notesGrid
            }
        }
    }

    private var emptyNotesPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "note.text")
                .font(.title2)
                .foregroundStyle(Color(hex: "#333333"))
            Text("Tap + to add your first note")
                .font(.caption)
                .foregroundStyle(Color(hex: "#555555"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(hex: "#141414"), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#222222"), lineWidth: 0.5))
    }

    private var notesGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(store.notes) { note in
                StickyNoteCard(note: note) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    expandedNote = note
                } onDelete: {
                    withAnimation(.spring(duration: 0.3)) {
                        store.deleteNote(note)
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("DATA")
            PressScaleButton(disabled: false) {
                showingResetAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#FF6B6B"))
                    Text("Reset all data")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#FF6B6B"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#555555"))
                }
                .padding(14)
                .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#FF6B6B").opacity(0.2), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color(hex: "#888888"))
            .kerning(1.5)
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple sign in failed."
                return
            }
            let formatter = PersonNameComponentsFormatter()
            let fullName = cred.fullName.flatMap { formatter.string(from: $0) }
            let name = fullName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? fullName!.trimmingCharacters(in: .whitespacesAndNewlines)
                : "Apple User"
            store.signInWithApple(displayName: name, email: cred.email)
        case .failure:
            errorMessage = "Apple sign in failed."
        }
    }
}

// MARK: - Sticky Note Card

private struct StickyNoteCard: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false
    @State private var showDeleteConfirm = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(note.text)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white)
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                HStack {
                    Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#666666"))
                    Spacer()
                    if note.text.count > 120 {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hex: "#C9A84C").opacity(0.6))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "#2A2A2A"), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Note Detail Sheet

private struct NoteDetailSheet: View {
    let note: Note
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D0D").ignoresSafeArea()
                ScrollView {
                    Text(note.text)
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#C9A84C"))
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color(hex: "#FF6B6B"))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Add Note Sheet

private struct AddNoteSheet: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D0D").ignoresSafeArea()
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundStyle(.white)
                    .tint(Color(hex: "#C9A84C"))
                    .font(.body)
                    .padding(16)
                    .focused($focused)
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#888888"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onAdd(trimmed)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "#C9A84C"))
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Email Sign In Sheet (profile version)

private struct ProfileEmailSignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    let onSignIn: (String, String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D0D").ignoresSafeArea()
                VStack(spacing: 16) {
                    inputField(placeholder: "Display name", text: $name)
                    inputField(placeholder: "Email address", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Email Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#888888"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sign In") {
                        onSignIn(
                            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Email User" : name,
                            email.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "#C9A84C"))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func inputField(placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Color(hex: "#555555")))
            .foregroundStyle(.white)
            .tint(Color(hex: "#C9A84C"))
            .padding(14)
            .background(Color(hex: "#1C1C1C"), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2A2A2A"), lineWidth: 0.5))
    }
}

#Preview {
    UserProfilePage()
        .environmentObject(AppStore.preview)
}
