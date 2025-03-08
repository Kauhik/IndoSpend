import SwiftUI
import Charts
import SwiftData

struct SpendingChartView: View {
    var selectedCurrency: Currency
    // Dynamically fetch expenses.
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)]) private var expenses: [Expense]
    
    var body: some View {
        let filteredExpenses = expenses.filter { $0.currency == selectedCurrency }
        let dailyData = aggregateExpensesByDay(expenses: filteredExpenses)
        
        VStack {
            Text("Spending Chart - \(selectedCurrency.rawValue)")
                .font(.headline)
                .padding()
            
            if dailyData.isEmpty {
                Text("No expenses to display")
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(dailyData, id: \.date) { data in
                        BarMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value("Total", data.total)
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Spending Chart")
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
