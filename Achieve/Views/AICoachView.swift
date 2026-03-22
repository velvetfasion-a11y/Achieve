import SwiftUI

struct AICoachView: View {
    @EnvironmentObject private var store: AppStore
    @State private var input = ""
    @State private var isReplying = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Mode", selection: $store.selectedCoachMode) {
                    ForEach(CoachMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(store.coachMessages) { message in
                                HStack {
                                    if message.isUser { Spacer() }
                                    Text(message.text)
                                        .foregroundStyle(message.isUser ? .white : .primary)
                                        .padding(12)
                                        .background(message.isUser ? store.accentColor : Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
                                    if !message.isUser { Spacer() }
                                }
                                .id(message.id)
                            }

                            if isReplying {
                                HStack {
                                    ProgressView()
                                        .padding(12)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                    .onChange(of: store.coachMessages.count) { _ in
                        if let last = store.coachMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    TextField("Ask anything...", text: $input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .submitLabel(.send)
                        .onSubmit(sendMessage)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(store.accentColor, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
            .navigationTitle("AI Coach")
            .background(Color(hex: "#F8F4EB").ignoresSafeArea())
        }
    }

    private func sendMessage() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let mode = store.selectedCoachMode
        store.addUserMessage(input, mode: mode)
        input = ""
        isReplying = true

        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            store.addCoachReply(for: mode)
            isReplying = false
        }
    }
}

#Preview {
    AICoachView()
        .environmentObject(AppStore.preview)
}
