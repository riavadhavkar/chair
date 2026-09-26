//
//  ProductionCardView.swift
//  sair
//

import SwiftUI

/// Poster + facts. Matched and permit-only productions are deliberately
/// different: real poster art vs a line-drawn slate and the raw permit text.
struct ProductionCardView: View {
    let production: Production

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            artwork
                .frame(width: 124, height: 186)

            VStack(alignment: .leading, spacing: 8) {
                filmingNowRow

                Text(production.displayTitle)
                    .font(.system(size: production.isMatched ? 24 : 20, weight: .semibold))
                    .lineLimit(2)
                    .accessibilityAddTraits(.isHeader)

                Text(production.metaLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(production.match?.overview ?? production.summary)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if production.isMatched {
                    locationRow
                } else {
                    permitExcerpt
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let match = production.match {
            AsyncImage(url: match.posterURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Color(white: 0.12)
                    Text(match.title)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .multilineTextAlignment(.center)
                        .padding(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 0.5))
            .accessibilityLabel("Poster for \(match.title)")
        } else {
            VStack(spacing: 14) {
                Image(systemName: "movieclapper")
                    .font(.system(size: 44, weight: .ultraLight))
                Text(production.kindDescription.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.6)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
            .accessibilityHidden(true)
        }
    }

    private var filmingNowRow: some View {
        HStack(spacing: 7) {
            Circle().fill(Color.red).frame(width: 7, height: 7)
            Text(["Filming now", production.untilText].compactMap { $0 }.joined(separator: " · "))
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.85))
    }

    private var locationRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "mappin")
            VStack(alignment: .leading, spacing: 2) {
                Text(production.location.display).font(.callout.weight(.semibold))
                Text(production.distanceText).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var permitExcerpt: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FROM THE PERMIT")
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(production.location.raw)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(3)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 24) {
        ForEach(NearbyResponse.mock.productions) { ProductionCardView(production: $0) }
    }
    .padding()
    .frame(width: 540)
    .background(.black)
    .environment(\.colorScheme, .dark)
}
