import SwiftUI
import SwiftData

struct AddSubCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let mainCategory: MainCategory
    let onSave: (SubCategory) -> Void
    
    @State private var displayName: String = ""
    @State private var icon: String = "📦"
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Emojis populaires
    private let icons = ["📦", "🏠", "🚗", "🛍️", "📱", "🎉", "📈", "🎓", "🤝", "💼", "💵", "🛒", "✈️", "🎬", "💰", "🔧", "⛽", "🍽️", "🎵", "🏢", "💻", "📚", "💎", "📋", "👕", "👔", "👞", "👜", "💡", "🔥", "💧", "🛡️", "🌟", "⭐"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Catégorie Parente") {
                    HStack {
                        Text(mainCategory.icon)
                            .font(.system(size: 24))
                        VStack(alignment: .leading) {
                            Text(mainCategory.displayName)
                                .font(.headline)
                        }
                    }
                }
                
                Section("Informations") {
                    TextField("Nom affiché", text: $displayName)
                }
                
                Section("Icône") {
                    Picker("Icône", selection: $icon) {
                        ForEach(icons, id: \.self) { emoji in
                            Text("\(emoji) \(emoji)").tag(emoji)
                        }
                    }
                }
                
                Section("Prévisualisation") {
                    HStack {
                        Text(icon)
                            .font(.system(size: 28))
                        VStack(alignment: .leading) {
                            Text(displayName.isEmpty ? "Nom affiché" : displayName)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Nouvelle Sous-Catégorie")
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
        
        // Vérifier l'unicité du code interne dans cette catégorie
        let duplicate = mainCategory.subCategories.contains { $0.name == generatedName }
        
        if duplicate {
            errorMessage = "Une sous-catégorie avec ce nom existe déjà"
            showError = true
            return
        }
        
        let newSubCategory = SubCategory(
            name: generatedName,
            displayName: displayName,
            icon: icon,
            order: mainCategory.subCategories.count + 1
        )
        
        newSubCategory.mainCategory = mainCategory
        
        onSave(newSubCategory)
        dismiss()
    }
}

#Preview {
    let container = DataController.preview.modelContainer
    let context = ModelContext(container)
    
    let mainCat = MainCategory(
        name: "housing",
        displayName: "Logement",
        icon: "🏠",
        color: "#FF6B6B",
        categoryType: "expense",
        order: 1
    )
    
    return AddSubCategorySheet(
        mainCategory: mainCat,
        onSave: { _ in }
    )
    .modelContainer(container)
}
