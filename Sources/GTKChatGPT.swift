import Adwaita
import Foundation

@main struct AdwaitaTemplate: App {

    var app = AdwaitaApp(id: "io.github.alfianlosari.GTKChatGPT")

    var scene: Scene {
        Window(id: "content") { window in
            ChatListView(window: window, app: app)
        }
    }

}
