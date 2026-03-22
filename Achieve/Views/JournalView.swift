import SwiftUI
import UIKit

struct JournalView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedPhoto: JournalPhoto?
    @State private var pendingImage: UIImage?
    @State private var pendingComment = ""
    @State private var showingCamera = false
    @State private var noteText = ""
    @State private var errorText: String?

    private var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Journal")
                    .font(.custom("AvenirNext-Bold", size: 34))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)

                noteSection
                photoComposer
                photoGallery
            }
            .padding()
            .padding(.bottom, 120)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView(image: $pendingImage, isPresented: $showingCamera)
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoZoomSheet(photo: photo)
                .environmentObject(store)
        }
        .alert(
            "Camera",
            isPresented: Binding(
                get: { errorText != nil },
                set: { active in
                    if !active { errorText = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) { errorText = nil }
        } message: {
            Text(errorText ?? "")
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes to Self")
                .font(.headline)

            HStack(alignment: .top, spacing: 10) {
                TextEditor(text: $noteText)
                    .frame(minHeight: 90)
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))

                Button {
                    store.addNote(noteText)
                    noteText = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(store.accentColor, in: Circle())
                }
            }

            ForEach(store.notes) { note in
                Text(note.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var photoComposer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("📷 Add Photos")
                    .font(.headline)
                Spacer()
                Button {
                    openCamera()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(store.accentColor, in: Circle())
                }
            }

            if let image = pendingImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 260)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                TextField("Add comment", text: $pendingComment)
                    .textFieldStyle(.roundedBorder)

                Button("Save") {
                    savePendingPhoto()
                }
                .buttonStyle(.borderedProminent)
                .tint(store.accentColor)
            }
        }
    }

    private var photoGallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gallery")
                .font(.headline)

            if store.photos.isEmpty {
                Text("No photos yet. Tap + to capture your first one.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(store.photos) { photo in
                        Button {
                            selectedPhoto = photo
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                if let image = store.image(for: photo) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 180)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 180)
                                        .overlay(Text("Unavailable"))
                                }

                                if !photo.comment.isEmpty {
                                    Text(photo.comment)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                            .background(.background, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorText = "Camera is unavailable on this device."
            return
        }
        showingCamera = true
    }

    private func savePendingPhoto() {
        guard let image = pendingImage, let jpegData = image.jpegData(compressionQuality: 0.9) else { return }
        do {
            try store.addPhoto(data: jpegData, comment: pendingComment.trimmingCharacters(in: .whitespacesAndNewlines))
            pendingImage = nil
            pendingComment = ""
        } catch {
            errorText = "Could not save this photo."
        }
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
        JournalView()
            .environmentObject(AppStore.preview)
    }
}
