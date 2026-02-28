import SwiftUI
import SwiftData
import UIKit

struct CategorySelectionView: View {
    @Binding var selectedMainCategory: MainCategory?
    @Binding var selectedSubCategory: SubCategory?
    let mainCategories: [MainCategory]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Catégorie")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(mainCategories.sorted { $0.order < $1.order }) { category in
                    CategoryButton(
                        icon: category.icon,
                        displayName: category.displayName,
                        color: Color(hex: category.color) ?? .blue,
                        isSelected: selectedMainCategory?.id == category.id,
                        action: {
                            selectedMainCategory = category
                            selectedSubCategory = category.subCategories.first
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    let icon: String
    let displayName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            action()
        }) {
            VStack(spacing: 10) {
                Text(icon)
                    .font(.system(size: 28))
                
                Text(displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
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
                            colors: [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .foregroundColor(isSelected ? .white : .black)
        }
    }
}

#Preview {
    @State var selectedMain: MainCategory?
    @State var selectedSub: SubCategory?
    
    let mockCategory = MainCategory(
        name: "housing",
        displayName: "Logement",
        icon: "🏠",
        color: "#FF6B6B",
        categoryType: "expense",
        order: 1
    )
    
    return CategorySelectionView(
        selectedMainCategory: $selectedMain,
        selectedSubCategory: $selectedSub,
        mainCategories: [mockCategory]
    )
}
