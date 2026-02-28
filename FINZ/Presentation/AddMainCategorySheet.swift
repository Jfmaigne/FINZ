import SwiftUI
import SwiftData

struct AddMainCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let categoryType: String
    let onSave: (MainCategory) -> Void
    
    @State private var displayName: String = ""
    @State private var icon: String = "📦"
    @State private var color: String = "#4ECDC4"
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Couleurs prédéfinies
    private let colors = [
        ("#FF6B6B", "Rouge"),
        ("#4ECDC4", "Turquoise"),
        ("#FFE66D", "Jaune"),
        ("#95E1D3", "Menthe"),
        ("#FFB3BA", "Rose"),
        ("#A8E6CF", "Vert")
    ]
    
    // Emojis populaires
    private let icons = ["📦", "🏠", "🚗", "🛍️", "📱", "🎉", "📈", "🎓", "🤝", "💼", "💵", "🛒", "✈️", "🎬", "💰"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Nom affiché", text: $displayName)
                }
                
                Section("Apparence") {
                    Picker("Icône", selection: $icon) {
                        ForEach(icons, id: \.self) { emoji in
                            Text("\(emoji) \(emoji)").tag(emoji)
                        }
                    }
                    
                    Picker("Couleur", selection: $color) {
                        ForEach(colors, id: \.0) { hex, colorName in
                            HStack {
                                Circle()
                                    .fill(Color(hex: hex) ?? .blue)
                                    .frame(width: 20, height: 20)
                                Text(colorName)
                            }
                            .tag(hex)
                        }
                    }
                }
                
                Section("Prévisualisation") {
                    HStack {
                        Text(icon)
                            .font(.system(size: 32))
                        VStack(alignment: .leading) {
                            Text(displayName.isEmpty ? "Nom affiché" : displayName)
                                .font(.headline)
                        }
                        Spacer()
                        Circle()
                            .fill(Color(hex: color) ?? .blue)
                            .frame(width: 30, height: 30)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Nouvelle Catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        save()
                    }
                    .disabled(displayName.isEmpty)
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Une erreur est survenue")
            }
        }
    }
    
    private func save() {
        let generatedName = displayName.slugified
        
        // Vérifier l'unicité du code interne
        let fetchDescriptor = FetchDescriptor<MainCategory>(
            predicate: #Predicate { $0.name == generatedName && $0.categoryType == categoryType }
        )
        
        do {
            let existing = try modelContext.fetch(fetchDescriptor)
            if !existing.isEmpty {
                errorMessage = "Une catégorie avec ce nom existe déjà"
                showError = true
                return
            }
            
            // Récupérer le nombre de catégories pour définir l'ordre
            let allFetch = FetchDescriptor<MainCategory>(
                predicate: #Predicate { $0.categoryType == categoryType }
            )
            let allCount = try modelContext.fetch(allFetch).count
            
            let newCategory = MainCategory(
                name: generatedName,
                displayName: displayName,
                icon: icon,
                color: color,
                categoryType: categoryType,
                order: allCount + 1
            )
            
            onSave(newCategory)
            dismiss()
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6 else { return nil }
        
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        
        guard scanner.scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    AddMainCategorySheet(
        categoryType: "expense",
        onSave: { _ in }
    )
        .modelContainer(DataController.preview.modelContainer)
}
