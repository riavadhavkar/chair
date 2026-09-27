import Foundation
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("today", systemImage: "movieclapper") {
                TodayView()
            }
            Tab("walk", systemImage: "figure.walk") {
                WalkView()
            }
            Tab("collection", systemImage: "square.grid.2x2") {
                CollectionView()
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppModel(service: MockChairService()))
}
