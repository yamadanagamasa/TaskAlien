import SwiftUI

struct SettingsMenuView: View {
    @ObservedObject var viewModel: StudyAppViewModel
    @State private var isResetRecordsAlertPresented = false

    private var studyMinutesBinding: Binding<Int> {
        Binding(
            get: { viewModel.settings.studyMinutes },
            set: { viewModel.updateStudyMinutes($0) }
        )
    }

    private var breakMinutesBinding: Binding<Int> {
        Binding(
            get: { viewModel.settings.breakMinutes },
            set: { viewModel.updateBreakMinutes($0) }
        )
    }

    var body: some View {
        AppScreen(title: "設定") {
            VStack(alignment: .leading, spacing: 14) {
                Stepper(value: studyMinutesBinding, in: 1...180) {
                    MenuRow(icon: "timer", title: "Study Time", trailing: "\(viewModel.settings.studyMinutes) min")
                }

                Divider()

                Stepper(value: breakMinutesBinding, in: 1...60) {
                    MenuRow(icon: "cup.and.saucer", title: "Break Time", trailing: "\(viewModel.settings.breakMinutes) min")
                }
            }
            .appCardStyle(radius: 34)

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: "データ")

                Text("学習記録（タスク: 何分 の集計）をすべて削除します。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondaryInk)

                Button {
                    isResetRecordsAlertPresented = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("記録をリセット")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButton())
            }
            .appCardStyle(radius: 34)
        }
        .alert("記録をリセットしますか？", isPresented: $isResetRecordsAlertPresented) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                viewModel.resetStudyRecords()
            }
        } message: {
            Text("この操作は元に戻せません。")
        }
    }
}
