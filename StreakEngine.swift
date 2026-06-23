// StreakEngine.swift
//
// All streak-related business logic lives in this file.
// It is intentionally separated from the UI layer so the rules can be read,
// reasoned about, and tested in isolation.
//
// Design principles:
//  • Every public method is a static function — no hidden state.
//  • AppState is mutated directly; SwiftData observes the changes automatically.
//  • "Today" is always resolved at call time via Date(), so the engine stays
//    accurate even if the device clock advances while the app is open.

import Foundation
import SwiftData

enum StreakEngine {

    // ─────────────────────────────────────────────
    // MARK: - Public API
    // ─────────────────────────────────────────────

    /// Call once on app launch (after the model context is ready).
    /// 1. Tops up the weekly freeze allowance if eligible.
    /// 2. Burns freezes (or resets the streak) for any days missed while the app was closed.
    static func auditOnLaunch(
        state: AppState,
        tasks: [TaskItem],
        completions: [TaskCompletion]
    ) {
        refillFreezeIfEligible(state: state)
        penaliseMissedDays(state: state, tasks: tasks, completions: completions)
    }

    /// Call every time the user toggles a completion (add or remove).
    /// Advances the streak by 1 the first time all tasks are finished in a calendar day.
    static func evaluateAfterToggle(
        state: AppState,
        tasks: [TaskItem],
        completions: [TaskCompletion]
    ) {
        // Nothing to do if the daily goal isn't met yet.
        guard allTasksDoneToday(tasks: tasks, completions: completions) else { return }

        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())

        // Already credited today — prevent double-counting.
        if let last = state.lastCompletedDay, cal.isDate(last, inSameDayAs: todayStart) {
            return
        }

        // If yesterday was the previous completion day the run is consecutive.
        let wasConsecutive: Bool = {
            guard let last = state.lastCompletedDay else { return false }
            let yesterday = cal.date(byAdding: .day, value: -1, to: todayStart)!
            return cal.isDate(last, inSameDayAs: yesterday)
        }()

        if wasConsecutive || state.lastCompletedDay == nil {
            // Extend the current run.
            state.currentStreak += 1
        } else {
            // A gap existed; penaliseMissedDays already handled freezes/resets
            // on launch. Start a fresh run of 1.
            state.currentStreak = 1
        }

        // Update all-time best.
        if state.currentStreak > state.longestStreak {
            state.longestStreak = state.currentStreak
        }

        state.lastCompletedDay = todayStart
    }

    /// Returns true when every task has a completion record for today.
    /// Returns false (never true) when the task list is empty — zero tasks cannot be "all done."
    static func allTasksDoneToday(
        tasks: [TaskItem],
        completions: [TaskCompletion]
    ) -> Bool {
        guard !tasks.isEmpty else { return false }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return tasks.allSatisfy { task in
            completions.contains {
                $0.taskID == task.id && cal.isDate($0.dateCompleted, inSameDayAs: today)
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Private helpers
    // ─────────────────────────────────────────────

    /// Awards one freeze (cap: 2) when at least 7 days have passed since the last refill.
    /// Called on launch so the user never has to open the app on an exact weekly cadence.
    private static func refillFreezeIfEligible(state: AppState) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        if let lastRefill = state.lastFreezeRefillDate {
            let days = cal.dateComponents(
                [.day],
                from: cal.startOfDay(for: lastRefill),
                to: today
            ).day ?? 0
            guard days >= 7 else { return }
        }

        // Never exceed the maximum of 2 freezes.
        if state.freezeCount < 2 {
            state.freezeCount += 1
        }
        state.lastFreezeRefillDate = today
    }

    /// Works through each fully-missed day since the last recorded completion.
    /// For each missed day it either spends a freeze (streak survives) or resets
    /// the streak to 0 when no freeze is available.
    private static func penaliseMissedDays(
        state: AppState,
        tasks: [TaskItem],
        completions: [TaskCompletion]
    ) {
        // With no tasks, there is no concept of "missing" a day.
        guard !tasks.isEmpty else { return }

        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())

        // No prior completion means there is nothing to penalise.
        guard let lastDone = state.lastCompletedDay else { return }
        let lastStart = cal.startOfDay(for: lastDone)

        // If the last completion was today or later, nothing to penalise.
        guard lastStart < todayStart else { return }

        // How many complete calendar days lie between last completion and today?
        let totalDays = cal.dateComponents([.day], from: lastStart, to: todayStart).day ?? 0
        guard totalDays > 0 else { return }

        // We penalise days that were fully missed.
        // If today's tasks are already done we don't count today as missed.
        var daysToProcess = totalDays
        if allTasksDoneToday(tasks: tasks, completions: completions) {
            daysToProcess -= 1  // today is in progress/complete, not a miss
        }

        for _ in 0..<daysToProcess {
            if state.freezeCount > 0 {
                // Spend one freeze: streak survives, but advance the anchor so this day
                // isn't counted again on the next launch.
                state.freezeCount -= 1
                state.lastCompletedDay = cal.date(
                    byAdding: .day,
                    value: 1,
                    to: state.lastCompletedDay!
                )
            } else {
                // Ran out of freezes: streak is gone. Clear the anchor so the next
                // completed day starts a fresh run from 1.
                state.currentStreak = 0
                state.lastCompletedDay = nil
                return
            }
        }
    }
}
