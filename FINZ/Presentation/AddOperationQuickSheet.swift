import SwiftUI
import CoreData
import UIKit

private enum OperationKind: String, CaseIterable {
    case income, expense
    var label: String { self == .income ? "Recette" : "Dépense" }
    var color: Color { self == .income ? .green : .red }
    var icon: String { self == .income ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill" }
}

private enum FormattersQuickSheet {
    static let monthSymbolsFR: [String] = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr")
        return df.monthSymbols ?? (1...12).map { "Mois \($0)" }
    }()
}

// Buffer class that does NOT publish changes to SwiftUI, avoiding re-render on each keystroke
private final class AmountBuffer { var text: String = "" }

// Ultra-fast numeric field using UITextField that writes into AmountBuffer without causing SwiftUI updates
private struct NumericPadField: UIViewRepresentable {
    let placeholder: String
    @Binding var isFirstResponder: Bool
    var buffer: AmountBuffer

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NumericPadField
        init(_ parent: NumericPadField) { self.parent = parent }
        @objc func editingChanged(_ textField: UITextField) {
            // Keep only digits for stability
            let filtered = (textField.text ?? "").filter { $0.isNumber }
            if filtered != textField.text { textField.text = filtered }
            parent.buffer.text = filtered
        }
        @objc func doneTapped() {
            parent.isFirstResponder = false
        }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder(); parent.isFirstResponder = false; return true
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.keyboardType = .numberPad
        tf.placeholder = placeholder
        tf.textAlignment = .center // Centré
        tf.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        tf.adjustsFontSizeToFitWidth = false
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        tf.delegate = context.coordinator
        // Input accessory toolbar for number pad
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Terminer", style: .done, target: context.coordinator, action: #selector(Coordinator.doneTapped))
        toolbar.items = [flex, done]
        tf.inputAccessoryView = toolbar
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Do not set text from buffer on every update to avoid flicker; the field owns its text while editing
        if isFirstResponder && !uiView.isFirstResponder { uiView.becomeFirstResponder() }
        if !isFirstResponder && uiView.isFirstResponder { uiView.resignFirstResponder() }
    }
}

struct AddOperationQuickSheet: View {
    @Environment(\.managedObjectContext) private var context

    let defaultDate: Date
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var kind: OperationKind = .expense
    @State private var amountFirstResponder: Bool = false
    @State private var amountBuffer = AmountBuffer()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    @State private var selectedCategory: String = ""
    @State private var descriptionText: String = ""
    @State private var error: String? = nil

    private let categoriesIncome = ["Salaire", "Bourse", "Prime", "Remboursement"]
    private let categoriesExpense = ["Courses", "Essence", "Sortie", "Abonnement", "Loyer", "Électricité"]

    init(defaultDate: Date = Date(), onSaved: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.defaultDate = defaultDate
        self.onSaved = onSaved
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 12) {
            // Close button at top-left corner, top-aligned
            HStack {
                Button(action: { onCancel() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 2)

            HStack {
                Spacer()
                Image("finz_logo_couleur")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 110)
                    .accessibilityLabel("Finz")
                Spacer()
            }
            .padding(.top, 0)

            // Main content cards in single VStack
            VStack(spacing: 6) {
                amountCard
                    .frame(maxWidth: .infinity)
                categoryWheelPicker
                    .frame(maxWidth: .infinity)
                dateWheelPickers
                    .frame(maxWidth: .infinity)
                descriptionCard
                    .frame(maxWidth: .infinity)
                actionButtons
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: 400, alignment: .center)
            .padding(.horizontal, 0)

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.resizes)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            kind = .expense
            configureDefaults()
            amountFirstResponder = true
        }
    }

    // MARK: - Cards

    private var amountCard: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack { Spacer(); Text("Montant").font(.headline); Spacer() }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Spacer()
                NumericPadField(placeholder: "0", isFirstResponder: $amountFirstResponder, buffer: amountBuffer)
                    .frame(height: 42)
                Text("€").font(.headline).foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .background(cardBackground)
        .overlay(cardStroke)
    }

    private var dateWheelPickers: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                DatePicker("", selection: Binding(get: {
                    var comps = DateComponents(); comps.year = selectedYear; comps.month = selectedMonth; comps.day = selectedDay
                    return Calendar.current.date(from: comps) ?? defaultDate
                }, set: { newDate in
                    let cal = Calendar.current
                    selectedYear = cal.component(.year, from: newDate)
                    selectedMonth = cal.component(.month, from: newDate)
                    selectedDay = cal.component(.day, from: newDate)
                }), displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .background(cardBackground)
        .overlay(cardStroke)
    }

    private var categoryWheelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Picker("Catégorie", selection: $selectedCategory) {
                    ForEach(categoriesExpense, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .background(cardBackground)
        .overlay(cardStroke)
        .onChange(of: kind) { _ in selectedCategory = categoriesExpense.first ?? "" }
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("commentaire, détail", text: $descriptionText)
                .textInputAutocapitalization(.sentences)
        }
        .padding(.vertical, 12)
        .background(cardBackground)
        .overlay(cardStroke)
    }

    private var actionButtons: some View {
        Button(action: save) {
            HStack { Spacer(); Text("Enregistrer la dépense").font(.headline); Spacer() }
                .padding(.vertical, 10)
                .background(
                    LinearGradient(colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Helpers
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground))
    }
    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1)
    }

    private func maxDay(in month: Int, year: Int) -> Int {
        var comps = DateComponents(); comps.year = year; comps.month = month; comps.day = 1
        let cal = Calendar.current
        if let date = cal.date(from: comps), let range = cal.range(of: .day, in: .month, for: date) { return range.count }
        return 31
    }

    private func configureDefaults() {
        kind = .expense
        let cal = Calendar.current
        selectedYear = cal.component(.year, from: defaultDate)
        selectedMonth = cal.component(.month, from: defaultDate)
        selectedDay = cal.component(.day, from: Date())
        selectedCategory = categoriesExpense.first ?? ""
    }

    private func save() {
        error = nil
        let amount = Double(amountBuffer.text) ?? 0
        guard amount > 0 else { error = "Montant invalide"; return }
        guard !selectedCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = "Catégorie requise"; return }
        let clampedDay = min(max(1, selectedDay), maxDay(in: selectedMonth, year: selectedYear))

        var comps = DateComponents(); comps.year = selectedYear; comps.month = selectedMonth; comps.day = clampedDay
        guard let date = Calendar.current.date(from: comps) else { error = "Date invalide"; return }

        guard let entity = NSEntityDescription.entity(forEntityName: "BudgetEntryOccurrence", in: context) else { error = "Entité introuvable"; return }
        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(UUID(), forKey: "id")
        obj.setValue(date, forKey: "date")
        obj.setValue(-amount, forKey: "amount")
        obj.setValue(kind.rawValue, forKey: "kind")
        obj.setValue(selectedCategory + (descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : " — " + descriptionText), forKey: "title")
        obj.setValue(true, forKey: "isManual")
        obj.setValue(BudgetProjectionManager.monthKey(for: date), forKey: "monthKey")

        do { try context.save(); onSaved(); onCancel() } catch { self.error = "Échec de l’enregistrement: \(error.localizedDescription)" }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var show = true
        var body: some View {
            Text("Preview")
                .sheet(isPresented: $show) {
                    AddOperationQuickSheet(defaultDate: Date(), onSaved: { }, onCancel: { print("Preview Cancel") })
                        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                }
        }
    }
    return PreviewWrapper()
}

