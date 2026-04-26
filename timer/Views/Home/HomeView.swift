import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: StudyAppViewModel
    @State private var isManualRecordSheetPresented = false

    var body: some View {
        AppScreen(title: "") {
            topActionBar
            timerHeroCard
            focusInputCard
            actionGuideCard
            smallSummaryRow
        }
        .sheet(isPresented: $isManualRecordSheetPresented) {
            ManualRecordSheet(
                date: viewModel.manualRecordDate,
                minutes: viewModel.manualRecordMinutes,
                task: viewModel.manualRecordTask
            ) { date, minutes, task in
                viewModel.manualRecordDate = date
                viewModel.manualRecordMinutes = minutes
                viewModel.manualRecordTask = task
                viewModel.addManualRecord()
            }
        }
    }

    private var topActionBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Timer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.secondaryInk)

                if viewModel.currentPhase == .study {
                    Text(viewModel.currentTask.isEmpty ? "先にタスク内容を書いてから Start" : viewModel.currentTask)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primaryInk)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                viewModel.stopTimer()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.primaryInk)
                    .frame(width: 46, height: 46)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primaryInk.opacity(0.08), lineWidth: 1))
            }
            .disabled(!viewModel.isRunning && viewModel.currentPhase == .study && viewModel.remainingSeconds == viewModel.settings.studyMinutes * 60)
        }
    }

    private var timerHeroCard: some View {
        VStack(spacing: 26) {
            Text(viewModel.currentPhase == .study ? "いまのモード: Task" : "いまのモード: Break")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.secondaryInk)

            Text(viewModel.formattedTime)
                .font(.system(size: 74, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.primaryInk)
                .frame(maxWidth: .infinity, alignment: .center)

            ProgressView(value: viewModel.phaseProgress)
                .tint(Color.primaryInk)
                .frame(maxWidth: .infinity)

            Text(viewModel.currentPhase.subtitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.secondaryInk)
                .multilineTextAlignment(.center)

            if viewModel.currentPhase == .study && viewModel.currentTask.isEmpty {
                Text("タスクを入力してからスタート！")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.secondaryInk)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 18) {
                iconActionButton(
                    icon: "arrow.counterclockwise",
                    title: "Reset",
                    fill: Color.cardBackground,
                    foreground: Color.primaryInk
                ) {
                    viewModel.resetTimer()
                }

                iconActionButton(
                    icon: viewModel.isRunning ? "pause.fill" : "play.fill",
                    title: viewModel.isRunning ? "Pause" : "Start",
                    fill: Color.primaryInk,
                    foreground: Color.accentInk
                ) {
                    viewModel.toggleTimer()
                }
                .opacity(viewModel.canStartStudyTimer ? 1 : 0.55)
            }
        }
        .padding(.vertical, 44)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(Color.primaryInk.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.primaryInk.opacity(0.05), radius: 12, x: 0, y: 7)
    }

    private var focusInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "今やるタスク")
            TextField("Task title", text: $viewModel.currentTask)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .textFieldStyle(AppInputFieldStyle())

            HStack(spacing: 12) {
                Button("記録を手入力") {
                    isManualRecordSheetPresented = true
                }
                .buttonStyle(SecondaryActionButton())

                Button("入力をクリア") {
                    viewModel.currentTask = ""
                }
                .buttonStyle(SecondaryActionButton())
            }
            
            Text("ここに書いた内容が、タイマー終了時や Stop 時に記録されます。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.secondaryInk)

        }
        .appCardStyle(radius: 30)
    }

    private var actionGuideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "使い方")

            VStack(alignment: .leading, spacing: 10) {
                guideRow(index: "1", text: "タスク内容を書く")
                guideRow(index: "2", text: "Start でタイマー開始")
                guideRow(index: "3", text: "終了または Stop で自動記録")
            }
        }
        .appCardStyle(radius: 30)
    }

    private var smallSummaryRow: some View {
        HStack(spacing: 14) {
            MiniMetricCard(
                icon: "clock.badge.checkmark",
                title: "Today",
                value: "\(viewModel.totalRecordedMinutesToday) min"
            )

            MiniMetricCard(
                icon: "bolt.badge.clock",
                title: "Sessions",
                value: "\(viewModel.timerSessionCountToday)"
            )
        }
    }

    private func iconActionButton(
        icon: String,
        title: String,
        fill: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(width: 68, height: 68)
                    .background(fill)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.primaryInk.opacity(fill == Color.cardBackground ? 0.08 : 0), lineWidth: 1)
                    )

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primaryInk)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func guideRow(index: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(index)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.accentInk)
                .frame(width: 24, height: 24)
                .background(Color.primaryInk)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.primaryInk)
        }
    }
}

private struct ManualRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var date: Date
    @State var minutes: Int
    @State var task: String
    let onSave: (Date, Int, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Record") {
                    DatePicker("日時", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("タスク内容", text: $task)
                    HStack{
                        Text("タスク時間")
                        Spacer()
                        Picker("分", selection: $minutes) {
                            ForEach(0..<1000) { minute in
                                Text("\(minute)分")
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                }
            }
            .navigationTitle("記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(date, max(1, minutes), task)
                        dismiss()
                    }
                }
            }
        }
    }
}
