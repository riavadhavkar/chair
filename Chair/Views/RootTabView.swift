import Foundation
import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: RootTab = .today

    var body: some View {
        TabView(selection: $selection) {
            Tab("today", systemImage: "movieclapper", value: .today) {
                TodayView()
            }
            Tab("walk", systemImage: "figure.walk", value: .walk) {
                WalkView()
            }
            Tab("collection", systemImage: "square.grid.2x2", value: .collection) {
                CollectionView()
            }
        }
        // A spot sheet's "walking directions" button sets this to hand off
        // to the walk tab instead of leaving the app for Apple Maps.
        .onChange(of: model.directionsDestination) { _, destination in
            if destination != nil { selection = .walk }
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppModel(service: MockChairService()))
}
