import SwiftUI

struct TodoView: View {
    @ObservedObject var viewModel: StudyAppViewModel
    @State private var isAddSheetPresented = false

    var body: some View {
        AppScreen(title: "Todo List") {
            HStack {
                Text("")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.secondaryInk)
                Spacer()
                Button("追加") {
                    isAddSheetPresented = true
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.primaryInk)
            }

            taskListCard
        }
        .sheet(isPresented: $isAddSheetPresented) {
            TodoInputSheet { title in
                viewModel.addTodoItem(title: title)
            }
        }
    }

    private var taskListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.todoItems.isEmpty {
                Text("Todo はまだありません。")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 22)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.todoItems) { item in
                        TodoRow(
                            item: item,
                            onUseForTimer: { viewModel.setCurrentTask(title: item.title) },
                            onToggle: { viewModel.toggleTodoItem(itemID: item.id) },
                            onDelete: { viewModel.deleteTodoItem(itemID: item.id) }
                        )
                    }
                }
            }
        }
        .appCardStyle(radius: 34)
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let onUseForTimer: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var TaskSetAlert = false
    var body: some View {
        
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(item.isCompleted ? Color.primaryInk : Color.secondaryInk)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.primaryInk.opacity(item.isCompleted ? 0.45 : 1))
                        .strikethrough(item.isCompleted)

                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.secondaryInk)
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.secondaryInk)
                }
            }

            HStack(spacing: 10) {
                Button("このタスクを使う") {
                    onUseForTimer()
                    TaskSetAlert = true
                }
                .buttonStyle(SecondaryActionButton())
                .alert("", isPresented: $TaskSetAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("タスクがセットされました")
                        }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primaryInk.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct TodoInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Todo") {
                    TextField("タイトル", text: $title)
                }
            }
            .navigationTitle("Todo を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(title)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
