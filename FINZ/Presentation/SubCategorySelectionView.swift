import SwiftUI
import SwiftData
import UIKit

struct SubCategorySelectionView: View {
    @Binding var selectedSubCategory: SubCategory?
    let mainCategory: MainCategory?
    
    var subCategories: [SubCategory] {
        mainCategory?.subCategories.sorted { $0.order < $1.order } ?? []
    }
    
    var body: some View {
        if !subCategories.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sous-catégorie")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(subCategories, id: \.id) { subCat in
                        SubCategoryPillButton(
                            icon: subCat.icon,
                            displayName: subCat.displayName,
                            isSelected: selectedSubCategory?.id == subCat.id,
                            action: {
                                selectedSubCategory = subCat
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SubCategoryPillButton: View {
    let icon: String
    let displayName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            action()
        }) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 16))
                
                Text(displayName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [
                                Color(red: 0.52, green: 0.21, blue: 0.93),
                                Color(red: 1.00, green: 0.29, blue: 0.63)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color(UIColor.secondarySystemBackground), Color(UIColor.secondarySystemBackground)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

#Preview {
    @State var selectedSub: SubCategory?
    
    let mockSubCat = SubCategory(
        name: "rent",
        displayName: "Loyer + charges",
        icon: "🚪",
        order: 1
    )
    
    let mockCategory = MainCategory(
        name: "housing",
        displayName: "Logement",
        icon: "🏠",
        color: "#FF6B6B",
        categoryType: "expense",
        order: 1
    )
    mockCategory.subCategories = [mockSubCat]
    mockSubCat.mainCategory = mockCategory
    
    return SubCategorySelectionView(
        selectedSubCategory: $selectedSub,
        mainCategory: mockCategory
    )
}
