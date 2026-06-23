import SwiftUI

struct TrailView: View {
    let tasks: [TaskItem]
    let completions: [TaskCompletion]
    let onToggle: (TaskItem) -> Void
    let onEdit: (TaskItem) -> Void

    private var trailItems: [TrailItem] {
        TrailBuilder.build(tasks: tasks, completions: completions)
    }

    var body: some View {
        if trailItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(trailItems) { item in
                        switch item {
                        case .groupHeader(let name, let done, let total):
                            GroupHeaderRow(name: name, done: done, total: total)
                                .padding(.top, 28)
                                .padding(.bottom, 6)

                        case .node(let task, let index, let locked, let completed, let live, let posLabel):
                            TrailNodeView(
                                task: task,
                                trailIndex: index,
                                isLocked: locked,
                                isCompleted: completed,
                                isLive: live,
                                positionLabel: posLabel,
                                onTap: { onToggle(task) },
                                onEdit: { onEdit(task) }
                            )
                            .padding(.vertical, 14)
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 120)   // room for FAB
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No tasks yet")
                .font(.title3.bold())
            Text("Tap + to add your first daily task")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }
}

// ── Group section header ───────────────────────────────────────────────────

struct GroupHeaderRow: View {
    let name: String
    let done: Int
    let total: Int

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(name.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .tracking(1.4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 5)
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(
                                width: total > 0
                                    ? geo.size.width * CGFloat(done) / CGFloat(total)
                                    : 0,
                                height: 5
                            )
                            .animation(.spring(duration: 0.4), value: done)
                    }
                }
                .frame(height: 5)
            }

            Text("\(done)/\(total)")
                .font(.caption.bold())
                .foregroundStyle(done == total ? .green : .secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 24)
    }
}
