import Adwaita
import ChatGPTSwift

struct ChatListView: WindowView, @unchecked Sendable {

    var window: AdwaitaWindow
    var app: AdwaitaApp!

    @State private var width = 650
    @State private var height = 550
    @State private var maximized = false
    @State("gptModel") private var selectedModel = ChatGPTModel.gpt_hyphen_4o_hyphen_mini.rawValue
    @State("systemPrompt") private var systemPrompt = "You're a helpful assistant"
    let models = ChatGPTModel.allCases
    @State("temperature") private var temperature: Double = 0.5

    @State private var chatState = ChatListState()
    @State private var showAbout = false
    @State private var showPreferences = false
    @State("apiKey") private var apiKey =
        ""
    nonisolated(unsafe) static var chatListScrollView: ChatListScrollView?

    static let chatGPTAPI = ChatGPTAPI(
        apiKey: "")

    var view: Body {
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
                                    .padding(16, .vertical)
                            }

                            if message.state == .error {
                                Button("Retry") {
                                    self.retry(message: message)
                                }
                                .style("suggested-action")
                                .insensitive(chatState.isPrompting)
                                .frame(maxWidth: 100)
                                .padding(16, .horizontal)
                                .padding(16, .vertical)
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
                        Button(icon: Icon.default(icon: .preferencesSystem)) {
                            showPreferences = true
                        }
                        .padding(8, .trailing)
                        .insensitive(chatState.isPrompting)

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

            HeaderBar.end {
                Menu(icon: .default(icon: .openMenu)) {
                    MenuSection {
                        MenuButton("Preferences") { showPreferences = true }
                            .keyboardShortcut("comma".ctrl())
                        MenuButton("About") { showAbout = true }

                        MenuButton("Quit", window: false) { app.quit() }
                            .keyboardShortcut("q".ctrl())
                    }
                }
                .primary()
                .tooltip("Main Menu")

            }
            .headerBarTitle {
                WindowTitle(subtitle: "GPT Model - \(selectedModel)", title: "XCA AI Chat")

            }

        }
        .onAppear {
            Self.chatGPTAPI.updateAPIKey(apiKey)
        }
        .aboutDialog(
            visible: $showAbout,
            app: "XCA AI Chat",
            developer: "Alfian Losari - Xcoding with Alfian",
            version: "0.1.0",
            icon: .custom(name: "io.github.alfianlosari.GTKChatGPT"),
            website: .init(string: "https://github.com/alfianlosari/GTKChatGPT"),
            issues: .init(string: "https://github.com/alfianlosari/GTKChatGPT/issues")
        )
        .alertDialog(
            visible: $showPreferences, heading: "Settings", body: "Bring your own OpenAI API Key"
        ) {

            ScrollView {
                VStack {
                    FormSection("API") {
                        Form {
                            EntryRow("API Key", text: $apiKey)
                                .secure(text: $apiKey)
                            LinkButton(uri: "https://platform.openai.com")

                        }

                    }
                    .padding()

                    FormSection("Configuration") {
                        Form {
                            ComboRow("ChatGPT Model", selection: $selectedModel, values: models)
                            EntryRow("System Prompt", text: $systemPrompt)
                            SpinRow(
                                "Temperature", value: $temperature,
                                min: 0.0, max: 1.0
                            )
                            .step(0.1)
                            .digits(1)
                            .subtitle("Response Creativity")

                        }
                    }
                    .padding()
                }
            }
            .frame(minWidth: 512, minHeight: 210)
            .frame(maxWidth: 768)
            .frame(maxHeight: 512)
        }
        .response("Close", appearance: .suggested, role: .close) {
            Self.chatGPTAPI.updateAPIKey(apiKey)
        }
    }

    func sendMessage(text: String) {
        self.chatState.messages.append(
            .init(sender: "M E", text: text, role: .user, state: .idle))
        self.chatState.messages.append(
            .init(sender: "A I", text: "", role: .assistant, state: .loading))
        self.chatState.isPrompting = true
        self.scrollToBottom()

        self.chatState.task = Task {
            do {
                let stream = try await Self.chatGPTAPI.sendMessageStream(
                    text: text,
                    model: ChatGPTModel(rawValue: selectedModel) ?? .gpt_hyphen_4o,
                    systemText: systemPrompt,
                    temperature: temperature
                )

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
                        if !message.text.isEmpty {
                            message.text += "\n\n"
                        }

                        if error is CancellationError {
                            message.text += "Cancelled"
                        } else {
                            message.text += "Error:\n\(error.localizedDescription)"
                            message.text +=
                                "\n\nSomething went wrong. Please check your API key, model access, or try again later."
                        }
                        message.state = .error
                        self.chatState.messages[self.chatState.messages.count - 1] = message
                        self.chatState.task = nil
                        self.chatState.isPrompting = false
                        self.scrollToBottom()
                    }
                }
            }
        }
    }

    func retry(message: Message) {
        guard let index = self.chatState.messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        let promptMessage = self.chatState.messages[index - 1]
        self.chatState.messages.remove(at: index)
        self.chatState.messages.remove(at: index - 1)
        Idle(delay: Duration.seconds(0.1)) {
            self.sendMessage(text: promptMessage.text)
            return false
        }
    }

    func scrollToBottom() {
        Self.chatListScrollView?.scrollToBottom()
    }

    func window(_ window: Core.Window) -> Core.Window {
        window
            .size(width: $width, height: $height)
            .maximized($maximized)
            .resizable(true)
            .closeShortcut()
            .title("XCA AI Chat")
    }

}
