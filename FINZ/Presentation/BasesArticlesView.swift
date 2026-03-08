import SwiftUI
import UIKit
import Combine
import UserNotifications

// MARK: - Justified Text (UIKit-backed, self-sizing)

private final class SelfSizingTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        let fixedWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 40
        let size = sizeThatFits(CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

private struct JustifiedText: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let lineSpacing: CGFloat

    init(_ text: String, font: UIFont = .preferredFont(forTextStyle: .body), textColor: UIColor = .label, lineSpacing: CGFloat = 6) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.lineSpacing = lineSpacing
    }

    func makeUIView(context: Context) -> SelfSizingTextView {
        let tv = SelfSizingTextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.isSelectable = true
        tv.isUserInteractionEnabled = true
        // Les liens sont gérés via l'attribut .link dans le parser
        // Ne PAS utiliser dataDetectorTypes qui réécrit les attributs du texte
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.backgroundColor = .clear
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.required, for: .vertical)
        tv.linkTextAttributes = [
            .foregroundColor: UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 1),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return tv
    }

    func updateUIView(_ tv: SelfSizingTextView, context: Context) {
        let richText = RichTextParser.parse(
            text,
            baseFont: font,
            baseColor: textColor,
            lineSpacing: lineSpacing
        )
        // Éviter les mises à jour inutiles
        if tv.attributedText?.string != richText.string {
            tv.attributedText = richText
            tv.invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - Rich Text Parser

private enum RichTextParser {
    
    static func parse(
        _ text: String,
        baseFont: UIFont,
        baseColor: UIColor,
        lineSpacing: CGFloat
    ) -> NSAttributedString {
        
        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")
        
        let bodyParagraph = NSMutableParagraphStyle()
        bodyParagraph.alignment = .justified
        bodyParagraph.lineSpacing = lineSpacing
        
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: baseColor,
            .paragraphStyle: bodyParagraph
        ]
        
        // Fonts pré-calculées
        let boldFont = fontWith(base: baseFont, traits: .traitBold)
        let sizes = FontSizes(base: baseFont)
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Ajouter un saut de ligne entre les lignes (sauf avant la première)
            if i > 0 {
                result.append(NSAttributedString(string: "\n", attributes: baseAttrs))
            }
            
            // ─── Séparateur (---) ───
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                let sepParagraph = NSMutableParagraphStyle()
                sepParagraph.alignment = .center
                sepParagraph.paragraphSpacingBefore = 8
                sepParagraph.paragraphSpacing = 8
                let sep = NSAttributedString(string: "───────────────────", attributes: [
                    .font: baseFont,
                    .foregroundColor: UIColor.separator,
                    .paragraphStyle: sepParagraph
                ])
                result.append(sep)
                i += 1
                continue
            }
            
            // ─── Titres (# à ####) ───
            if let headingMatch = trimmed.range(of: #"^(#{1,4})\s+(.+)$"#, options: .regularExpression) {
                let full = String(trimmed[headingMatch])
                let hashCount = full.prefix(while: { $0 == "#" }).count
                let content = String(full.drop(while: { $0 == "#" }).drop(while: { $0 == " " }))
                
                let headingParagraph = NSMutableParagraphStyle()
                headingParagraph.alignment = .natural
                headingParagraph.lineSpacing = 4
                headingParagraph.paragraphSpacingBefore = hashCount == 1 ? 16 : (hashCount == 2 ? 12 : 8)
                headingParagraph.paragraphSpacing = 4
                
                let headingFont = sizes.heading(level: hashCount)
                let headingAttrs: [NSAttributedString.Key: Any] = [
                    .font: headingFont,
                    .foregroundColor: baseColor,
                    .paragraphStyle: headingParagraph
                ]
                result.append(NSAttributedString(string: content, attributes: headingAttrs))
                i += 1
                continue
            }
            
            // ─── Bloc de code (```) ───
            if trimmed.hasPrefix("```") {
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                if i < lines.count { i += 1 } // skip closing ```
                
                let codeText = codeLines.joined(separator: "\n")
                let codeParagraph = NSMutableParagraphStyle()
                codeParagraph.alignment = .natural
                codeParagraph.lineSpacing = 2
                
                let codeFont = UIFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
                let codeAttrs: [NSAttributedString.Key: Any] = [
                    .font: codeFont,
                    .foregroundColor: UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 1),
                    .backgroundColor: UIColor.systemGray6,
                    .paragraphStyle: codeParagraph
                ]
                result.append(NSAttributedString(string: codeText, attributes: codeAttrs))
                continue
            }
            
            // ─── Citation (> texte) ───
            if trimmed.hasPrefix("> ") {
                let content = String(trimmed.dropFirst(2))
                let quoteParagraph = NSMutableParagraphStyle()
                quoteParagraph.alignment = .natural
                quoteParagraph.lineSpacing = lineSpacing
                quoteParagraph.firstLineHeadIndent = 16
                quoteParagraph.headIndent = 16
                quoteParagraph.paragraphSpacingBefore = 4
                quoteParagraph.paragraphSpacing = 4
                
                let quoteAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: baseFont.pointSize),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: quoteParagraph
                ]
                // Barre verticale via un attribut de couleur sur le "│ "
                let barAttrs: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 0.6),
                    .paragraphStyle: quoteParagraph
                ]
                result.append(NSAttributedString(string: "│ ", attributes: barAttrs))
                result.append(parseInlineFormatting(content, baseAttrs: quoteAttrs, baseFont: UIFont.italicSystemFont(ofSize: baseFont.pointSize), baseColor: UIColor.secondaryLabel))
                i += 1
                continue
            }
            
            // ─── Checkbox (- [ ] ou - [x]) ───
            if let cbMatch = trimmed.range(of: #"^- \[([ xX])\]\s+(.+)$"#, options: .regularExpression) {
                let full = String(trimmed[cbMatch])
                let isChecked = full.contains("[x]") || full.contains("[X]")
                let content: String
                if let textStart = full.range(of: "] ") {
                    content = String(full[textStart.upperBound...])
                } else {
                    content = full
                }
                
                let listParagraph = NSMutableParagraphStyle()
                listParagraph.alignment = .natural
                listParagraph.lineSpacing = lineSpacing
                listParagraph.firstLineHeadIndent = 8
                listParagraph.headIndent = 30
                
                let checkbox = isChecked ? "☑ " : "☐ "
                let cbColor = isChecked ? UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1) : UIColor.tertiaryLabel
                result.append(NSAttributedString(string: checkbox, attributes: [
                    .font: baseFont,
                    .foregroundColor: cbColor,
                    .paragraphStyle: listParagraph
                ]))
                
                var contentAttrs = baseAttrs
                contentAttrs[.paragraphStyle] = listParagraph
                if isChecked {
                    contentAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                    contentAttrs[.foregroundColor] = UIColor.tertiaryLabel
                }
                result.append(parseInlineFormatting(content, baseAttrs: contentAttrs, baseFont: baseFont, baseColor: isChecked ? UIColor.tertiaryLabel : baseColor))
                i += 1
                continue
            }
            
            // ─── Liste à puces (- texte) ───
            if trimmed.hasPrefix("- ") && !trimmed.hasPrefix("- [") {
                let content = String(trimmed.dropFirst(2))
                let listParagraph = NSMutableParagraphStyle()
                listParagraph.alignment = .natural
                listParagraph.lineSpacing = lineSpacing
                listParagraph.firstLineHeadIndent = 8
                listParagraph.headIndent = 26
                listParagraph.tabStops = [NSTextTab(textAlignment: .natural, location: 26)]
                
                let bulletAttrs: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 1),
                    .paragraphStyle: listParagraph
                ]
                result.append(NSAttributedString(string: "•  ", attributes: bulletAttrs))
                
                var contentAttrs = baseAttrs
                contentAttrs[.paragraphStyle] = listParagraph
                result.append(parseInlineFormatting(content, baseAttrs: contentAttrs, baseFont: baseFont, baseColor: baseColor))
                i += 1
                continue
            }
            
            // ─── Liste numérotée (1. texte) ───
            if let numMatch = trimmed.range(of: #"^(\d+)\.\s+(.+)$"#, options: .regularExpression) {
                let full = String(trimmed[numMatch])
                let dotIndex = full.firstIndex(of: ".")!
                let number = String(full[full.startIndex..<dotIndex])
                let content = String(full[full.index(dotIndex, offsetBy: 2)...])
                
                let listParagraph = NSMutableParagraphStyle()
                listParagraph.alignment = .natural
                listParagraph.lineSpacing = lineSpacing
                listParagraph.firstLineHeadIndent = 8
                listParagraph.headIndent = 30
                
                let numAttrs: [NSAttributedString.Key: Any] = [
                    .font: boldFont,
                    .foregroundColor: UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 1),
                    .paragraphStyle: listParagraph
                ]
                result.append(NSAttributedString(string: "\(number). ", attributes: numAttrs))
                
                var contentAttrs = baseAttrs
                contentAttrs[.paragraphStyle] = listParagraph
                result.append(parseInlineFormatting(content, baseAttrs: contentAttrs, baseFont: baseFont, baseColor: baseColor))
                i += 1
                continue
            }
            
            // ─── Ligne normale → parser les styles inline ───
            result.append(parseInlineFormatting(trimmed, baseAttrs: baseAttrs, baseFont: baseFont, baseColor: baseColor))
            i += 1
        }
        
        return result
    }
    
    // MARK: - Inline Formatting Parser (récursif pour styles imbriqués)
    
    /// Parse les styles inline avec support de l'imbrication.
    /// Ex: **texte <font color="#FF2D54">coloré</font> en gras** fonctionne.
    private static func parseInlineFormatting(
        _ text: String,
        baseAttrs: [NSAttributedString.Key: Any],
        baseFont: UIFont,
        baseColor: UIColor
    ) -> NSAttributedString {
        
        let codeFont = UIFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
        
        // Regex combinée — ORDRE IMPORTANT : les patterns les plus longs d'abord
        let pattern = [
            #"\*\*\*(.+?)\*\*\*"#,                       // 1: ***bold+italic***
            #"\*\*(.+?)\*\*"#,                            // 2: **bold**
            #"(?<!\*)\*(?!\*)(.+?)\*(?!\*)"#,             // 3: *italic*
            #"~~(.+?)~~"#,                                // 4: ~~strikethrough~~
            #"<u>(.+?)</u>"#,                             // 5: <u>underline</u>
            #"<font\s+color="([^"]+)">(.+?)</font>"#,    // 6+7: <font color>text</font>
            #"`([^`]+)`"#,                                // 8: `code`
            #"!\[([^\]]*)\]\(([^)]+)\)"#,                 // 9+10: ![alt](image url)
            #"\[([^\]]+)\]\(([^)]+)\)"#,                  // 11+12: [text](url)
        ].joined(separator: "|")
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return NSAttributedString(string: text, attributes: baseAttrs)
        }
        
        let result = NSMutableAttributedString()
        let nsText = text as NSString
        var lastEnd = 0
        
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            // Ignorer les matches qui chevauchent un match précédent
            if match.range.location < lastEnd { continue }
            
            // Texte normal avant ce match
            if match.range.location > lastEnd {
                let normalRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                result.append(NSAttributedString(string: nsText.substring(with: normalRange), attributes: baseAttrs))
            }
            
            if match.range(at: 1).location != NSNotFound {
                // ***bold+italic*** → re-parser le contenu interne
                let content = nsText.substring(with: match.range(at: 1))
                let boldItalicFont = fontWith(base: baseFont, traits: [.traitBold, .traitItalic])
                var innerAttrs = baseAttrs
                innerAttrs[.font] = boldItalicFont
                result.append(parseInlineFormatting(content, baseAttrs: innerAttrs, baseFont: boldItalicFont, baseColor: baseColor))
                
            } else if match.range(at: 2).location != NSNotFound {
                // **bold** → re-parser le contenu interne
                let content = nsText.substring(with: match.range(at: 2))
                let boldFont = fontWith(base: baseFont, traits: .traitBold)
                var innerAttrs = baseAttrs
                innerAttrs[.font] = boldFont
                result.append(parseInlineFormatting(content, baseAttrs: innerAttrs, baseFont: boldFont, baseColor: baseColor))
                
            } else if match.range(at: 3).location != NSNotFound {
                // *italic* → re-parser le contenu interne
                let content = nsText.substring(with: match.range(at: 3))
                let italicFont = fontWith(base: baseFont, traits: .traitItalic)
                var innerAttrs = baseAttrs
                innerAttrs[.font] = italicFont
                result.append(parseInlineFormatting(content, baseAttrs: innerAttrs, baseFont: italicFont, baseColor: baseColor))
                
            } else if match.range(at: 4).location != NSNotFound {
                // ~~strikethrough~~ → re-parser le contenu interne
                let content = nsText.substring(with: match.range(at: 4))
                var innerAttrs = baseAttrs
                innerAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                innerAttrs[.strikethroughColor] = baseColor
                result.append(parseInlineFormatting(content, baseAttrs: innerAttrs, baseFont: baseFont, baseColor: baseColor))
                
            } else if match.range(at: 5).location != NSNotFound {
                // <u>underline</u> → re-parser le contenu interne
                let content = nsText.substring(with: match.range(at: 5))
                var innerAttrs = baseAttrs
                innerAttrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                result.append(parseInlineFormatting(content, baseAttrs: innerAttrs, baseFont: baseFont, baseColor: baseColor))
                
            } else if match.range(at: 6).location != NSNotFound && match.range(at: 7).location != NSNotFound {
                // <font color="#HEX">text</font> → re-parser le contenu interne
                let hexColor = nsText.substring(with: match.range(at: 6))
                let content = nsText.substring(with: match.range(at: 7))
                var innerAttrs = baseAttrs
                innerAttrs[.foregroundColor] = UIColor(hex: hexColor) ?? baseColor
                result.append(parseInlineFormatting(content, baseAttrs: innerAttrs, baseFont: baseFont, baseColor: UIColor(hex: hexColor) ?? baseColor))
                
            } else if match.range(at: 8).location != NSNotFound {
                // `code inline` — pas de récursion
                let content = nsText.substring(with: match.range(at: 8))
                var attrs = baseAttrs
                attrs[.font] = codeFont
                attrs[.foregroundColor] = UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 1)
                attrs[.backgroundColor] = UIColor.systemGray6
                result.append(NSAttributedString(string: " \(content) ", attributes: attrs))
                
            } else if match.range(at: 9).location != NSNotFound && match.range(at: 10).location != NSNotFound {
                // ![alt](image url)
                let alt = nsText.substring(with: match.range(at: 9))
                let displayText = alt.isEmpty ? "🖼️ Image" : "🖼️ \(alt)"
                var attrs = baseAttrs
                attrs[.foregroundColor] = UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 1)
                let italicFont = fontWith(base: baseFont, traits: .traitItalic)
                attrs[.font] = italicFont
                result.append(NSAttributedString(string: displayText, attributes: attrs))
                
            } else if match.range(at: 11).location != NSNotFound && match.range(at: 12).location != NSNotFound {
                // [text](url)
                let linkText = nsText.substring(with: match.range(at: 11))
                let urlString = nsText.substring(with: match.range(at: 12))
                var attrs = baseAttrs
                attrs[.foregroundColor] = UIColor(red: 0.52, green: 0.21, blue: 0.93, alpha: 1)
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                if let url = URL(string: urlString) {
                    attrs[.link] = url
                }
                result.append(NSAttributedString(string: linkText, attributes: attrs))
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // Reste du texte
        if lastEnd < nsText.length {
            result.append(NSAttributedString(string: nsText.substring(from: lastEnd), attributes: baseAttrs))
        }
        
        return result
    }
    
    // MARK: - Font Helpers
    
    private static func fontWith(base: UIFont, traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(traits) ?? base.fontDescriptor, size: base.pointSize)
    }
    
    private struct FontSizes {
        let h1: UIFont
        let h2: UIFont
        let h3: UIFont
        let h4: UIFont
        
        init(base: UIFont) {
            h1 = UIFont.systemFont(ofSize: base.pointSize + 10, weight: .heavy)
            h2 = UIFont.systemFont(ofSize: base.pointSize + 6, weight: .bold)
            h3 = UIFont.systemFont(ofSize: base.pointSize + 3, weight: .semibold)
            h4 = UIFont.systemFont(ofSize: base.pointSize + 1, weight: .semibold)
        }
        
        func heading(level: Int) -> UIFont {
            switch level {
            case 1: return h1
            case 2: return h2
            case 3: return h3
            default: return h4
            }
        }
    }
}

// MARK: - UIColor Hex Extension

private extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        guard hexSanitized.count == 6,
              let rgbValue = UInt64(hexSanitized, radix: 16) else { return nil }
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - Article Read Tracker

/// Détecte les nouveaux articles en stockant les IDs connus par catégorie dans UserDefaults.
/// - Au premier chargement d'une catégorie, tous les articles sont enregistrés comme "connus" (pas de badge NEW).
/// - Quand un nouvel article apparaît, il est marqué "nouveau" → badge NEW.
/// - Quand l'utilisateur ouvre l'article → marqué comme "vu" → badge disparaît.
final class ArticleReadTracker: ObservableObject {
    static let shared = ArticleReadTracker()
    
    private let defaults = UserDefaults.standard
    private let prefix = "ArticleTracker_"
    
    /// Publie un changement quand un article est marqué comme vu
    @Published var lastUpdate = Date()
    
    private init() {
        // Demander la permission pour le badge sur l'icône de l'app
        requestBadgePermission()
    }
    
    // MARK: - API publique
    
    /// Enregistre les articles d'une catégorie. Au premier appel, tous sont marqués "connus".
    /// Aux appels suivants, les nouveaux IDs sont détectés.
    func registerArticles(_ articles: [BasesArticleData], forAsset asset: String) {
        let key = prefix + asset
        let currentIDs = Set(articles.map { $0.id })
        
        if let stored = defaults.array(forKey: key) as? [Int] {
            let knownIDs = Set(stored)
            let newIDs = currentIDs.subtracting(knownIDs)
            let allIDs = knownIDs.union(currentIDs)
            defaults.set(Array(allIDs), forKey: key)
            
            if !newIDs.isEmpty {
                // Publier le changement pour mettre à jour les badges
                DispatchQueue.main.async {
                    self.lastUpdate = Date()
                }
            }
        } else {
            // Premier chargement : enregistrer tous les IDs comme connus ET vus
            defaults.set(Array(currentIDs), forKey: key)
            let seenKey = prefix + "seen_" + asset
            defaults.set(Array(currentIDs), forKey: seenKey)
        }
    }
    
    /// Retourne `true` si l'article est nouveau (pas encore vu par l'utilisateur)
    func isNew(articleID: Int, forAsset asset: String) -> Bool {
        let seenKey = prefix + "seen_" + asset
        let seenIDs = Set(defaults.array(forKey: seenKey) as? [Int] ?? [])
        return !seenIDs.contains(articleID)
    }
    
    /// Marque un article comme vu
    func markAsSeen(articleID: Int, forAsset asset: String) {
        let seenKey = prefix + "seen_" + asset
        var seenIDs = defaults.array(forKey: seenKey) as? [Int] ?? []
        if !seenIDs.contains(articleID) {
            seenIDs.append(articleID)
            defaults.set(seenIDs, forKey: seenKey)
            DispatchQueue.main.async {
                self.lastUpdate = Date()
                self.updateAppIconBadge()
            }
        }
    }
    
    /// Retourne le nombre d'articles nouveaux non lus pour un asset
    func newCount(forAsset asset: String) -> Int {
        let key = prefix + asset
        let knownIDs = Set(defaults.array(forKey: key) as? [Int] ?? [])
        let seenKey = prefix + "seen_" + asset
        let seenIDs = Set(defaults.array(forKey: seenKey) as? [Int] ?? [])
        return knownIDs.subtracting(seenIDs).count
    }
    
    /// Nombre total d'articles non lus sur toutes les catégories
    var totalNewCount: Int {
        ArticleCacheService.allAssetNames.reduce(0) { $0 + newCount(forAsset: $1) }
    }
    
    /// Pré-enregistre les articles de tous les assets pour pouvoir afficher les badges
    func preloadAllAssets() {
        for asset in ArticleCacheService.allAssetNames {
            if let data = ArticleCacheService.shared.loadData(forAsset: asset),
               let envelope = try? JSONDecoder().decode(BasesDataEnvelope.self, from: data) {
                registerArticles(envelope.articles, forAsset: asset)
            }
        }
        updateAppIconBadge()
    }
    
    // MARK: - Badge icône app
    
    /// Demande la permission pour afficher un badge sur l'icône de l'app
    private func requestBadgePermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.badgeSetting == .enabled {
                return
            }
            // Il faut demander .badge avec .alert pour que iOS affiche la popup
            center.requestAuthorization(options: [.badge, .alert]) { granted, error in
                if granted {
                    // Mettre à jour le badge dès que la permission est accordée
                    self.updateAppIconBadge()
                }
            }
        }
    }
    
    /// Met à jour le badge sur l'icône de l'app avec le nombre total d'articles non lus
    func updateAppIconBadge() {
        let count = totalNewCount
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(count) { _ in }
        }
    }
}

// MARK: - Data Models

struct BasesArticleData: Codable, Identifiable {
    let id: Int
    let title: String
    let hook: String
    let reading_time_minutes: Int
    let level: String
    let tags: [String]?
    let content: String
    let actions_a_tester: [String]?
    let quiz: BasesQuiz?
    let illustration_idea: String?
    
    /// Actions non vides
    var hasActions: Bool {
        guard let actions = actions_a_tester else { return false }
        return !actions.isEmpty && actions.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
    }
    
    /// Quiz rempli
    var hasQuiz: Bool {
        guard let q = quiz else { return false }
        return !q.question.trimmingCharacters(in: .whitespaces).isEmpty && !q.choices.isEmpty
    }
}

struct BasesQuiz: Codable {
    let question: String
    let choices: [String]
    let answer: Int
}

struct BasesDataEnvelope: Codable {
    let category: String
    let articles: [BasesArticleData]
}

// MARK: - Articles List View

struct BasesArticlesView: View {
    let assetName: String
    let imageName: String
    let subtitle: String
    let levelLabel: String

    @State private var articles: [BasesArticleData] = []
    @State private var searchText: String = ""
    @State private var categoryName: String = "Les bases"
    @ObservedObject private var cacheService = ArticleCacheService.shared
    @ObservedObject private var readTracker = ArticleReadTracker.shared

    private let finzPurple = Color(red: 0.52, green: 0.21, blue: 0.93)
    private let finzPink = Color(red: 1.00, green: 0.29, blue: 0.63)
    private let finzGradient = LinearGradient(
        colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
        startPoint: .leading, endPoint: .trailing
    )

    private var filteredArticles: [BasesArticleData] {
        if searchText.isEmpty { return articles }
        let query = searchText.lowercased()
        return articles.filter {
            $0.title.lowercased().contains(query)
            || $0.hook.lowercased().contains(query)
            || ($0.tags ?? []).contains(where: { $0.lowercased().contains(query) })
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header with gradient background
                headerView

                // Search bar
                searchBarView
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Articles count
                HStack {
                    Text("\(filteredArticles.count) article\(filteredArticles.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Articles list
                LazyVStack(spacing: 12) {
                    ForEach(filteredArticles) { article in
                        NavigationLink {
                            BasesArticleDetailView(article: article)
                                .onAppear {
                                    readTracker.markAsSeen(articleID: article.id, forAsset: assetName)
                                }
                        } label: {
                            BasesArticleRowView(
                                article: article,
                                finzPurple: finzPurple,
                                isNew: readTracker.isNew(articleID: article.id, forAsset: assetName)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadArticles() }
        .onChange(of: cacheService.lastUpdated) { _, _ in
            loadArticles()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    finzPurple.opacity(0.15),
                    finzPink.opacity(0.08),
                    Color(UIColor.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: 16) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text(categoryName)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Level badge
                    Text(levelLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(finzGradient)
                        .clipShape(Capsule())
                }

                Spacer()

                // Logo
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: finzPurple.opacity(0.2), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .frame(height: 140)
    }

    // MARK: - Search Bar

    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))

            TextField("Rechercher un article…", text: $searchText)
                .font(.subheadline)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Load

    private func loadArticles() {
        guard let data = ArticleCacheService.shared.loadData(forAsset: assetName) else {
            return
        }
        do {
            let envelope = try JSONDecoder().decode(BasesDataEnvelope.self, from: data)
            categoryName = envelope.category
            articles = envelope.articles
            readTracker.registerArticles(envelope.articles, forAsset: assetName)
        } catch {
            // JSON decode error — silently ignore
        }
    }
}

// MARK: - Article Row

private struct BasesArticleRowView: View {
    let article: BasesArticleData
    let finzPurple: Color
    var isNew: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(article.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if isNew {
                        Text("NEW")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }

                Text(article.hook)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Reading time
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(article.reading_time_minutes) min")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)

                    // Level
                    Text(article.level.capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(finzPurple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(finzPurple.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Article Detail View

struct BasesArticleDetailView: View {
    let article: BasesArticleData

    @State private var selectedAnswer: Int? = nil
    @State private var showQuizResult: Bool = false

    private let finzPurple = Color(red: 0.52, green: 0.21, blue: 0.93)
    private let finzPink = Color(red: 1.00, green: 0.29, blue: 0.63)
    private let finzGradient = LinearGradient(
        colors: [Color(red: 0.52, green: 0.21, blue: 0.93), Color(red: 1.00, green: 0.29, blue: 0.63)],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                articleHeaderView

                // Content
                JustifiedText(
                    article.content,
                    font: .preferredFont(forTextStyle: .body),
                    textColor: UIColor.label.withAlphaComponent(0.85),
                    lineSpacing: 6
                )
                .padding(.horizontal, 20)

                // Actions à tester
                if article.hasActions {
                    actionsSectionView
                }

                // Quiz
                if article.hasQuiz {
                    quizSectionView
                }

                // Tags
                if let tags = article.tags, !tags.isEmpty {
                    tagsSectionView
                }

                Color.clear.frame(height: 30)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Article Header

    private var articleHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Level + time
            HStack(spacing: 10) {
                Label(article.level.capitalized, systemImage: "graduationcap")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(finzGradient)
                    .clipShape(Capsule())

                Label("\(article.reading_time_minutes) min", systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }

            // Title
            Text(article.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Hook
            Text(article.hook)
                .font(.callout.italic())
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [finzPurple.opacity(0.08), finzPink.opacity(0.04), .clear],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Actions Section

    private var actionsSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(finzGradient)
                Text("Actions à tester")
                    .font(.headline)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(Array((article.actions_a_tester ?? []).enumerated()), id: \.offset) { index, action in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(finzPurple.opacity(0.1))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(finzPurple)
                        }

                        Text(action)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Quiz Section

    private var quizSectionView: some View {
        Group {
            if let quiz = article.quiz {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(finzGradient)
                        Text("Quiz rapide")
                            .font(.headline)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(quiz.question)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedAnswer = index
                                    showQuizResult = true
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(quizCircleColor(for: index))
                                            .frame(width: 28, height: 28)
                                        Text(["A", "B", "C"][index])
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(quizLetterColor(for: index))
                                    }

                                    Text(choice)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    if showQuizResult && index == quiz.answer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else if showQuizResult && index == selectedAnswer && index != quiz.answer {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(quizRowBackground(for: index))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(quizBorderColor(for: index), lineWidth: 1.5)
                                )
                            }
                            .disabled(showQuizResult)
                        }

                        // Result message
                        if showQuizResult {
                            HStack {
                                if selectedAnswer == quiz.answer {
                                    Image(systemName: "party.popper.fill")
                                    Text("Bien joué ! C'est la bonne réponse 🎉")
                                } else {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                    Text("Pas tout à fait ! Mais t'inquiète, on apprend en faisant 💪")
                                }
                            }
                            .font(.caption.weight(.medium))
                            .foregroundColor(selectedAnswer == quiz.answer ? .green : .orange)
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(article.tags ?? [], id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(finzPurple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(finzPurple.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Quiz Helpers

    private func quizCircleColor(for index: Int) -> Color {
        guard let quiz = article.quiz else { return finzPurple.opacity(0.1) }
        if showQuizResult && index == quiz.answer { return .green.opacity(0.15) }
        if showQuizResult && index == selectedAnswer { return .red.opacity(0.15) }
        return finzPurple.opacity(0.1)
    }

    private func quizLetterColor(for index: Int) -> Color {
        guard let quiz = article.quiz else { return finzPurple }
        if showQuizResult && index == quiz.answer { return .green }
        if showQuizResult && index == selectedAnswer { return .red }
        return finzPurple
    }

    private func quizRowBackground(for index: Int) -> Color {
        guard let quiz = article.quiz else { return Color(.systemBackground) }
        if showQuizResult && index == quiz.answer { return .green.opacity(0.05) }
        if showQuizResult && index == selectedAnswer && index != quiz.answer { return .red.opacity(0.05) }
        return Color(.systemBackground)
    }

    private func quizBorderColor(for index: Int) -> Color {
        guard let quiz = article.quiz else { return Color(.systemGray5) }
        if showQuizResult && index == quiz.answer { return .green.opacity(0.3) }
        if showQuizResult && index == selectedAnswer && index != quiz.answer { return .red.opacity(0.3) }
        return Color(.systemGray5)
    }
}
