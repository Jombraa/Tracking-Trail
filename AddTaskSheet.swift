import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    /// Non-nil when editing an existing task.
    let task: TaskItem?
    let existingGroups: [String]
    /// Called on save with (name, emoji, groupName, hasDueTime, dueTime).
    let onSave: (String, String, String, Bool, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var emoji: String = "⭐️"
    @State private var groupName: String = ""
    @State private var hasDueTime: Bool = false
    @State private var dueTime: Date = {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @State private var showEmojiPicker = false
    @State private var showDeleteAlert = false

    private var isEditing: Bool { task != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                // ── Name & emoji ───────────────────────────────────────────
                Section("Task") {
                    HStack(spacing: 12) {
                        Button {
                            showEmojiPicker = true
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                                .frame(width: 48, height: 48)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        TextField("Task name", text: $name)
                            .font(.body)
                    }
                }

                // ── Group ──────────────────────────────────────────────────
                Section {
                    TextField("Group name (optional)", text: $groupName)
                        .autocorrectionDisabled()

                    if !existingGroups.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "None" chip to clear the group
                                groupChip(label: "None", isSelected: groupName.isEmpty) {
                                    groupName = ""
                                }
                                ForEach(existingGroups, id: \.self) { g in
                                    groupChip(label: g, isSelected: groupName == g) {
                                        groupName = g
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Group")
                } footer: {
                    Text("Tasks in the same group are sequential — each unlocks when the previous is done.")
                        .font(.caption)
                }

                // ── Due time ───────────────────────────────────────────────
                Section("Due time") {
                    Toggle("Set a due time", isOn: $hasDueTime.animation())
                    if hasDueTime {
                        DatePicker(
                            "Time",
                            selection: $dueTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // ── Delete (edit mode only) ────────────────────────────────
                if isEditing {
                    Section {
                        Button("Delete Task", role: .destructive) {
                            showDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            emoji,
                            groupName.trimmingCharacters(in: .whitespaces),
                            hasDueTime,
                            dueTime
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .bold()
                }
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(selected: $emoji)
            }
            .alert("Delete \"\(name)\"?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { deleteTask() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the task and all its history.")
            }
        }
        .onAppear {
            if let t = task {
                name = t.name
                emoji = t.emoji
                groupName = t.groupName
                hasDueTime = t.hasDueTime
                dueTime = t.dueTime
            }
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    @ViewBuilder
    private func groupChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func deleteTask() {
        guard let t = task else { return }
        // Delete all completion records for this task.
        let taskID = t.id
        let descriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { $0.taskID == taskID }
        )
        if let orphans = try? modelContext.fetch(descriptor) {
            orphans.forEach { modelContext.delete($0) }
        }
        modelContext.delete(t)
        dismiss()
    }
}
