//
//  TrainTrackerView.swift
//  sair
//

import SwiftUI

/// Flighty-style centerpiece: a stylized route line with a glowing, gliding
/// position dot and a live countdown — the primary glanceable element in the
/// expanded panel. Deliberately plain SwiftUI shapes, no map tiles, so it
/// renders instantly. The literal Mapbox map is a separate, secondary layer.
struct TrainTrackerView: View {
    let stops: [RouteStop]
    var trainProgress: Double
    var nextStopName: String
    var etaMinutes: Int
    let lineColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    @State private var remainingSeconds: Int = 0

    init(
        stops: [RouteStop] = RouteStop.mockRoute,
        trainProgress: Double = 0.35,
        nextStopName: String = "14 St",
        etaMinutes: Int = 4,
        lineColor: Color = MTALineColor.l
    ) {
        self.stops = stops
        self.trainProgress = trainProgress
        self.nextStopName = nextStopName
        self.etaMinutes = etaMinutes
        self.lineColor = lineColor
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(countdownText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .monospacedDigit()

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    trackLine(width: geometry.size.width, height: geometry.size.height)

                    ForEach(stops) { stop in
                        stopMarker(for: stop, in: geometry.size)
                    }

                    trainDot(in: geometry.size)
                }
            }
            .frame(height: 44)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(nextStopName) in \(remainingSeconds / 60) minutes \(remainingSeconds % 60) seconds")
        .accessibilityAddTraits(.updatesFrequently)
        .task(id: etaMinutes) {
            remainingSeconds = etaMinutes * 60
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if remainingSeconds > 0 { remainingSeconds -= 1 }
            }
        }
        .onAppear { startPulsing() }
    }

    private var countdownText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d to %@", minutes, seconds, nextStopName)
    }

    private func trackLine(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: width, height: 3)

            Capsule()
                .fill(lineColor.opacity(0.85))
                .frame(width: width * trainProgress, height: 3)
        }
        .frame(height: height, alignment: .center)
        .animation(reduceMotion ? .easeInOut(duration: 0.3) : .easeInOut(duration: 1.2), value: trainProgress)
    }

    @ViewBuilder
    private func stopMarker(for stop: RouteStop, in size: CGSize) -> some View {
        let isNext = stop.name == nextStopName
        VStack(spacing: 4) {
            Circle()
                .fill(isNext ? lineColor : Color.secondary.opacity(0.5))
                .frame(width: isNext ? 8 : 5, height: isNext ? 8 : 5)
            if isNext {
                Text(stop.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
        .position(x: size.width * stop.progress, y: size.height / 2)
    }

    private func trainDot(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(lineColor)
                .frame(width: 14, height: 14)
                .opacity(0.35)
                .scaleEffect(isPulsing ? 1.6 : 1.0)

            Circle()
                .fill(lineColor)
                .frame(width: 10, height: 10)
                .shadow(color: lineColor.opacity(0.8), radius: 6)
        }
        .position(x: size.width * trainProgress, y: size.height / 2)
        .animation(reduceMotion ? .easeInOut(duration: 0.3) : .easeInOut(duration: 1.2), value: trainProgress)
    }

    private func startPulsing() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

#Preview {
    TrainTrackerView()
        .padding()
        .frame(width: 320)
        .background(.black)
        .environment(\.colorScheme, .dark)
}
