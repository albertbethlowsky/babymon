import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SleepSession.startedAt, order: .reverse) private var sessions: [SleepSession]

    var body: some View {
        ZStack {
            BabymonTheme.backgroundGradient
                .ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SummaryCard(sessions: lastWeek)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        Text("Recent Sessions")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)

                        VStack(spacing: 10) {
                            ForEach(sessions) { session in
                                SessionCard(session: session)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Sleep History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var lastWeek: [SleepSession] {
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        return sessions.filter { $0.startedAt >= cutoff }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 40))
                .foregroundStyle(BabymonTheme.accent.opacity(0.5))
            Text("No Sleep Recorded Yet")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Text("Start a monitor session to begin tracking.\nSessions under 2 minutes are not saved.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Summary

private struct SummaryCard: View {
    let sessions: [SleepSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Last 7 Days")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(sessions.count) session\(sessions.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 16) {
                StatTile(
                    label: "Total",
                    value: formatTotal(totalDuration),
                    color: BabymonTheme.accentLight
                )
                StatTile(
                    label: "Avg / session",
                    value: formatDuration(avgDuration),
                    color: BabymonTheme.softBlue
                )
                StatTile(
                    label: "Wake-ups",
                    value: "\(totalWakes)",
                    color: BabymonTheme.warmPink
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(BabymonTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(BabymonTheme.hairline, lineWidth: 1))
        )
    }

    private var totalDuration: TimeInterval { sessions.reduce(0) { $0 + $1.duration } }
    private var avgDuration: TimeInterval { sessions.isEmpty ? 0 : totalDuration / Double(sessions.count) }
    private var totalWakes: Int { sessions.reduce(0) { $0 + $1.wakeCount } }
}

private struct StatTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Session Card

private struct SessionCard: View {
    let session: SleepSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(timeRangeLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ModeBadge(mode: session.mode)
            }

            HStack(spacing: 14) {
                MetricChip(icon: "clock.fill", text: formatDuration(session.duration), tint: BabymonTheme.accentLight)
                MetricChip(
                    icon: "exclamationmark.triangle.fill",
                    text: "\(session.wakeCount) wake\(session.wakeCount == 1 ? "" : "s")",
                    tint: session.wakeCount == 0 ? BabymonTheme.softGreen : BabymonTheme.warmPink
                )
            }

            if !session.wakeEvents.isEmpty {
                WakeTimeline(session: session)
                    .frame(height: 22)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BabymonTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(BabymonTheme.hairline, lineWidth: 1))
        )
    }

    private var dayLabel: String {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: session.startedAt)
    }

    private var timeRangeLabel: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return "\(f.string(from: session.startedAt)) – \(f.string(from: session.endedAt))"
    }
}

private struct ModeBadge: View {
    let mode: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.12)))
    }

    private var icon: String { mode == "audio" ? "waveform" : "video.fill" }
    private var label: String { mode == "audio" ? "Audio" : "Video" }
    private var tint: Color { mode == "audio" ? BabymonTheme.softGreen : BabymonTheme.accentLight }
}

private struct MetricChip: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

private struct WakeTimeline: View {
    let session: SleepSession

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(BabymonTheme.hairline)
                    .frame(height: 3)
                    .frame(maxHeight: .infinity, alignment: .center)

                ForEach(session.wakeEvents) { event in
                    Circle()
                        .fill(BabymonTheme.warmPink)
                        .frame(width: 8, height: 8)
                        .offset(x: xOffset(for: event, width: geo.size.width) - 4)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }

    private func xOffset(for event: WakeEvent, width: CGFloat) -> CGFloat {
        let total = session.duration
        guard total > 0 else { return 0 }
        let progress = event.timestamp.timeIntervalSince(session.startedAt) / total
        return CGFloat(min(max(progress, 0), 1)) * width
    }
}

// MARK: - Formatting helpers

private func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    let h = total / 3600
    let m = (total % 3600) / 60
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}

private func formatTotal(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    let h = total / 3600
    let m = (total % 3600) / 60
    if h == 0 { return "\(m)m" }
    return "\(h)h \(m)m"
}
