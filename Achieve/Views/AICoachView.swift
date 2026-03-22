import SwiftUI

struct AICoachView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedMode: CoachMode = .motivation
    @State private var input = ""
    @State private var isSending = false

    private var modeMessages: [ChatMessage] {
        store.messages(for: selectedMode)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("AI Coach")
                .font(.custom("AvenirNext-Bold", size: 34))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)

            Picker("Mode", selection: $selectedMode) {
                ForEach(CoachMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(modeMessages) { message in
                            bubble(for: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: modeMessages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            HStack(spacing: 10) {
                TextField("Ask anything...", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit(send)

                Button(action: send) {
                    Image(systemName: isSending ? "hourglass" : "arrow.up")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(store.accentColor, in: Circle())
                }
                .disabled(isSending)
            }
            .padding()
        }
        .padding(.bottom, 110)
        .background(Color(.systemGroupedBackground))
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .assistant {
                textBubble(message.text, isUser: false)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                textBubble(message.text, isUser: true)
            }
        }
    }

    private func textBubble(_ text: String, isUser: Bool) -> some View {
        Text(text)
            .padding(12)
            .foregroundStyle(isUser ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isUser ? store.accentColor : Color(.secondarySystemBackground))
            )
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
    }

    private func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        input = ""
        isSending = true

        Task {
            await store.sendCoachMessage(trimmed, mode: selectedMode)
            await MainActor.run {
                isSending = false
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = modeMessages.last else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

#Preview {
    NavigationStack {
        AICoachView()
            .environmentObject(AppStore.preview)
    }
}
