import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var newNote = ""
    @State private var showColorPicker = false
    @State private var customAccentColor = Color(hex: "#3F2A6B")
    @State private var selectedPickerItem: PhotosPickerItem?
    @State private var selectedPhoto: JournalPhoto?
    @State private var showingResetAlert = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    dashboardSection
                    colorSection
                    notesSection
                    journalSection
                    settingsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "#F8F4EB").ignoresSafeArea())
            .navigationTitle("Profile")
            .alert("Reset all local data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { store.resetAllData() }
            } message: {
                Text("This clears habits, notes, photos, coach messages, and settings from this device.")
            }
            .onAppear { customAccentColor = store.accentColor }
            .fullScreenCover(item: $selectedPhoto) { photo in
                PhotoZoomView(url: store.photoURL(for: photo))
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 122, height: 122)

                Text("👤")
                    .font(.system(size: 62))
                    .foregroundStyle(store.accentColor)
            }

            Text("velvetfasion@gmail.com")
                .font(.headline)
            Text("Account created: 26/01/2026")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Empire Dashboard")
            HStack(spacing: 12) {
                statCard(value: "\(store.lifetimeFrequencyScore)", label: "Lifetime Frequency")
                statCard(value: "\(store.settings.currentStreak)", label: "Day Streak 🔥")
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showColorPicker.toggle() }
            } label: {
                Text("Change Empire Color")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(store.accentColor, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            if showColorPicker {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(store.accentPresets, id: \.self) { hex in
                            Button {
                                store.accentHex = hex
                                customAccentColor = Color(hex: hex)
                            } label: {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: hex))
                                    .frame(height: 50)
                                    .overlay {
                                        if store.accentHex.lowercased() == hex.lowercased() {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ColorPicker("Full Accent Picker", selection: $customAccentColor, supportsOpacity: false)
                        .onChange(of: customAccentColor) { newColor in
                            store.accentHex = UIColor(newColor).toHexString()
                        }
                }
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Notes to Self")

            HStack(alignment: .top, spacing: 12) {
                TextField("Write your affirmation or reflection...", text: $newNote, axis: .vertical)
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .lineLimit(3...8)

                Button {
                    store.addNote(newNote)
                    newNote = ""
                } label: {
                    Text("+")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(store.accentColor, in: Circle())
                }
                .buttonStyle(.plain)
            }

            ForEach(store.notes) { note in
                Text(note.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Journal Photos (full size)")

            PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                Text("Add full-size photo")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(store.accentColor, in: RoundedRectangle(cornerRadius: 16))
            }
            .onChange(of: selectedPickerItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        store.addPhotoData(data)
                    }
                    selectedPickerItem = nil
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(store.journalPhotos) { photo in
                    Button {
                        selectedPhoto = photo
                    } label: {
                        PhotoThumbnailView(url: store.photoURL(for: photo))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Settings")

            VStack(spacing: 12) {
                settingsPicker(
                    title: "Reminder frequency",
                    selection: $store.settings.reminderFrequency,
                    options: ReminderFrequency.allCases
                )
                settingsPicker(
                    title: "Notification style",
                    selection: $store.settings.notificationStyle,
                    options: NotificationStyle.allCases
                )
                settingsPicker(
                    title: "Export format",
                    selection: $store.settings.exportFormat,
                    options: ExportFormat.allCases
                )

                Stepper("Streak counter: \(store.settings.currentStreak) days", value: $store.settings.currentStreak, in: 0...999)
                    .font(.subheadline)

                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Text("Reset all local data")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func settingsPicker<T: Hashable & Identifiable & RawRepresentable>(
        title: String,
        selection: Binding<T>,
        options: [T]
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(title, selection: selection) {
                ForEach(options) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func sectionTitle(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(store.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(store.accentColor)
            Text(label)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct PhotoThumbnailView: View {
    let url: URL

    var body: some View {
        Group {
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.15))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct PhotoZoomView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    @State private var zoom: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoom)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                zoom = max(1, min(value, 4))
                            }
                    )
                    .onTapGesture {
                        dismiss()
                    }
            } else {
                Text("Image unavailable")
                    .foregroundStyle(.white)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .padding(20)
            }
            .buttonStyle(.plain)
        }
    }
}

private extension UIColor {
    func toHexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#3F2A6B"
        }
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppStore.preview)
}
