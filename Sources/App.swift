import Adwaita
import ChatGPTSwift
import Foundation

@main struct AdwaitaTemplate: App {

    var app = AdwaitaApp(id: "com.alfianlosari.xca-gtk-chatgpt")

    var scene: Scene {
        Window(id: "content") { window in
            ChatListView(window: window, app: app)
        }
    }

}
