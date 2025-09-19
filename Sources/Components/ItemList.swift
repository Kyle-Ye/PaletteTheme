//
//  ItemList.swift
//
//  Used on Writing view.
//
//  Created by Yuhan Chen on 2022/02/06.
//

import Foundation
import Publish
import Plot

struct LanguageVariant<Site: PaletteWebsite> {
    let item: Item<Site>
    let languageCode: String
    let languageName: String
}

struct MultiLanguageItem<Site: PaletteWebsite> {
    let basePath: String
    let variants: [LanguageVariant<Site>]
}

struct ItemList<Site: PaletteWebsite>: Component {
    var items: [Item<Site>]
    var site: Site

    var body: Component {
        let groupedItems = groupLanguageVariants(items)

        return List(groupedItems) { multiItem in
            if multiItem.variants.count > 1 {
                // Multi-language item with language-aware display
                return Div {
                    // Create variants for each language
                    ComponentGroup {
                        for variant in multiItem.variants {
                            createLanguageVariant(for: variant, multiItem: multiItem)
                        }
                    }
                }
                .attribute(named: "data-multilang-item", value: multiItem.basePath)
            } else {
                // Single language item
                let item = multiItem.variants.first!.item
                return Article {
                    H3(Link(item.title, url: extractBasePath(from: item.path).absoluteString))
                        .class("font-semibold")
                    Paragraph(item.description)
                        .class("mt-2")
                        .class("text-zinc-500 dark:text-zinc-400")
                    ItemTagListWithDate(item: item, site: site)
                        .class("mt-8")
                }
                .class("rounded-lg my-6 p-6")
                .class("bg-zinc-100 dark:bg-zinc-800")
            }
        }
    }

    private func createLanguageVariant(for variant: LanguageVariant<Site>, multiItem: MultiLanguageItem<Site>) -> Component {
        Article {
            H3(Link(variant.item.title, url: extractBasePath(from: variant.item.path).absoluteString))
                .class("font-semibold")
            Paragraph(variant.item.description)
                .class("mt-2")
                .class("text-zinc-500 dark:text-zinc-400")
            ItemTagListWithDate(item: variant.item, site: site)
                .class("mt-8")
        }
        .class("rounded-lg my-6 p-6")
        .class("bg-zinc-100 dark:bg-zinc-800")
        .attribute(named: "data-lang", value: variant.languageCode)
        .attribute(named: "style", value: variant.languageCode == "en" ? "display: block;" : "display: none;")
    }

    private func groupLanguageVariants(_ items: [Item<Site>]) -> [MultiLanguageItem<Site>] {
        var grouped: [String: [LanguageVariant<Site>]] = [:]

        for item in items {
            let basePath = extractBasePath(from: item.path).string
            let languageCode = extractLanguageCode(from: item.path)

            let variant = LanguageVariant<Site>(
                item: item,
                languageCode: languageCode,
                languageName: getLanguageName(for: languageCode)
            )

            if grouped[basePath] == nil {
                grouped[basePath] = []
            }
            grouped[basePath]!.append(variant)
        }

        return grouped.map { basePath, variants in
            MultiLanguageItem<Site>(
                basePath: basePath,
                variants: variants.sorted { $0.languageCode < $1.languageCode }
            )
        }.sorted { item1, item2 in
            // Sort by most recent date of any variant in the group
            let date1 = item1.variants.map(\.item.date).max() ?? Date.distantPast
            let date2 = item2.variants.map(\.item.date).max() ?? Date.distantPast
            return date1 > date2
        }
    }

    private func extractLanguageCode(from path: Path) -> String {
        let pathString = path.string

        if let underscoreIndex = pathString.lastIndex(of: "_"),
           let suffixStart = pathString.index(underscoreIndex, offsetBy: 1, limitedBy: pathString.endIndex) {
            let suffix = String(pathString[suffixStart...])

            if isValidLanguageCode(suffix) {
                return suffix
            }
        }

        return "en" // Default to English
    }

    private func getLanguageName(for code: String) -> String {
        switch code {
        case "zh": return "中文"
        case "en": return "English"
        case "ja": return "日本語"
        case "ko": return "한국어"
        case "fr": return "Français"
        case "de": return "Deutsch"
        case "es": return "Español"
        case "it": return "Italiano"
        case "pt": return "Português"
        case "ru": return "Русский"
        default: return code.capitalized
        }
    }

    // Helper function to extract base path from item path
    private func extractBasePath(from path: Path) -> Path {
        let pathString = path.string

        // Check if path ends with language suffix (e.g., "_en")
        if let underscoreIndex = pathString.lastIndex(of: "_"),
           let suffixStart = pathString.index(underscoreIndex, offsetBy: 1, limitedBy: pathString.endIndex) {
            let suffix = String(pathString[suffixStart...])

            // Check if suffix is a valid language code
            if isValidLanguageCode(suffix) {
                let basePath = String(pathString[..<underscoreIndex])
                return Path(basePath)
            }
        }

        // Return original path if no language suffix found
        return path
    }

    // Helper function to check if a string is a valid language code
    private func isValidLanguageCode(_ code: String) -> Bool {
        let supportedLanguages = ["en", "zh", "ja", "ko", "fr", "de", "es", "it", "pt", "ru"]
        return supportedLanguages.contains(code)
    }
}

extension Component {
    func appendingScript(_ script: String) -> Component {
        return ComponentGroup {
            self
            Script(script: script)
        }
    }
}

struct Script: Component {
    let script: String

    var body: Component {
        Node<HTML.BodyContext>.script(.text(script))
    }
}

// Remove the HomepageItemList since we'll use a different approach

struct GroupByYearItemList<Site: PaletteWebsite>: Component {
    let items: [Item<Site>]
    let site: Site
    
    private var groupByYear: [Int: [Item<Site>]] {
        var itemsDic: [Int: [Item<Site>]] = [:]
        items.forEach { item in
            let year = item.date.year
            var itemsOfYear = itemsDic[year] ?? []
            itemsOfYear.append(item)
            itemsDic[year] = itemsOfYear
        }
        return itemsDic
    }
    private var sortedYears: [Int] { groupByYear.keys.sorted(by: >) }

    var body: Component {
        List(sortedYears) { year in
            let sortedArticles = groupByYear[year]?.sorted(by: \.date, ascending: false) ?? []
            return Div {
                H2("\(year)").class("top-h2")
                List(sortedArticles) { item in
                    Div {
                        Span("\(item.date.formattedString)")
                            .class("flex-none w-32 text-zinc-500")
                        Span(Link(item.title, url: item.path.absoluteString))
                            .class("flex-3 link-underline")
                    }
                    .class("flex my-2")
                }
                .class("group-item-list")
            }
        }
        .class("space-y-16")
    }
}
