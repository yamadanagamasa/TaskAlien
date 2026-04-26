import SwiftUI

struct DiaryView: View {
    @ObservedObject var viewModel: StudyAppViewModel
    @State private var isEditorPresented = false

    var body: some View {
        AppScreen(title: "Diary") {
            VStack(alignment: .leading, spacing: 18) {
                DatePicker("日付", selection: $viewModel.selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)

                taskSummaryCard

                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.selectedDateLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.secondaryInk)

                    if viewModel.selectedDiaryText.isEmpty {
                        Text("まだ日記はありません。")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.secondaryInk)
                    } else {
                        Text(viewModel.selectedDiaryText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.primaryInk)
                    }
                }

                HStack(spacing: 12) {
                    Button(viewModel.selectedDiaryText.isEmpty ? "追加" : "編集") {
                        isEditorPresented = true
                    }
                    .buttonStyle(PrimaryActionButton())

                    if !viewModel.selectedDiaryText.isEmpty {
                        Button("削除") {
                            viewModel.deleteDiaryForSelectedDate()
                        }
                        .buttonStyle(SecondaryActionButton())
                    }
                }
            }
            .appCardStyle(radius: 34)
        }
        .onChange(of: viewModel.selectedDate) { _, newDate in
            viewModel.loadDiary(for: newDate)
        }
        .sheet(isPresented: $isEditorPresented) {
            DiaryEditorSheet(
                date: viewModel.selectedDate,
                text: viewModel.selectedDiaryText
            ) { text in
                viewModel.selectedDiaryText = text
                viewModel.saveDiaryForSelectedDate()
            }
        }
    }

    private var taskSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("その日のタスク記録")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.primaryInk)

            if viewModel.selectedDateTaskSummaries.isEmpty {
                Text("まだタイマー記録はありません。")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.secondaryInk)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.selectedDateTaskSummaries) { summary in
                        HStack {
                            Text(summary.task)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.primaryInk)
                            Spacer()
                            Text("\(summary.minutes)分")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.primaryInk)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .appCardStyle(radius: 28)
    }
}

private struct DiaryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    @State var text: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(date.formatted(.dateTime.year().month().day())) {
                    TextField("日記を書く", text: $text, axis: .vertical)
                        .lineLimit(8...14)
                }
            }
            .navigationTitle("Diary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(text)
                        dismiss()
                    }
                }
            }
        }
    }
}
