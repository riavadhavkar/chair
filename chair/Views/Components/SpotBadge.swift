import Foundation
import SwiftUI

/// A block's pin: its own street icon, red with a white check when collected, gray when missing.
struct SpotBadge: View {
    let symbol: String
    let isCollected: Bool
    var size: CGFloat = 76

    var body: some View {
        Circle()
            .fill(isCollected ? Color.red.gradient : Color.gray.opacity(0.35).gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.4, weight: .medium))
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

/// A collected pin you can drag to turn in 3D; a rainbow foil sheen follows the tilt.
struct HolographicBadge: View {
    let symbol: String
    let isCollected: Bool
    var size: CGFloat = 120

    @State private var drag: CGSize = .zero
    @State private var isDragging = false

    private var tiltX: Double { max(-40, min(40, Double(-drag.height) / 3)) }
    private var turnY: Double { Double(drag.width) * 0.9 }

    var body: some View {
        SpotBadge(symbol: symbol, isCollected: isCollected, size: size)
            .overlay {
                if isCollected { foil }
            }
            .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(turnY), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .gesture(dragToTurn, including: isCollected ? .all : .subviews)
            .sensoryFeedback(.impact(weight: .light), trigger: isDragging) { _, dragging in dragging }
            .accessibilityHint(isCollected ? "drag to turn the pin" : "")
    }

    private var foil: some View {
        let angle = Angle.degrees(Double(drag.width + drag.height) * 1.5)
        return ZStack {
            Circle()
                .fill(AngularGradient(
                    colors: [.pink, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
                    center: .center,
                    angle: angle
                ))
                .blendMode(.overlay)
                .opacity(isDragging ? 0.85 : 0.3)
            Circle()
                .fill(LinearGradient(
                    colors: [.white.opacity(0), .white.opacity(isDragging ? 0.55 : 0.2), .white.opacity(0)],
                    startPoint: UnitPoint(x: 0.2 + drag.width / 300, y: 0),
                    endPoint: UnitPoint(x: 0.8 + drag.width / 300, y: 1)
                ))
                .blendMode(.screen)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    private var dragToTurn: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                drag = value.translation
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                    drag = .zero
                    isDragging = false
                }
            }
    }
}

/// The badge in the spot sheet. When the block becomes collected it shrinks,
/// spins on its vertical axis three times while gaining color, pops past full
/// size and settles — with a sparkle burst behind it. Reduce Motion: a crossfade.
struct CollectibleBadge: View {
    let spot: Spot
    var size: CGFloat = 120

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsColor: Bool
    @State private var celebration = 0

    init(spot: Spot, size: CGFloat = 120) {
        self.spot = spot
        self.size = size
        _showsColor = State(initialValue: spot.isCollected)
    }

    var body: some View {
        ZStack {
            SparkleBurst(trigger: celebration, radius: size * 1.1)
            HolographicBadge(symbol: spot.badgeSymbol, isCollected: showsColor, size: size)
                .keyframeAnimator(initialValue: CollectMotion(), trigger: celebration) { content, motion in
                    content
                        .rotation3DEffect(.degrees(motion.spin), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                        .scaleEffect(motion.scale)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(0.8, duration: 0.15)
                        SpringKeyframe(1.3, duration: 0.55, spring: .bouncy)
                        SpringKeyframe(1.0, duration: 0.6, spring: .smooth)
                    }
                    KeyframeTrack(\.spin) {
                        CubicKeyframe(0, duration: 0.1)
                        CubicKeyframe(1080, duration: 1.1)
                    }
                }
        }
        .frame(width: size * 1.6, height: size * 1.6)
        .onChange(of: spot.isCollected) { wasCollected, isCollected in
            guard isCollected, !wasCollected else { return }
            if reduceMotion {
                withAnimation(.easeInOut(duration: 0.3)) { showsColor = true }
            } else {
                celebration += 1
                withAnimation(.easeInOut(duration: 0.3).delay(0.35)) { showsColor = true }
            }
        }
    }
}

nonisolated struct CollectMotion {
    var scale: CGFloat = 1
    var spin: Double = 0
}

/// Sparkles and a ring that fly out from the center each time `trigger` changes.
struct SparkleBurst: View {
    let trigger: Int
    var radius: CGFloat = 130

    private struct Particle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let symbol: String
        let color: Color
        let spin: Double
    }

    @State private var particles: [Particle] = []

    var body: some View {
        // keyframeAnimator's content closure isn't guaranteed MainActor by
        // its own type signature, so it can't implicitly read the
        // MainActor-isolated `particles` @State directly; capture a plain
        // (Sendable-safe) local snapshot instead.
        let currentParticles = particles
        Color.clear
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { _, progress in
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.35 * (1 - progress)), lineWidth: 3)
                        .frame(width: radius * (0.5 + progress), height: radius * (0.5 + progress))
                        .opacity(currentParticles.isEmpty ? 0 : 1)
                    ForEach(currentParticles) { particle in
                        Image(systemName: particle.symbol)
                            .font(.system(size: particle.size))
                            .foregroundStyle(particle.color)
                            .rotationEffect(.degrees(particle.spin * progress))
                            .scaleEffect(0.4 + 0.8 * sin(.pi * progress))
                            .offset(
                                x: cos(particle.angle) * particle.distance * progress,
                                y: sin(particle.angle) * particle.distance * progress
                            )
                            .opacity(1 - progress)
                    }
                }
            } keyframes: { _ in
                CubicKeyframe(1.0, duration: 1.3)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: trigger) {
                particles = (0..<24).map { _ in
                    Particle(
                        angle: Double.random(in: 0..<(2 * .pi)),
                        distance: CGFloat.random(in: radius * 0.45...radius),
                        size: CGFloat.random(in: 10...22),
                        symbol: ["sparkle", "star.fill", "sparkles", "circle.fill"].randomElement()!,
                        color: [Color.red, .orange, .yellow, .pink, .white].randomElement()!,
                        spin: Double.random(in: -180...180)
                    )
                }
            }
    }
}

#Preview {
    HStack(spacing: 24) {
        HolographicBadge(symbol: "guitars", isCollected: true)
        SpotBadge(symbol: "tree", isCollected: false)
    }
}
