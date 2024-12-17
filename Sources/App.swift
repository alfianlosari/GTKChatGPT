import Adwaita
import ChatGPTSwift
import Foundation
import Logging
import Observation
import WSClient

@main struct AdwaitaTemplate: App, @unchecked Sendable {

    var app = AdwaitaApp(id: "io.github.AparokshaUI.Demo")

    @State var chatGPTAPI = ChatGPTAPI(
        apiKey:
            "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"
    )
    @State var text = ""
    @State var messages: [Message] = [
        .init(
            sender: "A I", text: "Hello there! how may i assist you?",
            role: .assistant, state: .idle)
    ]
    @State var task: Task<Void, Never>?
    @State var isPrompting = false

    var scene: Scene {
        Window(id: "content") { _ in
            VStack {
                ScrollView {
                    ForEach(messages) { message in
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
                                }

                                if message.state == .error {
                                    Button("Retry") {
                                        self.retry(message: message)
                                    }
                                    .insensitive(isPrompting)
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
                .kineticScrolling()
                .vexpand()

                HStack {
                    EntryRow("Enter message to send", text: $text)
                        .onSubmit {
                            let text = self.text
                            guard !text.isEmpty else { return }
                            self.text = ""
                            self.sendMessage(text: text)
                        }
                        .hexpand()
                        .insensitive(isPrompting)
                        .padding(8, .trailing)

                    if task != nil {
                        Button("Cancel") {
                            self.task?.cancel()
                            self.task = nil
                        }
                        .style("destructive-action")
                    } else {
                        HStack {
                            Button("Clear") {
                                self.messages.removeAll()
                                self.messages.append(
                                    .init(
                                        sender: "A I", text: "Hello there! how may i assist you?",
                                        role: .assistant, state: .idle))
                            }
                            .style("destructive-action")
                            .padding(8, .trailing)
                            .insensitive(isPrompting)

                            Button("Send") {
                                let text = self.text
                                guard !text.isEmpty else { return }
                                self.text = ""
                                self.sendMessage(text: text)
                            }
                            .style("suggested-action")
                            .insensitive(isPrompting)
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
        self.task = Task {
            do {
                Idle {
                    self.messages.append(
                        .init(sender: "A L", text: text, role: .user, state: .idle))
                    self.messages.append(
                        .init(sender: "A I", text: "", role: .assistant, state: .loading))
                    self.isPrompting = true
                }

                let stream = try await self.chatGPTAPI.sendMessageStream(text: text)
                var responseText = ""
                for try await text in stream {
                    try Task.checkCancellation()
                    Idle {
                        responseText += text
                        if var message = self.messages.last {
                            message.text = responseText
                            self.messages[self.messages.count - 1] = message
                        }
                    }
                }
                try Task.checkCancellation()
                Idle {
                    if var message = self.messages.last {
                        message.text = responseText
                        message.state = .idle
                        self.messages[self.messages.count - 1] = message
                        self.task = nil
                        self.isPrompting = false
                        self.chatGPTAPI.appendToHistoryList(
                            userText: text, responseText: responseText)

                    }

                }

            } catch {
                if var message = self.messages.last {
                    Idle {
                        if error is CancellationError {
                            message.text += "\n\nCancelled"
                        } else {
                            message.text += "\n\nError:\n\(error.localizedDescription)"
                        }
                        message.state = .error
                        self.messages[self.messages.count - 1] = message
                        self.task = nil
                        self.isPrompting = false
                    }
                }
                print(error.localizedDescription)
            }
        }
    }

    func retry(message: Message) {
        guard let index = self.messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        Idle {
            let promptMessage = self.messages[index - 1]
            self.messages.remove(at: index)
            self.messages.remove(at: index - 1)
            self.sendMessage(text: promptMessage.text)
        }
    }

}

// Task {

//     do {
//         try await WebSocketClient.connect(
//             url: "wss://ws.coincap.io/prices?assets=bitcoin,ethereum,dogecoin",
//             logger: Logger(label: "xca.cryptotracker")
//         ) { inbound, outbound, context in
//             // you can convert the inbound stream of frames into a stream of full messages using `messages(maxSize:)`

//             for try await frame in inbound.messages(maxSize: 8_388_608) {
//                 print(frame)
//             }
//         }
//     } catch {
//         print("\(error)")
//     }
// }

// RunLoop.main.run(until: .distantFuture)
