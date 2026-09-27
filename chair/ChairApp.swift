import Foundation
import SwiftUI

@main
struct ChairApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .tint(.red)
                .textCase(.lowercase)
                .task { model.location.start() }
        }
    }
}
