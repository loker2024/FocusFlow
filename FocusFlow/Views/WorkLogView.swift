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
        VStack(spacing: 30) {
            // 标题
            HStack {
                Text("工作日志")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showHistory.toggle() }) {
                    Image(systemName: "calendar")
                        .font(.title2)
                }
                .popover(isPresented: $showHistory) {
                    WorkLogHistoryView()
                        .frame(width: 500, height: 600)
                }
            }
            
            // 日期选择
            HStack {
                DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Spacer()
                
                Text(selectedDate, style: .date)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // 心情选择
            VStack(alignment: .leading, spacing: 10) {
                Text("今日心情")
                    .font(.headline)
                
                HStack {
                    ForEach(moods, id: \.self) { mood in
                        Button(action: { selectedMood = mood }) {
                            Text(mood)
                                .font(.system(size: 32))
                                .padding(8)
                                .background(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // 生产力评分
            VStack(alignment: .leading, spacing: 10) {
                Text("生产力评分")
                    .font(.headline)
                
                HStack {
                    ForEach(1...5, id: \.self) { rating in
                        Button(action: { productivity = rating }) {
                            Image(systemName: rating <= productivity ? "star.fill" : "star")
                                .font(.title)
                                .foregroundColor(.yellow)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("(\(productivity)/5)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.leading, 10)
                }
            }
            
            // 日志内容
            VStack(alignment: .leading, spacing: 10) {
                Text("今日记录")
                    .font(.headline)
                
                TextEditor(text: $logContent)
                    .frame(height: 200)
                    .border(Color.gray.opacity(0.3))
                    .font(.body)
            }
            
            // 保存按钮
            HStack {
                Spacer()
                
                Button(action: saveLog) {
                    Label("保存日志", systemImage: "square.and.arrow.down")
                        .font(.title2)
                        .frame(width: 150, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(logContent.isEmpty)
            }
        }
        .padding(40)
    }
    
    private func saveLog() {
        let log = WorkLog(
            date: selectedDate,
            content: logContent,
            mood: selectedMood,
            productivity: productivity
        )
        dataStore.addWorkLog(log)
        
        // 重置
        logContent = ""
        selectedMood = "😊"
        productivity = 3
        
        // 显示提示
        NSSound.beep()
    }
}

struct WorkLogHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack {
            Text("日志历史")
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
        }
    }
}

