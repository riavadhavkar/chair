//
//  NotchPillView.swift
//  sair
//

import SwiftUI

/// The notch row: leading content left of the camera, trailing content right
/// of it, nothing under the cutout. Stays put in both idle and expanded states
/// so only the shape grows around it.
struct NotchPillView: View {
    let production: Production?
    let isOffline: Bool
    let notchWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var recPulse = false

    var body: some View {
        HStack(spacing: 0) {
            leading
                .frame(width: NotchLayout.flankWidth, alignment: .leading)
                .padding(.leading, 12)
            Spacer(minLength: notchWidth)
            trailing
                .frame(width: NotchLayout.flankWidth, alignment: .trailing)
                .padding(.trailing, 12)
        }
        .padding(.horizontal, NotchLayout.shoulder)
        .foregroundStyle(.white)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var leading: some View {
        if let production {
            if let posterURL = production.match?.posterURL {
                AsyncImage(url: posterURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.white.opacity(0.15)
                }
                .frame(width: 18, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            } else {
                Image(systemName: "movieclapper")
                    .font(.system(size: 14, weight: .medium))
            }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isOffline, production == nil {
            Text("—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        } else if let production {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .opacity(recPulse ? 0.45 : 1)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { recPulse = true }
                    }
                Text(production.distanceText)
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    private var accessibilityText: String {
        guard let production else { return isOffline ? "Set Watch, offline" : "Set Watch, nothing filming nearby" }
        return "\(production.displayTitle), filming \(production.distanceText) away. Expand for details"
    }
}

#Preview {
    NotchPillView(production: NearbyResponse.mock.productions.first, isOffline: false, notchWidth: 185)
        .frame(width: 185 + 2 * NotchLayout.flankWidth + 2 * NotchLayout.shoulder, height: 32)
        .background(NotchShape(bottomRadius: 12).fill(.black))
}
