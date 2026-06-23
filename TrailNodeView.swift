import SwiftUI

struct TrailNodeView: View {
    let task: TaskItem
    let trailIndex: Int
    let isLocked: Bool
    let isCompleted: Bool
    let isLive: Bool
    let positionLabel: String?
    let onTap: () -> Void
    let onEdit: () -> Void

    @State private var pulsing = false

    private let nodeSize: CGFloat = 66
    private let amplitude: CGFloat = 84   // max horizontal displacement in points

    // sin(index × π/2) gives the sequence 0, 1, 0, -1, 0, 1 …
    // producing a smooth diamond-shaped path like Duolingo's map.
    private var xOffset: CGFloat {
        CGFloat(sin(Double(trailIndex) * .pi / 2)) * amplitude
    }

    // ── Colors ─────────────────────────────────────────────────────────────

    private var faceColor: Color {
        if isCompleted { return Color(red: 0.18, green: 0.78, blue: 0.45) }   // green
        if isLocked    { return Color(.systemGray4) }
        if isLive      { return .orange }
        return Color(red: 1.0, green: 0.78, blue: 0.0)                         // gold
    }

    private var shadowColor: Color {
        if isCompleted { return Color(red: 0.05, green: 0.52, blue: 0.28) }   // dark green
        if isLocked    { return Color(.systemGray3) }
        if isLive      { return Color(red: 0.78, green: 0.38, blue: 0.0) }    // dark orange
        return Color(red: 0.70, green: 0.52, blue: 0.0)                        // dark gold
    }

    // ── Body ───────────────────────────────────────────────────────────────

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                // Shadow ring — shifted down to create a raised / 3-D look
                Circle()
                    .fill(shadowColor)
                    .frame(width: nodeSize, height: nodeSize)
                    .offset(y: 5)

                // Main face
                Circle()
                    .fill(faceColor)
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay { nodeIcon }
                    .scaleEffect(pulsing ? 1.07 : 1.0)
            }
            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)

            // Task name
            Text(task.name)
                .font(.caption.bold())
                .foregroundStyle(isLocked ? .secondary : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 92)

            // Optional due-time label
            if !task.timeLabel.isEmpty {
                Text(task.timeLabel)
                    .font(.caption2)
                    .foregroundStyle(isLive ? .orange : .secondary)
            }

            // Group position badge (e.g. "2/3")
            if let pos = positionLabel {
                Text(pos)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .offset(x: xOffset)
        .contentShape(Rectangle())
        .onTapGesture { if !isLocked { onTap() } }
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
        }
        .onAppear { startPulseIfNeeded() }
        .onChange(of: isLive)      { startPulseIfNeeded() }
        .onChange(of: isCompleted) { startPulseIfNeeded() }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    @ViewBuilder
    private var nodeIcon: some View {
        if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
        } else if isLocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.55))
        } else {
            Text(task.emoji)
                .font(.system(size: 28))
        }
    }

    private func startPulseIfNeeded() {
        let shouldPulse = isLive && !isCompleted && !isLocked
        if shouldPulse {
            withAnimation(
                .easeInOut(duration: 0.85)
                .repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        } else {
            withAnimation(.default) {
                pulsing = false
            }
        }
    }
}
