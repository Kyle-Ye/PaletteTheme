//
//  ItemList.swift
//
//  Used on Writing view.
//
//  Created by Yuhan Chen on 2022/02/06.
//

import Publish
import Plot

struct ItemList<Site: PaletteWebsite>: Component {
    var items: [Item<Site>]
    var site: Site

    var body: Component {
        List(items) { item in
            Article {
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
