import SwiftUI
import SwiftData

struct AppEntryView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var vm: QuestionnaireViewModel
    
    @State private var shouldShowDashboard = false
    @State private var checked = false
    
    var body: some View {
        Group {
            if checked {
                if shouldShowDashboard {
                    BudgetDashboardView()
                } else {
                    BudgetFlowView()
                }
            } else {
                ProgressView("Chargement…")
            }
        }
        .task {
            await checkBudgetEntries()
        }
    }
    
    private func checkBudgetEntries() async {
        let monthKey = monthKey(for: Date())
        let fetchDescriptor = FetchDescriptor<BudgetEntryOccurrence>(
            predicate: #Predicate { $0.monthKey == monthKey }
        )
        
        do {
            let entries = try modelContext.fetch(fetchDescriptor)
            shouldShowDashboard = !entries.isEmpty
        } catch {
            shouldShowDashboard = false
        }
        checked = true
    }
    
    private func monthKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else { return "" }
        return String(format: "%04d-%02d", year, month)
    }
}

#Preview {
    AppEntryView()
        .modelContainer(DataController.preview.modelContainer)
        .environmentObject(QuestionnaireViewModel())
}
