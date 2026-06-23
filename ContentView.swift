import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortOrder) private var tasks: [TaskItem]
    @Query private var completions: [TaskCompletion]
    @Query private var appStates: [AppState]

    @State private var showAddSheet = false
    @State private var editingTask: TaskItem?
    @State private var confettiBurst = false
    @State private var toastMessage = ""
    @State private var showToast = false

    // Fetch-or-create the singleton AppState.
    private var appState: AppState {
        if let s = appStates.first { return s }
        let s = AppState()
        modelContext.insert(s)
        return s
    }

    private var goalMet: Bool {
        StreakEngine.allTasksDoneToday(tasks: Array(tasks), completions: Array(completions))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                streakHeader
                Divider()
                TrailView(
                    tasks: Array(tasks),
                    completions: Array(completions),
                    onToggle: { toggle(task: $0) },
                    onEdit:   { editingTask = $0 }
                )
            }

            // Floating action button
            HStack {
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 36)
            }

            // Toast
            if showToast {
                Text(toastMessage)
                    .font(.callout.bold())
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 110)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Confetti overlay
            if confettiBurst {
                ConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .animation(.spring(duration: 0.35), value: showToast)
        .sheet(isPresented: $showAddSheet) {
            AddTaskSheet(task: nil, existingGroups: existingGroups) { name, emoji, group, hasDue, dueDate in
                let maxOrder = tasks.map(\.sortOrder).max() ?? -1
                let item = TaskItem(
                    name: name, emoji: emoji, groupName: group,
                    hasDueTime: hasDue, dueTime: dueDate, sortOrder: maxOrder + 1
                )
                modelContext.insert(item)
            }
        }
        .sheet(item: $editingTask) { task in
            AddTaskSheet(task: task, existingGroups: existingGroups) { name, emoji, group, hasDue, dueDate in
                task.name = name
                task.emoji = emoji
                task.groupName = group
                task.hasDueTime = hasDue
                task.dueTime = dueDate
            }
        }
        .onAppear {
            StreakEngine.auditOnLaunch(
                state: appState,
                tasks: Array(tasks),
                completions: Array(completions)
            )
        }
    }

    // ── Streak header ──────────────────────────────────────────────────────

    private var streakHeader: some View {
        HStack(spacing: 12) {
            // Flame
            Label("\(appState.currentStreak)", systemImage: goalMet ? "flame.fill" : "flame")
                .font(.title2.bold())
                .foregroundStyle(goalMet ? .orange : .secondary)

            Spacer()

            // Freeze shields
            HStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { i in
                    Image(systemName: i < appState.freezeCount ? "shield.fill" : "shield")
                        .foregroundStyle(i < appState.freezeCount ? Color.blue : Color.secondary.opacity(0.35))
                        .font(.subheadline)
                }
            }

            Text("Best \(appState.longestStreak)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // ── Toggle completion ──────────────────────────────────────────────────

    private func toggle(task: TaskItem) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        if let existing = completions.first(where: {
            $0.taskID == task.id && cal.isDate($0.dateCompleted, inSameDayAs: today)
        }) {
            modelContext.delete(existing)
        } else {
            let newCompletion = TaskCompletion(taskID: task.id)
            modelContext.insert(newCompletion)

            // Build synthetic array so StreakEngine sees the just-inserted record.
            let syntheticCompletions = Array(completions) + [newCompletion]
            let wasGoalMet = goalMet  // before this completion

            if !wasGoalMet && StreakEngine.allTasksDoneToday(
                tasks: Array(tasks),
                completions: syntheticCompletions
            ) {
                let before = appState.currentStreak
                StreakEngine.evaluateAfterToggle(
                    state: appState,
                    tasks: Array(tasks),
                    completions: syntheticCompletions
                )
                if appState.currentStreak > before {
                    displayToast("🔥 \(appState.currentStreak)-day streak!")
                } else {
                    displayToast("✅ All done today!")
                }
            }

            triggerConfetti()
        }
    }

    private func triggerConfetti() {
        confettiBurst = false
        // Small delay so SwiftUI picks up the state toggle.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            confettiBurst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                confettiBurst = false
            }
        }
    }

    private func displayToast(_ msg: String) {
        toastMessage = msg
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }

    private var existingGroups: [String] {
        let groups = tasks.compactMap { $0.groupName.isEmpty ? nil : $0.groupName }
        return Array(Set(groups)).sorted()
    }
}
