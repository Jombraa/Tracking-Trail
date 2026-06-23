import Foundation

// A single renderable row in the trail scroll view.
enum TrailItem: Identifiable {
    case groupHeader(name: String, done: Int, total: Int)
    case node(
        task: TaskItem,
        trailIndex: Int,     // used for the zig-zag x-offset calculation
        isLocked: Bool,
        isCompleted: Bool,
        isLive: Bool,
        positionLabel: String?  // e.g. "2/3" for grouped tasks; nil for standalone
    )

    var id: String {
        switch self {
        case .groupHeader(let name, _, _):
            return "hdr-\(name)"
        case .node(let task, _, _, _, _, _):
            return "node-\(task.id.uuidString)"
        }
    }
}

struct TrailBuilder {

    /// Converts the flat list of TaskItems into an ordered trail, injecting group
    /// section headers and computing lock / completion / live state for every node.
    static func build(
        tasks: [TaskItem],
        completions: [TaskCompletion]
    ) -> [TrailItem] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func doneToday(_ task: TaskItem) -> Bool {
            completions.contains {
                $0.taskID == task.id && cal.isDate($0.dateCompleted, inSameDayAs: today)
            }
        }

        // Sort all tasks by their stored sortOrder.
        let sorted = tasks.sorted { $0.sortOrder < $1.sortOrder }

        // ── Build ordered "units" ──────────────────────────────────────────
        // A unit is either a named group (one or more tasks) or a standalone task.
        // We preserve relative order by tracking the sortOrder of the first task
        // that introduced each group.

        struct Unit {
            var minSortOrder: Int
            var groupName: String?  // nil → standalone
            var tasks: [TaskItem]
        }

        var groupUnits: [String: Unit] = [:]
        var groupInsertionOrder: [String] = []
        var standaloneUnits: [Unit] = []

        for task in sorted {
            let g = task.groupName
            if !g.isEmpty {
                if groupUnits[g] == nil {
                    groupUnits[g] = Unit(minSortOrder: task.sortOrder, groupName: g, tasks: [])
                    groupInsertionOrder.append(g)
                }
                groupUnits[g]!.tasks.append(task)
            } else {
                standaloneUnits.append(Unit(minSortOrder: task.sortOrder, groupName: nil, tasks: [task]))
            }
        }

        var allUnits: [Unit] = groupInsertionOrder.compactMap { groupUnits[$0] }
        allUnits.append(contentsOf: standaloneUnits)
        allUnits.sort { $0.minSortOrder < $1.minSortOrder }

        // ── Emit TrailItems ───────────────────────────────────────────────
        var items: [TrailItem] = []
        var trailIndex = 0  // increments only for node items, used for zig-zag offset

        for unit in allUnits {
            if let groupName = unit.groupName {
                let done = unit.tasks.filter { doneToday($0) }.count
                items.append(.groupHeader(name: groupName, done: done, total: unit.tasks.count))

                for (i, task) in unit.tasks.enumerated() {
                    let completed = doneToday(task)
                    // Each group task is locked until the immediately preceding task is done.
                    let locked = i > 0 && !doneToday(unit.tasks[i - 1])
                    let label = "\(i + 1)/\(unit.tasks.count)"
                    items.append(.node(
                        task: task,
                        trailIndex: trailIndex,
                        isLocked: locked,
                        isCompleted: completed,
                        isLive: task.isLive,
                        positionLabel: label
                    ))
                    trailIndex += 1
                }
            } else {
                let task = unit.tasks[0]
                items.append(.node(
                    task: task,
                    trailIndex: trailIndex,
                    isLocked: false,     // standalone tasks are always available
                    isCompleted: doneToday(task),
                    isLive: task.isLive,
                    positionLabel: nil
                ))
                trailIndex += 1
            }
        }

        return items
    }
}
