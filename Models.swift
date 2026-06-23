import Foundation
import SwiftData

// ── TaskItem ───────────────────────────────────────────────────────────────
// Represents one recurring daily task.
// groupName == "" means the task is standalone (always available).
// dueTime stores hour/minute only; the date component is ignored.
@Model
final class TaskItem {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "⭐️"
    var groupName: String = ""      // "" → no group
    var hasDueTime: Bool = false
    var dueTime: Date = Date()      // time-of-day only; date part is irrelevant
    var sortOrder: Int = 0

    init(
        name: String,
        emoji: String,
        groupName: String = "",
        hasDueTime: Bool = false,
        dueTime: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.groupName = groupName
        self.hasDueTime = hasDueTime
        self.dueTime = dueTime
        self.sortOrder = sortOrder
    }

    /// True when this task is due within the next 60 minutes or is already overdue today.
    var isLive: Bool {
        guard hasDueTime, let todayDue = todayDueDate else { return false }
        return Date() >= todayDue.addingTimeInterval(-3600)
    }

    /// Formatted time string for display under the node label.
    var timeLabel: String {
        guard hasDueTime, let todayDue = todayDueDate else { return "" }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: todayDue)
    }

    private var todayDueDate: Date? {
        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: dueTime)
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hm.hour
        comps.minute = hm.minute
        return cal.date(from: comps)
    }
}

// ── TaskCompletion ─────────────────────────────────────────────────────────
// One record per (task, day) pair when the user marks a task done.
@Model
final class TaskCompletion {
    var id: UUID = UUID()
    var taskID: UUID = UUID()
    var dateCompleted: Date = Date()

    init(taskID: UUID, dateCompleted: Date = Date()) {
        self.id = UUID()
        self.taskID = taskID
        self.dateCompleted = dateCompleted
    }
}

// ── AppState ───────────────────────────────────────────────────────────────
// Singleton. Fetch with a limit of 1; create one if the store is empty.
@Model
final class AppState {
    var id: UUID = UUID()
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletedDay: Date?         // nil = never completed
    var freezeCount: Int = 0
    var lastFreezeRefillDate: Date?     // nil = never refilled

    init() {
        self.id = UUID()
    }
}
