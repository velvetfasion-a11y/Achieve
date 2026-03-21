import PhotosUI
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    @State private var noteText = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhoto: JournalPhoto?
    @State private var isExporting = false
    @State private var exportDocument = ExportJSONDocument(data: Data())
    @State private var exportFileName = "achieve-export.json"
    @State private var showingResetAlert = false
    @State private var errorMessage: String?

    private let presetColors = ["#3F2A6B", "#E8B923", "#C84B6F", "#10B981", "#1E3A8A"]
    private let accountCreated = "26/01/2026"

    private var twoColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                profileHeader
                dashboard
                colorSection
                notesSection
                photosSection
                settingsSection
                leaderboardSection
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
        .onChange(of: selectedItems) { _ in
            Task { await importSelectedPhotos() }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoZoomSheet(photo: photo)
                .environmentObject(store)
        }
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
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)
                Image(systemName: "person.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(store.accentColor)
            }
            Text("velvetfasion@gmail.com")
                .font(.headline)
            Text("Account created: \(accountCreated)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var dashboard: some View {
        HStack(spacing: 14) {
            dashboardCard(value: "\(store.lifetimeFrequencyScore)", title: "Lifetime Frequency")
            dashboardCard(value: "\(store.streakCount)", title: "Day Streak")
        }
    }

    private func dashboardCard(value: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(store.accentColor)
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes to Self")
                .font(.title3.weight(.bold))

            HStack(alignment: .top, spacing: 10) {
                TextEditor(text: $noteText)
                    .frame(minHeight: 86)
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    addNote()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(store.accentColor, in: Circle())
                }
            }

            Button("Generate empire affirmation") {
                store.addNote(store.generatedAffirmation())
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(store.accentColor)

            ForEach(store.notes) { note in
                VStack(alignment: .leading, spacing: 6) {
                    Text(note.text)
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Journal Photos")
                .font(.title3.weight(.bold))

            PhotosPicker(selection: $selectedItems, maxSelectionCount: 8, matching: .images) {
                Label("Add full-size photos", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(store.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if store.photos.isEmpty {
                Text("No journal photos yet.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: twoColumns, spacing: 10) {
                    ForEach(store.photos) { photo in
                        Button {
                            selectedPhoto = photo
                        } label: {
                            Group {
                                if let image = store.image(for: photo) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                        .overlay(Text("Unavailable"))
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 180)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Anonymous Leaderboard")
                .font(.title3.weight(.bold))

            ForEach(Array(store.leaderboard.enumerated()), id: \.element.id) { index, entry in
                HStack {
                    Text("#\(index + 1)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(store.accentColor)
                    Text(entry.alias)
                    Spacer()
                    Text("\(entry.score)")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
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

    private func addNote() {
        store.addNote(noteText)
        noteText = ""
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

    private func importSelectedPhotos() async {
        guard !selectedItems.isEmpty else { return }

        for item in selectedItems {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    try store.addPhoto(data: data)
                }
            } catch {
                errorMessage = "Could not import a selected photo."
            }
        }
        selectedItems = []
    }
}

private struct PhotoZoomSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let photo: JournalPhoto

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let image = store.image(for: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                Text("Photo unavailable")
                    .foregroundStyle(.white)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding()
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
