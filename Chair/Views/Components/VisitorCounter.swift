import Foundation
import SwiftUI

/// "212 people have been here · a classic" / "you're one of 4 people · secret spot"
struct VisitorCounter: View {
    let spot: Spot

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: spot.isCollected ? "star.fill" : "person.2.fill")
        }
        .font(.subheadline)
        .foregroundStyle(.red)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.red.opacity(0.1), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var text: AttributedString {
        if spot.visitorCount == 0 { return AttributedString(spot.vibe) }
        let people = spot.visitorCount == 1 ? "1 person" : "\(spot.visitorCount) people"
        var result = AttributedString(spot.isCollected ? "you're one of " : "")
        var bold = AttributedString(people)
        bold.font = .subheadline.weight(.semibold)
        result += bold
        result += AttributedString(spot.isCollected ? " · \(spot.vibe)" : " have been here · \(spot.vibe)")
        return result
    }
}
