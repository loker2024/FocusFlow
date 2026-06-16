import SwiftUI

struct WorkLogView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var logContent = ""
    @State private var selectedMood = "😊"
    @State private var productivity = 3
    @State private var showHistory = false
    @State private var selectedDate = Date()
    
    let moods = ["😊", "😐", "😔", "😤", "😴", "🎉", "💪", "🤔"]
    
    var body: some View {
        AppPage(
            title: "每日复盘",
            subtitle: "把今天的投入、阻力和收获写下来，让成长留下可回看的证据。",
            icon: "book.closed",
            actionTitle: "复盘历史",
            actionIcon: "calendar",
            action: { showHistory.toggle() }
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 18) {
                        SectionPanel(title: "复盘日期", subtitle: "可以补记，也可以回看某一天。") {
                            HStack {
                                DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                
                                Spacer()
                                
                                Text(selectedDate, style: .date)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        SectionPanel(title: "状态标记", subtitle: "记录状态，不评判自己。") {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    ForEach(moods, id: \.self) { mood in
                                        Button(action: { selectedMood = mood }) {
                                            Text(mood)
                                                .font(.system(size: 27))
                                                .frame(width: 40, height: 40)
                                                .background(selectedMood == mood ? Color.appMutedAccent : Color.clear)
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                HStack(spacing: 8) {
                                    ForEach(1...5, id: \.self) { rating in
                                        Button(action: { productivity = rating }) {
                                            Image(systemName: rating <= productivity ? "star.fill" : "star")
                                                .font(.title2)
                                                .foregroundColor(.yellow)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Text(productivityLabel)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 6)
                                }
                            }
                        }
                    }
                    
                    SectionPanel(title: "今日沉淀", subtitle: "建议写下：完成了什么、卡在哪里、明天先做哪一步。") {
                        PromptTextEditor(
                            text: $logContent,
                            prompt: "今天我推进了……\n遇到的阻力是……\n明天最先启动的一步是……",
                            minHeight: 220
                        )
                    }
                    
                    HStack {
                        Text("复盘不需要完美，真实比漂亮更有用。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: saveLog) {
                            Label("保存复盘", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .frame(width: 148, height: 46)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(logContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .popover(isPresented: $showHistory) {
            WorkLogHistoryView()
                .frame(width: 520, height: 620)
        }
        .onAppear(perform: loadSelectedDateLog)
        .onChange(of: selectedDate) { _, _ in
            loadSelectedDateLog()
        }
    }
    
    private var productivityLabel: String {
        switch productivity {
        case 1: return "低电量，先恢复"
        case 2: return "有阻力，少量推进"
        case 3: return "稳定完成"
        case 4: return "状态不错"
        default: return "高质量投入"
        }
    }
    
    private func saveLog() {
        let trimmedContent = logContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let log = WorkLog(
            date: selectedDate,
            content: trimmedContent,
            mood: selectedMood,
            productivity: productivity
        )
        dataStore.addWorkLog(log)
        
        // 显示提示
        NSSound.beep()
    }
    
    private func loadSelectedDateLog() {
        if let log = dataStore.workLog(for: selectedDate) {
            logContent = log.content
            selectedMood = log.mood
            productivity = log.productivity
        } else {
            logContent = ""
            selectedMood = "😊"
            productivity = 3
        }
    }
}

struct WorkLogHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack {
            Text("复盘历史")
                .font(.headline)
                .padding()
            
            List(dataStore.workLogs.sorted(by: { $0.date > $1.date })) { log in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(log.date, style: .date)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(log.mood)
                            .font(.title)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { rating in
                                Image(systemName: rating <= log.productivity ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Text(log.content)
                        .font(.body)
                        .lineLimit(5)
                }
                .padding(.vertical, 8)
            }
            .overlay {
                if dataStore.workLogs.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "暂无复盘",
                        message: "保存一次每日复盘后，成长痕迹会显示在这里。"
                    )
                }
            }
        }
    }
}
