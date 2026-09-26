import Foundation
import SwiftUI

enum CollectionFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case collected = "collected"
    case missing = "missing"

    var id: Self { self }

    func includes(_ spot: Spot) -> Bool {
        switch self {
        case .all: true
        case .collected: spot.isCollected
        case .missing: !spot.isCollected
        }
    }
}

struct NeighborhoodSection: Identifiable {
    let id: String
    let spots: [Spot]
    let collectedCount: Int
    let totalCount: Int
}

enum CollectionLayout {
    /// Sections by neighborhood (most-collected first, then by name). Inside each:
    /// collected spots first, then missing, both sorted by name. Counts ignore the filter.
    static func sections(from spots: [Spot], filter: CollectionFilter) -> [NeighborhoodSection] {
        Dictionary(grouping: spots, by: \.neighborhood)
            .map { name, group in
                let byName: (Spot, Spot) -> Bool = { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                let collected = group.filter(\.isCollected).sorted(by: byName)
                let missing = group.filter { !$0.isCollected }.sorted(by: byName)
                return NeighborhoodSection(
                    id: name,
                    spots: (collected + missing).filter(filter.includes),
                    collectedCount: collected.count,
                    totalCount: group.count
                )
            }
            .filter { !$0.spots.isEmpty }
            .sorted {
                ($0.collectedCount, $1.id) > ($1.collectedCount, $0.id)
            }
    }
}

/// The pins-style collection: all / collected / missing, sections by neighborhood,
/// with a toggle to "my map" (your visits on a map).
struct CollectionView: View {
    @Environment(AppModel.self) private var model
    @State private var showsMap = false
    @State private var filter: CollectionFilter = .all
    @State private var collapsed: Set<String> = []
    @State private var selected: SpotRoute?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        NavigationStack {
            Group {
                if showsMap {
                    VisitMapView(spots: model.collection, selected: $selected)
                } else {
                    grid
                }
            }
            .navigationTitle(showsMap ? "my map" : "collection")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) { showsMap.toggle() }
                    } label: {
                        Image(systemName: showsMap ? "square.grid.2x2" : "map")
                    }
                    .accessibilityLabel(showsMap ? "show collection grid" : "show my map")
                }
            }
            .task { await model.loadCollection() }
            .sheet(item: $selected) { route in
                SpotSheet(spotID: route.id)
            }
        }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("filter", selection: $filter) {
                    ForEach(CollectionFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                content
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(.background.secondary)
        .safeAreaInset(edge: .top, spacing: 0) {
            if model.collectionState == .loaded {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .refreshable { await model.loadCollection() }
    }

    private var summary: String {
        let collected = model.collection.filter(\.isCollected).count
        return "\(collected) of \(model.collection.count) blocks collected"
    }

    @ViewBuilder
    private var content: some View {
        switch model.collectionState {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .failed(let error) where model.collection.isEmpty:
            ContentUnavailableView {
                Label("can't load your collection", systemImage: "wifi.slash")
            } description: {
                Text(error)
            } actions: {
                Button("try again") { Task { await model.loadCollection() } }
            }
        default:
            let sections = CollectionLayout.sections(from: model.collection, filter: filter)
            if sections.isEmpty {
                ContentUnavailableView(
                    filter == .collected ? "nothing collected yet" : "no spots here",
                    systemImage: "movieclapper",
                    description: Text(filter == .collected ? "walk to a filmed block and check in to collect it." : "pull to refresh.")
                )
            } else {
                ForEach(sections) { section in
                    sectionView(section)
                }
            }
        }
    }

    private func sectionView(_ section: NeighborhoodSection) -> some View {
        let isCollapsed = collapsed.contains(section.id)
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    if isCollapsed { collapsed.remove(section.id) } else { collapsed.insert(section.id) }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(section.id).font(.title3.bold()).foregroundStyle(.primary)
                    Text("\(section.collectedCount) of \(section.totalCount)").foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.red)
                        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                    Spacer()
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(section.id), \(section.collectedCount) of \(section.totalCount) collected")
            .accessibilityHint(isCollapsed ? "expands the section" : "collapses the section")

            if !isCollapsed {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(section.spots) { spot in
                        Button {
                            selected = SpotRoute(id: spot.id)
                        } label: {
                            VStack(spacing: 6) {
                                SpotBadge(symbol: spot.badgeSymbol, isCollected: spot.isCollected)
                                Text(spot.name)
                                    .font(.caption)
                                    .foregroundStyle(spot.isCollected ? .primary : .secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(spot.name), \(spot.isCollected ? "collected" : "not collected")")
                    }
                }
            }
        }
    }
}

#Preview {
    CollectionView()
        .environment(AppModel(service: MockChairService()))
}
