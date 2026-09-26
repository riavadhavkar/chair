import Foundation
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "film") {
                TodayView()
            }
            Tab("Walk", systemImage: "figure.walk") {
                WalkView()
            }
            Tab("Collection", systemImage: "square.grid.2x2") {
                CollectionView()
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppModel(service: MockSetWatchService()))
}
