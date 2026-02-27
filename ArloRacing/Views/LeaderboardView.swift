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
            Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()

            VStack(spacing: 0) {
                // Track selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // "All" button
                        Button {
                            selectedTrack = nil
                            fetchEntries()
                        } label: {
                            Text("All")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedTrack == nil ? .orange : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedTrack == nil ? Color.orange.opacity(0.2) : Color(white: 0.2))
                                )
                        }

                        ForEach(allTracks) { track in
                            Button {
                                selectedTrack = track
                                fetchEntries()
                            } label: {
                                Text(track.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTrack?.id == track.id ? .orange : .white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedTrack?.id == track.id ? Color.orange.opacity(0.2) : Color(white: 0.2))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)

                if entries.isEmpty {
                    Spacer()
                    Text("No times recorded yet")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                    Text("Race this track to set the first record!")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray.opacity(0.7))
                    Spacer()
                } else {
                    List {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(index < 3 ? .orange : .gray)
                                    .frame(width: 40, alignment: .leading)

                                Text(entry.playerName)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Spacer()

                                // Show track name in "All" view
                                if selectedTrack == nil {
                                    Text(allTracks.first(where: { $0.id == entry.trackId })?.name ?? "")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(.orange.opacity(0.7))
                                        .lineLimit(1)
                                }

                                Text(entry.vehicleId.capitalized)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.gray)

                                Text(entry.timeMillis.millisToRaceTime)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(white: 0.12))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
            // "All" — fetch all entries across tracks, sorted by time
            var descriptor = FetchDescriptor<LeaderboardEntry>(
                sortBy: [SortDescriptor(\.timeMillis)]
            )
            descriptor.fetchLimit = GameConstants.leaderboardMaxEntries
            entries = (try? modelContext.fetch(descriptor)) ?? []
        }
    }
}
