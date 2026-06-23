import SwiftUI

struct EmojiPickerView: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    // A broad but hand-curated set covering health, work, hobbies, and home.
    private let emojis: [[String]] = [
        // Health & body
        ["💪", "🧘", "🏃", "🚴", "🏋️", "🤸", "🧗", "🏊", "🛌", "💊", "💧", "🥗"],
        // Mind & learning
        ["🧠", "📚", "✏️", "📝", "💻", "📖", "🎓", "🔬", "🗒️", "📊", "📈", "🧩"],
        // Food & drink
        ["🍎", "☕️", "🫖", "🥤", "🍳", "🥗", "🍱", "🍇", "🥑", "🥦", "🫐", "🍌"],
        // Home & chores
        ["🏡", "🧹", "🛁", "🚿", "🧺", "🛏️", "🪴", "🌱", "🐕", "🐈", "🧴", "🪟"],
        // Work & money
        ["💰", "📬", "📱", "🤝", "🗓️", "⏰", "🔔", "📦", "🔑", "📋", "✅", "🎯"],
        // Fun & creativity
        ["🎵", "🎨", "🎮", "🎲", "🎉", "⭐️", "🔥", "🌅", "🌙", "🌊", "🏔️", "✈️"],
    ]

    @State private var searchText = ""

    private var allEmojis: [String] { emojis.flatMap { $0 } }
    private var filtered: [String] {
        // Simple search: include all until the user types something specific.
        // This picker doesn't have emoji names so just return all when non-empty.
        allEmojis
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filtered, id: \.self) { e in
                        Button {
                            selected = e
                            dismiss()
                        } label: {
                            Text(e)
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    selected == e
                                        ? Color.accentColor.opacity(0.2)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            selected == e ? Color.accentColor : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
