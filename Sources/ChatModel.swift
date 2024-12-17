import Foundation

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
