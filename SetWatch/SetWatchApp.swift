import Foundation
import SwiftUI

@main
struct SetWatchApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .tint(.red)
                .task { model.location.start() }
        }
    }
}
