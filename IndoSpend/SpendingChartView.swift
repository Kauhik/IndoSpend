import SwiftUI
import Charts
import SwiftData

struct SpendingChartView: View {
    var selectedCurrency: Currency
    // Dynamically fetch expenses.
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)]) private var expenses: [Expense]
    @State private var selectedDataPoint: DailySpending?
    @State private var plotWidth: CGFloat = 0
    
    var body: some View {
        let filteredExpenses = expenses.filter { $0.currency == selectedCurrency }
        let dailyData = aggregateExpensesByDay(expenses: filteredExpenses)
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spending Overview")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(selectedCurrency.rawValue) Expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !dailyData.isEmpty {
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(totalSpending(data: dailyData), specifier: "%.2f") \(selectedCurrency.rawValue)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Average/Day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(averageSpending(data: dailyData), specifier: "%.2f") \(selectedCurrency.rawValue)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Chart section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Spending")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    if dailyData.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(Color.gray.opacity(0.3))
                            
                            Text("No expenses to display")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("Add some expenses to see your spending chart")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .background(Color(.systemBackground).opacity(0.7))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            // Selected data point info
                            if let selected = selectedDataPoint {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selected.date, format: .dateTime.day().month())
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Total: \(selected.total, specifier: "%.2f") \(selectedCurrency.rawValue)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedDataPoint = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                .padding(.horizontal)
                                .transition(.opacity)
                            }
                            
                            // Chart
                            Chart {
                                ForEach(dailyData, id: \.date) { data in
                                    BarMark(
                                        x: .value("Date", data.date, unit: .day),
                                        y: .value("Total", data.total)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(6)
                                    .annotation(position: .top) {
                                        if selectedDataPoint?.date == data.date {
                                            Text("\(data.total, specifier: "%.0f")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                if let selected = selectedDataPoint {
                                    RuleMark(
                                        x: .value("Selected", selected.date, unit: .day)
                                    )
                                    .foregroundStyle(Color.gray.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                                    AxisValueLabel(format: .dateTime.day().month())
                                        .font(.caption)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                                        .foregroundStyle(Color.gray.opacity(0.3))
                                    AxisValueLabel()
                                        .font(.caption)
                                }
                            }
                            .frame(height: 250)
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    let x = value.location.x
                                                    if let date = proxy.value(atX: x) as Date? {
                                                        if let closest = findClosestDataPoint(date: date, data: dailyData) {
                                                            selectedDataPoint = closest
                                                        }
                                                    }
                                                }
                                        )
                                        .onTapGesture { location in
                                            let x = location.x
                                            if let date = proxy.value(atX: x) as Date? {
                                                if let closest = findClosestDataPoint(date: date, data: dailyData) {
                                                    selectedDataPoint = closest
                                                }
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Legend
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 10, height: 10)
                                
                                Text("Daily Spending")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Tap on chart to see details")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground).opacity(0.7))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                
                // Spending breakdown
                if !dailyData.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending Breakdown")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(dailyData.prefix(5)), id: \.date) { data in
                                HStack {
                                    Text(data.date, format: .dateTime.day().month().weekday())
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(data.total, specifier: "%.2f") \(selectedCurrency.rawValue)")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground).opacity(0.7))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .background(backgroundColor())
        .navigationTitle("Spending Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Aggregate expenses by day.
    func aggregateExpensesByDay(expenses: [Expense]) -> [DailySpending] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        let dailyData = grouped.map { (key, expenses) in
            DailySpending(date: key, total: expenses.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.date < $1.date }
        return dailyData
    }
    
    // Find the closest data point to a given date
    private func findClosestDataPoint(date: Date, data: [DailySpending]) -> DailySpending? {
        let calendar = Calendar.current
        return data.min(by: {
            abs(calendar.dateComponents([.day], from: $0.date, to: date).day ?? 0) <
            abs(calendar.dateComponents([.day], from: $1.date, to: date).day ?? 0)
        })
    }
    
    // Calculate total spending
    private func totalSpending(data: [DailySpending]) -> Double {
        data.reduce(0) { $0 + $1.total }
    }
    
    // Calculate average daily spending
    private func averageSpending(data: [DailySpending]) -> Double {
        data.isEmpty ? 0 : totalSpending(data: data) / Double(data.count)
    }
    
    // Background color based on spending trend
    private func backgroundColor() -> Color {
        let data = aggregateExpensesByDay(expenses: expenses.filter { $0.currency == selectedCurrency })
        
        if data.count < 2 {
            return Color(.systemGroupedBackground)
        }
        
        // Check if spending is increasing or decreasing
        let sortedData = data.sorted { $0.date < $1.date }
        if let first = sortedData.first?.total, let last = sortedData.last?.total {
            if last > first {
                // Spending is increasing - light red background
                return Color.red.opacity(0.1)
            } else if last < first {
                // Spending is decreasing - light green background
                return Color.green.opacity(0.1)
            }
        }
        
        return Color(.systemGroupedBackground)
    }
}

struct DailySpending {
    let date: Date
    let total: Double
}

struct SpendingChartView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpendingChartView(selectedCurrency: .SGD)
        }
    }
}

