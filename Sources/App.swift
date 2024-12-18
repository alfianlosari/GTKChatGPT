import Adwaita
import ChatGPTSwift
import Foundation

@main struct AdwaitaTemplate: App, @unchecked Sendable {

    var app = AdwaitaApp(id: "com.alfianlosari.xca-gtk-chatgpt")

    @State var chatState = ChatListState()
    nonisolated(unsafe) static var chatListScrollView: ChatListScrollView?

    static let chatGPTAPI = ChatGPTAPI(
        apiKey:
            "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"
    )

    var scene: Scene {
        Window(id: "content") { _ in
            VStack {
                ChatListScrollView { _ in
                    ForEach(chatState.messages) { message in
                        HStack {
                            Avatar(showInitials: true, size: 20)
                                .text(message.sender)
                                .padding(16, .leading)
                                .padding(16, .vertical)
                                .valign(.start)

                            VStack {
                                Text(message.text)
                                    .xalign(0)
                                    .wrap()
                                    .selectable()
                                    .padding(16, .horizontal)
                                    .padding(16, .vertical)
                                    .hexpand()
                                    .valign(.start)

                                if message.state == .loading {
                                    Spinner()
                                        .padding(8, .vertical)
                                }

                                if message.state == .error {
                                    Button("Retry") {
                                        self.retry(message: message)
                                    }
                                    .insensitive(chatState.isPrompting)
                                    .frame(maxWidth: 100)
                                    .padding(16, .horizontal)
                                    .padding(8, .vertical)
                                    .halign(.start)
                                }
                            }

                        }
                        .padding(8)
                        .style("card")
                    }
                }
                .modify { scrollView in
                    Self.chatListScrollView = scrollView
                }
                .kineticScrolling()
                .propagateNaturalHeight()
                .vexpand()

                HStack {
                    EntryRow("Enter message to send", text: $chatState.text)
                        .entryActivated {
                            let text = self.chatState.text
                            guard !text.isEmpty else { return }
                            self.chatState.text = ""
                            self.sendMessage(text: text)
                        }
                        .hexpand()
                        .insensitive(chatState.isPrompting)
                        .padding(8, .trailing)

                    if chatState.task != nil {
                        Button("Cancel") {
                            self.chatState.task?.cancel()
                            self.chatState.task = nil
                        }
                        .style("destructive-action")
                    } else {
                        HStack {
                            Button("Clear") {
                                self.chatState.messages.removeAll()
                                self.chatState.messages.append(
                                    .init(
                                        sender: "A I", text: "Hello there! how may i assist you?",
                                        role: .assistant, state: .idle))
                            }
                            .style("destructive-action")
                            .padding(8, .trailing)
                            .insensitive(chatState.isPrompting)

                            Button("Send") {

                                let text = self.chatState.text
                                guard !text.isEmpty else { return }
                                self.chatState.text = ""
                                self.sendMessage(text: text)
                            }
                            .style("suggested-action")
                            .insensitive(chatState.isPrompting)
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: 768)
            .topToolbar {
                HeaderBar.empty()
            }
        }
        .resizable(true)
        .closeShortcut()
        .defaultSize(width: 400, height: 250)
        .title("XCA GTK ChatGPT ")
    }

    func sendMessage(text: String) {
        self.chatState.messages.append(
            .init(sender: "A L", text: text, role: .user, state: .idle))
        self.chatState.messages.append(
            .init(sender: "A I", text: "", role: .assistant, state: .loading))
        self.chatState.isPrompting = true
        self.scrollToBottom()

        self.chatState.task = Task {
            do {
                let stream = try await Self.chatGPTAPI.sendMessageStream(text: text)
                var responseText = ""
                for try await text in stream {
                    try Task.checkCancellation()
                    Idle {
                        responseText += text
                        if var message = self.chatState.messages.last {
                            message.text = responseText
                            self.chatState.messages[self.chatState.messages.count - 1] = message
                            self.scrollToBottom()
                        }
                    }
                }
                try Task.checkCancellation()
                Idle {
                    if var message = self.chatState.messages.last {
                        message.text = responseText
                        message.state = .idle
                        self.chatState.messages[self.chatState.messages.count - 1] = message
                        self.chatState.task = nil
                        self.chatState.isPrompting = false
                        self.scrollToBottom()
                        Self.chatGPTAPI.appendToHistoryList(
                            userText: text, responseText: responseText)
                    }
                }
            } catch {
                if var message = self.chatState.messages.last {
                    Idle {
                        if error is CancellationError {
                            message.text += "\n\nCancelled"
                        } else {
                            message.text += "\n\nError:\n\(error.localizedDescription)"
                        }
                        message.state = .error
                        self.chatState.messages[self.chatState.messages.count - 1] = message
                        self.chatState.task = nil
                        self.chatState.isPrompting = false
                        self.scrollToBottom()
                    }
                }
                print(error.localizedDescription)
            }
        }
    }

    func retry(message: Message) {
        guard let index = self.chatState.messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        Idle {
            let promptMessage = self.chatState.messages[index - 1]
            self.chatState.messages.remove(at: index)
            self.chatState.messages.remove(at: index - 1)
            self.sendMessage(text: promptMessage.text)
        }
    }

    func scrollToBottom() {
        Self.chatListScrollView?.scrollToBottom()
    }
}
