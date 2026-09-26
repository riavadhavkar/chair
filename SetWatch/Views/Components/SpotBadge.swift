import Foundation
import SwiftUI

/// Red with a white check when collected, gray when missing.
struct SpotBadge: View {
    let isCollected: Bool
    var size: CGFloat = 76

    var body: some View {
        Circle()
            .fill(isCollected ? Color.red : Color.gray.opacity(0.4))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "movieclapper")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.white)
            }
            .overlay(alignment: .bottomTrailing) {
                if isCollected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.3))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, .white)
                        .offset(x: size * 0.02, y: size * 0.02)
                }
            }
            .shadow(color: isCollected ? .red.opacity(0.25) : .clear, radius: size * 0.12, y: size * 0.06)
            .accessibilityHidden(true)
    }
}

/// "212 people have been here · A classic" / "You're one of 4 people · Secret spot"
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
        let people = spot.visitorCount == 1 ? "1 person" : "\(spot.visitorCount) people"
        if spot.visitorCount == 0 { return AttributedString(spot.vibe) }
        var result = AttributedString(spot.isCollected ? "You're one of " : "")
        var bold = AttributedString(people)
        bold.font = .subheadline.weight(.semibold)
        result += bold
        result += AttributedString(spot.isCollected ? " · \(spot.vibe)" : " have been here · \(spot.vibe)")
        return result
    }
}

#Preview {
    HStack(spacing: 24) {
        SpotBadge(isCollected: true)
        SpotBadge(isCollected: false)
    }
}
