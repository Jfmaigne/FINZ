import SwiftUI
import Foundation

// MARK: - Category Articles Data Model
struct CategoryArticlesEnvelope: Codable {
    let version: String
    let generated_at: String
    let category: CategoryInfo
    let articles: [ArticleItem]
}

struct CategoryInfo: Codable {
    let title: String
    let description: String
    let image: String
    let buttonTitle: String
}

// MARK: - Category Articles Loader
enum CategoryArticlesLoader {
    static func load(fromAsset name: String) -> CategoryArticlesEnvelope? {
        // Try loading from NSDataAsset first
        if let dataAsset = NSDataAsset(name: name) {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(CategoryArticlesEnvelope.self, from: dataAsset.data)
            } catch {
                print("Error decoding category articles from asset '\(name)': \(error)")
            }
        } else {
            print("NSDataAsset not found for: \(name)")
        }
        
        // Fallback: try loading from Bundle
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode(CategoryArticlesEnvelope.self, from: data)
            } catch {
                print("Error loading category articles from bundle: \(error)")
            }
        } else {
            print("Bundle resource not found for: \(name).json")
        }
        
        return nil
    }
}

// MARK: - Category Articles View
struct CategoryArticlesView: View {
    let assetName: String
    
    @State private var envelope: CategoryArticlesEnvelope?
    @State private var showAllArticles = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let envelope = envelope {
                    // Header avec image
                    CategoryHeaderView(
                        category: envelope.category,
                        onButtonTap: {
                            showAllArticles = true
                        }
                    )
                    
                    // Liste des articles
                    VStack(spacing: 12) {
                        ForEach(envelope.articles) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                CategoryArticleRow(article: article)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                } else {
                    ProgressView()
                        .padding(.top, 100)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.purple.opacity(0.04),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            envelope = CategoryArticlesLoader.load(fromAsset: assetName)
        }
    }
}

// MARK: - Category Header View
private struct CategoryHeaderView: View {
    let category: CategoryInfo
    let onButtonTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.15),
                            Color.purple.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                // Image
                if let uiImage = UIImage(named: category.image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                }
                
                // Title
                Text(category.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.85))
                
                // Button
                Button(action: onButtonTap) {
                    Text(category.buttonTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.52, green: 0.21, blue: 0.93),
                                    Color(red: 0.75, green: 0.35, blue: 0.95)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            
            // Heart icon
            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.purple.opacity(0.6))
                .padding(16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Category Article Row
private struct CategoryArticleRow: View {
    let article: ArticleItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Article image
            if let uiImage = loadArticleImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } else {
                // Fallback icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.purple.opacity(0.5))
                }
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(article.excerpt)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
    
    private func loadArticleImage() -> UIImage? {
        // Try to load image based on article slug or tags
        let candidates = [
            article.slug,
            article.slug.replacingOccurrences(of: "-", with: "_"),
            article.tags.first?.lowercased() ?? ""
        ].filter { !$0.isEmpty }
        
        for name in candidates {
            if let image = UIImage(named: name) {
                return image
            }
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        CategoryArticlesView(assetName: "lesbases")
    }
}
