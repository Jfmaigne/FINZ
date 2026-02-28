import SwiftUI
import SwiftData

struct EditSubCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var subCategory: SubCategory
    let onSave: (SubCategory) -> Void
    
    @State private var displayName: String = ""
    @State private var icon: String = "📦"
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Emojis populaires
    private let icons = ["📦", "🏠", "🚗", "🛍️", "📱", "🎉", "📈", "🎓", "🤝", "💼", "💵", "🛒", "✈️", "🎬", "💰", "🔧", "⛽", "🍽️", "🎵", "🎬", "🏢", "💻", "📚", "💎", "📋", "👕", "👔", "👞", "👜", "💡", "🔥", "💧", "🛡️", "🌟", "⭐"]
    
    var body: some View {
        NavigationStack {
            Form {
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
            .navigationTitle("Modifier Sous-Catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
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
        .onAppear {
            displayName = subCategory.displayName
            icon = subCategory.icon
        }
    }
    
    private func save() {
        subCategory.displayName = displayName
        subCategory.icon = icon
        
        do {
            try modelContext.save()
            onSave(subCategory)
            dismiss()
        } catch {
            errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
            showError = true
        }
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
    
    let subCat = SubCategory(
        name: "rent",
        displayName: "Loyer + charges",
        icon: "🚪",
        order: 1
    )
    
    return EditSubCategorySheet(
        subCategory: subCat,
        onSave: { _ in }
    )
    .modelContainer(container)
}
