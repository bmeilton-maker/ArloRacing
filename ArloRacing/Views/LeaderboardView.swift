import SwiftUI
import SwiftData

struct LeaderboardManager {
    static let maxEntries = GameConstants.leaderboardMaxEntries

    static func isTopScore(trackId: Int, timeMillis: Int, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<LeaderboardEntry>(
            predicate: #Predicate<LeaderboardEntry> { entry in
                entry.trackId == trackId
            },
            sortBy: [SortDescriptor(\.timeMillis)]
        )

        let entries = (try? context.fetch(descriptor)) ?? []

        if entries.count < maxEntries { return true }
        if let worst = entries.last, timeMillis < worst.timeMillis { return true }
        return false
    }

    static func addEntry(_ entry: LeaderboardEntry, context: ModelContext) {
        context.insert(entry)

        let trackId = entry.trackId
        let descriptor = FetchDescriptor<LeaderboardEntry>(
            predicate: #Predicate<LeaderboardEntry> { e in
                e.trackId == trackId
            },
            sortBy: [SortDescriptor(\.timeMillis)]
        )

        if let entries = try? context.fetch(descriptor), entries.count > maxEntries {
            for e in entries.dropFirst(maxEntries) {
                context.delete(e)
            }
        }
    }
}

struct LeaderboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTrack: Track? = nil // nil = "All"
    @State private var entries: [LeaderboardEntry] = []

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                trackSelector

                if entries.isEmpty {
                    emptyState
                } else if selectedTrack == nil {
                    allTracksList
                } else {
                    rankedList
                }
            }
        }
        .navigationTitle("Leaderboards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            fetchEntries()
        }
    }

    // MARK: - Track selector chips

    private var trackSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(label: "All", isSelected: selectedTrack == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTrack = nil }
                    fetchEntries()
                }

                ForEach(allTracks) { track in
                    FilterChip(label: track.name, isSelected: selectedTrack?.id == track.id, tint: track.theme.accentColor) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTrack = track }
                        fetchEntries()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Content states

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: selectedTrack == nil ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 38))
                .foregroundColor(AppTheme.textTertiary)
            Text("No times recorded yet")
                .font(AppTheme.bodyFont(17, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            Text("Race this track to set the first record!")
                .font(AppTheme.bodyFont(13))
                .foregroundColor(AppTheme.textTertiary)
            Spacer()
        }
    }

    /// "All" tab — one best-entry-per-track "track record" card each
    /// (see fetchEntries: entries here is already deduped to one per track).
    private var allTracksList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(entries) { entry in
                    TrackRecordCard(entry: entry, track: allTracks.first(where: { $0.id == entry.trackId }))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }

    /// Single-track tab — ranked rows with medal treatment for top 3.
    private var rankedList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    RankedEntryRow(rank: index + 1, entry: entry)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }

    private func fetchEntries() {
        if let track = selectedTrack {
            let trackId = track.id
            let descriptor = FetchDescriptor<LeaderboardEntry>(
                predicate: #Predicate<LeaderboardEntry> { entry in
                    entry.trackId == trackId
                },
                sortBy: [SortDescriptor(\.timeMillis)]
            )
            entries = (try? modelContext.fetch(descriptor)) ?? []
        } else {
            // "All" — show each track's record. Times across tracks of
            // different lengths aren't comparable, so a single global
            // ranking would just be dominated by the shortest track.
            let descriptor = FetchDescriptor<LeaderboardEntry>(
                sortBy: [SortDescriptor(\.timeMillis)]
            )
            let all = (try? modelContext.fetch(descriptor)) ?? []
            var bestPerTrack: [Int: LeaderboardEntry] = [:]
            for entry in all where bestPerTrack[entry.trackId] == nil {
                bestPerTrack[entry.trackId] = entry // sorted fetch → first seen is fastest
            }
            entries = allTracks.compactMap { bestPerTrack[$0.id] }
        }
    }
}

// MARK: - Filter chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var tint: Color = AppTheme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.bodyFont(14, weight: .semibold))
                .foregroundColor(isSelected ? .black : AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(AppTheme.surfaceElevated))
                )
                .shadow(color: isSelected ? tint.opacity(0.4) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - "All" track-record card

private struct TrackRecordCard: View {
    let entry: LeaderboardEntry
    let track: Track?

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4)
                .fill((track?.theme.accentColor ?? .gray).gradient)
                .frame(width: 5, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(track?.name ?? "Unknown Track")
                    .font(AppTheme.titleFont(16))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textTertiary)
                    Text(entry.playerName)
                        .font(AppTheme.bodyFont(13))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("· \(entry.vehicleId.capitalized)")
                        .font(AppTheme.bodyFont(12))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            Spacer()

            Text(entry.timeMillis.millisToRaceTime)
                .font(AppTheme.monoFont(18))
                .foregroundColor(track?.theme.accentColor ?? AppTheme.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke((track?.theme.accentColor ?? .gray).opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Ranked row (specific track) — medal treatment for top 3

private struct RankedEntryRow: View {
    let rank: Int
    let entry: LeaderboardEntry

    private var medalColor: Color? {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(medalColor.map { AnyShapeStyle($0.gradient) } ?? AnyShapeStyle(Color.white.opacity(0.08)))
                Text("\(rank)")
                    .font(AppTheme.titleFont(14))
                    .foregroundColor(medalColor != nil ? .black.opacity(0.75) : AppTheme.textSecondary)
            }
            .frame(width: 30, height: 30)

            Text(entry.playerName)
                .font(AppTheme.bodyFont(16, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Text(entry.vehicleId.capitalized)
                .font(AppTheme.bodyFont(12))
                .foregroundColor(AppTheme.textTertiary)

            Text(entry.timeMillis.millisToRaceTime)
                .font(AppTheme.monoFont(16))
                .foregroundColor(.white)
                .frame(width: 78, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.surface)
        )
    }
}
