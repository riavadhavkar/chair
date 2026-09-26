//
//  NotchShape.swift
//  sair
//

import SwiftUI

enum NotchLayout {
    /// Concave top corners that make the shape read as part of the screen edge.
    static let shoulder: CGFloat = 8
    /// Space either side of the camera for the idle pill's leading/trailing content.
    static let flankWidth: CGFloat = 64
    static let idleBottomRadius: CGFloat = 12
    static let expandedBottomRadius: CGFloat = 28
    static let expandedSize = CGSize(width: 556, height: 380)

    static func idleSize(notch: CGSize) -> CGSize {
        CGSize(width: notch.width + 2 * flankWidth + 2 * shoulder, height: max(notch.height, 32))
    }
}

/// One black shape that grows out of the notch: flush with the top screen edge,
/// concave shoulders, rounded bottom corners.
struct NotchShape: Shape {
    var bottomRadius: CGFloat
    var shoulder: CGFloat = NotchLayout.shoulder

    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let s = min(shoulder, w / 4, h / 2)
        let r = max(0, min(bottomRadius, h - s, (w - 2 * s) / 2))

        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(to: CGPoint(x: s, y: s), control: CGPoint(x: s, y: 0))
        path.addLine(to: CGPoint(x: s, y: h - r))
        path.addQuadCurve(to: CGPoint(x: s + r, y: h), control: CGPoint(x: s, y: h))
        path.addLine(to: CGPoint(x: w - s - r, y: h))
        path.addQuadCurve(to: CGPoint(x: w - s, y: h - r), control: CGPoint(x: w - s, y: h))
        path.addLine(to: CGPoint(x: w - s, y: s))
        path.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w - s, y: 0))
        path.closeSubpath()
        return path
    }
}

#Preview {
    NotchShape(bottomRadius: 28)
        .fill(.black)
        .frame(width: 556, height: 380)
        .padding()
        .background(Color.gray)
}
