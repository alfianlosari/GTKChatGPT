import Foundation

struct ChatListState {

    var text = ""
    var messages: [Message] = [
        .init(
            sender: "A I", text: "Hello there! how may i assist you?",
            role: .assistant, state: .idle)
    ]
    var task: Task<Void, Never>?
    var isPrompting = false

}

enum MessageState {
    case loading, error, idle
}

enum MessageRole {
    case assistant, user
}

struct Message: Identifiable {
    let id = UUID()
    let sender: String
    var text: String
    var role: MessageRole
    var state: MessageState = .idle
}
