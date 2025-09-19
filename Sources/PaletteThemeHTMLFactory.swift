//
//  PaletteThemeHTMLFactory.swift
//  
//
//  Created by Yuhan Chen on 2022/01/23.
//

import Foundation
import Publish
import Plot

func generateHomepageLanguageData<Site: PaletteWebsite>(context: PublishingContext<Site>) -> String {
    // Get ALL items from the context (before filtering) and manually extract language variants
    var allItems: [Item<Site>] = []
    for sectionID in type(of: context.site).SectionID.allCases {
        // Access the raw items using allItems method which includes filtered items
        let sectionItems = context.allItems(sortedBy: \.date, order: .descending)
        allItems.append(contentsOf: sectionItems)
        break // We only need one section since allItems gets all items
    }

    // Group items by base path
    var grouped: [String: [Item<Site>]] = [:]
    for item in allItems {
        let basePath = extractBasePath(from: item.path).string
        if grouped[basePath] == nil {
            grouped[basePath] = []
        }
        grouped[basePath]!.append(item)
    }

    // Get latest 6 base paths by most recent date
    let sortedBasePaths = grouped.keys.sorted { path1, path2 in
        let date1 = grouped[path1]?.map(\.date).max() ?? Date.distantPast
        let date2 = grouped[path2]?.map(\.date).max() ?? Date.distantPast
        return date1 > date2
    }

    let latestBasePaths = Array(sortedBasePaths.prefix(6))

    // Build language data
    var languageData: [String: [String: [String: Any]]] = [:]

    for basePath in latestBasePaths {
        guard let items = grouped[basePath] else { continue }

        languageData[basePath] = [:]

        for item in items {
            let languageCode = extractLanguageCode(from: item.path)
            languageData[basePath]![languageCode] = [
                "title": item.title,
                "description": item.description,
                "url": extractBasePath(from: item.path).absoluteString,
                "date": formatDate(item.date)
            ]
        }

        // Add known Chinese variants for articles that have them
        if basePath == "posts/swiftui-debug-analysis" {
            languageData[basePath]!["zh"] = [
                "title": "使用 AttributeGraph 调试 SwiftUI：从 DisplayList 到 Transactions",
                "description": "使用 AttributeGraph API 深入分析 SwiftUI 调试技术",
                "url": "/posts/swiftui-debug-analysis",
                "date": formatDate(items.first?.date ?? Date())
            ]
        } else if basePath == "posts/swiftui-textfield-memory-leak" {
            languageData[basePath]!["zh"] = [
                "title": "SwiftUI TextField 在 iOS 17+ 上的内存泄漏分析",
                "description": "深入调查 iOS 17+ 版本中 SwiftUI TextField 由 AFUITargetDetectionController 引起的关键内存泄漏问题，并提供解决方案",
                "url": "/posts/swiftui-textfield-memory-leak",
                "date": formatDate(items.first?.date ?? Date())
            ]
        } else if basePath == "posts/swiftui-timeline-view" {
            languageData[basePath]!["zh"] = [
                "title": "深入理解 SwiftUI 的 TimelineView",
                "description": "基于 OpenSwiftUI 实现探索 TimelineView 和 TimelineSchedule 的内部机制",
                "url": "/posts/swiftui-timeline-view",
                "date": formatDate(items.first?.date ?? Date())
            ]
        } else if basePath == "posts/explore-swiftui-link" {
            languageData[basePath]!["zh"] = [
                "title": "探索 SwiftUI Link 的实现原理",
                "description": "深入分析 SwiftUI Link 组件的内部实现机制和使用技巧",
                "url": "/posts/explore-swiftui-link",
                "date": formatDate(items.first?.date ?? Date())
            ]
        }
    }

    // Convert to JSON
    guard let jsonData = try? JSONSerialization.data(withJSONObject: languageData, options: []),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        return "const homepageLanguageData = {};"
    }

    return """
    const homepageLanguageData = \(jsonString);

    // Function to update homepage content based on language
    function updateHomepageContent(lang) {
        const DEBUG = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

        if (DEBUG) {
            console.log('Updating homepage content for language:', lang);
            console.log('Available language data:', homepageLanguageData);
        }

        // Iterate through all articles on the homepage
        const articles = document.querySelectorAll('article');
        if (DEBUG) console.log('Found articles:', articles.length);

        Object.keys(homepageLanguageData).forEach(function(basePath) {
            const itemData = homepageLanguageData[basePath];
            const langData = itemData[lang] || itemData['en']; // Fallback to English

            if (langData) {
                if (DEBUG) console.log('Processing basePath:', basePath, 'langData:', langData);

                // Find the article element that matches this base path
                articles.forEach(function(article, index) {
                    const titleLink = article.querySelector('h3 a');
                    if (titleLink) {
                        const currentHref = titleLink.href;
                        if (DEBUG) console.log('Article', index, 'href:', currentHref);

                        // More flexible matching - check if the basePath appears in the current href
                        const basePathParts = basePath.split('/');
                        const lastPart = basePathParts[basePathParts.length - 1]; // e.g., "swiftui-debug-analysis"

                        if (currentHref.includes(lastPart)) {
                            if (DEBUG) console.log('Matched article for basePath:', basePath, 'updating to:', langData.title);

                            // Update title and URL
                            titleLink.textContent = langData.title;
                            titleLink.href = langData.url;

                            // Update description - look for the paragraph that contains description text
                            const description = article.querySelector('p.text-zinc-500, p.mt-2');
                            if (description) {
                                description.textContent = langData.description;
                                if (DEBUG) console.log('Updated description to:', langData.description);
                            } else {
                                if (DEBUG) console.log('Description element not found for article');
                            }
                        }
                    }
                });
            }
        });
    }

    // Make it globally available
    window.updateHomepageContent = updateHomepageContent;
    """
}

// Helper functions for language processing
func extractBasePath(from path: Path) -> Path {
    let pathString = path.string

    if let underscoreIndex = pathString.lastIndex(of: "_"),
       let suffixStart = pathString.index(underscoreIndex, offsetBy: 1, limitedBy: pathString.endIndex) {
        let suffix = String(pathString[suffixStart...])

        if isValidLanguageCode(suffix) {
            let basePath = String(pathString[..<underscoreIndex])
            return Path(basePath)
        }
    }

    return path
}

func extractLanguageCode(from path: Path) -> String {
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

func isValidLanguageCode(_ code: String) -> Bool {
    let supportedLanguages = ["en", "zh", "ja", "ko", "fr", "de", "es", "it", "pt", "ru"]
    return supportedLanguages.contains(code)
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: date)
}

struct PaletteThemeHTMLFactory<Site: PaletteWebsite>: HTMLFactory {
    func makeIndexHTML(for index: Index, context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: index, on: context.site, customNodes: context.site.headCustomNodes + [
                .script(.text("""
                // Language detection for initial page load
                function detectAndSetInitialLanguage() {
                    const stored = localStorage.getItem('preferredLanguage');
                    const browserLang = navigator.language || navigator.userLanguage;

                    let defaultLang = 'en'; // Default to English
                    if (stored) {
                        defaultLang = stored;
                    } else if (browserLang.toLowerCase().includes('zh') ||
                               browserLang.toLowerCase().includes('chinese')) {
                        defaultLang = 'zh_cn';
                    }

                    // Set the detected language as a data attribute for the server to potentially use
                    document.documentElement.setAttribute('data-detected-lang', defaultLang);

                    // Update page language attribute based on detection
                    document.documentElement.lang = (defaultLang === 'zh' || defaultLang === 'zh_cn') ? 'zh-CN' : 'en';

                    // Store detected language for future use
                    if (!localStorage.getItem('preferredLanguage')) {
                        localStorage.setItem('preferredLanguage', defaultLang);
                    }
                }
                detectAndSetInitialLanguage();

                // Homepage multi-language data for content switching
                \(generateHomepageLanguageData(context: context))
                """))
            ]),
            .body {
                PageContainer {
                    RibbonView()
                    CenterContainer {
                        SiteHeader(
                            context: context,
                            selectedItem: context.site.pages.first { $0.isIndex }
                        )
                        Div {
                            // Profile
                            Div {
                                H2("About")
                                    .class("top-h2")
                                Article {
                                    Div(Markdown(context.site.aboutMe)).class("content")
                                }
                                .class("prose prose-zinc min-w-full")
                                .class("dark:prose-invert")
                                SocialItemBar(context: context)
                                    .class("mt-4")
                            }
                            .class("mb-16")

                            // Latest Writing
                            H2("Latest Writing").class("top-h2")
                            ItemList(
                                items: Array(context.allItems(
                                    sortedBy: \.date,
                                    order: .descending
                                ).prefix(6)),
                                site: context.site
                            )
                            Div {
                                UnderlineButton(title: "Show more", url: "/posts")
                                    .class("float-right")
                            }
                            .class("overflow-hidden")
                        }
                    }
                    SiteFooter(context: context)
                }
            }
        )
    }

    func makeSectionHTML(for section: Section<Site>, context: PublishingContext<Site>) throws -> HTML {
        guard let currentPage = context.site.pages.first(
            where: { $0.id == section.id.rawValue }
        ) else {
            return HTML()
        }

        return HTML(
            .lang(context.site.language),
            .head(for: section, on: context.site, customNodes: context.site.headCustomNodes + [
                .script(.text("""
                // Language detection for section pages
                function detectAndSetLanguage() {
                    const stored = localStorage.getItem('preferredLanguage');
                    const browserLang = navigator.language || navigator.userLanguage;

                    let defaultLang = 'en';
                    if (stored) {
                        defaultLang = stored;
                    } else if (browserLang.toLowerCase().includes('zh') ||
                               browserLang.toLowerCase().includes('chinese')) {
                        defaultLang = 'zh_cn';
                    }

                    document.documentElement.setAttribute('data-detected-lang', defaultLang);
                    document.documentElement.lang = (defaultLang === 'zh' || defaultLang === 'zh_cn') ? 'zh-CN' : 'en';
                }
                detectAndSetLanguage();

                // Section page multi-language data for content switching
                \(generateHomepageLanguageData(context: context))
                """))
            ]),
            .body {
                PageContainer {
                    RibbonView()
                    CenterContainer {
                        SiteHeader(context: context, selectedItem: currentPage)
                        Div {
                            switch currentPage.listType {
                            case .groupByYear:
                                GroupByYearItemList(items: section.items, site: context.site)
                            case .default:
                                ItemList(items: section.items, site: context.site)
                            }
                        }
                    }
                    SiteFooter(context: context)
                }
            }
        )
    }

    func makeItemHTML(for item: Item<Site>, context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: item, on: context.site, customNodes: context.site.headCustomNodes),
            .body(
                .components {
                    PageContainer {
                        RibbonView()
                        FlatHeader(context: context, selectedItem: nil)
                        CenterContainer {
                            ItemTagListWithDate(item: item, site: context.site)
                                .class("mb-1")
                            Article {
                                Div(item.content.body).class("content")
                            }
                            .class("prose prose-zinc min-w-full")
                            .class("dark:prose-invert")
                            
                            // Previous / Next
                            PostNavigationBar(item: item)
                                .class("mt-16")
                            
                            // Comments
                            Div().class({
                                guard let commentClass = context.site.commentSystem?.className else { return "" }
                                return "\(commentClass) mt-20"
                            }())
                        }
                        .class("mx-4")
                        SiteFooter(context: context)
                    }
                },
                .raw({
                    // Comments
                    guard let system = context.site.commentSystem else { return "" }
                    switch system {
                    case .giscus(let script):
                        return script
                    }
                }())
            )
        )
    }

    func makePageHTML(for page: Page, context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site, customNodes: context.site.headCustomNodes),
            .body(
                .components {
                    PageContainer {
                        RibbonView()
                        FlatHeader(context: context, selectedItem: nil)
                        CenterContainer {
                            Article {
                                Div(page.body).class("content")
                            }
                            .class("prose prose-zinc min-w-full")
                            .class("dark:prose-invert")
                            
                            // Comments
                            Div().class({
                                guard let commentClass = context.site.commentSystem?.className else { return "" }
                                return "\(commentClass) mt-20"
                            }())
                        }
                        .class("mx-4")
                        SiteFooter(context: context)
                    }
                },
                .raw({
                    // Comments
                    guard let system = context.site.commentSystem else { return "" }
                    switch system {
                    case .giscus(let script):
                        return script
                    }
                }())
            )
        )
    }

    func makeTagListHTML(for page: TagListPage, context: PublishingContext<Site>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site, customNodes: context.site.headCustomNodes),
            .body {
                PageContainer {
                    RibbonView()
                    CenterContainer {
                        SiteHeader(context: context, selectedItem: nil)
                        Div {
                            List(page.tags.sorted()) { tag in
                                ListItem {
                                    Link(tag.string, url: context.site.path(for: tag).absoluteString)
                                        .class("hashtag link-underline")
                                }
                            }
                            .class("flex flex-wrap gap-4")
                        }
                    }
                    SiteFooter(context: context)
                }
            }
        )
    }

    func makeTagDetailsHTML(for page: TagDetailsPage,  context: PublishingContext<Site>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site, customNodes: context.site.headCustomNodes),
            .body {
                PageContainer {
                    RibbonView()
                    CenterContainer {
                        SiteHeader(
                            context: context,
                            selectedItem: context.site.pages.first { $0.title == page.tag.string }
                        )
                        Div {
                            H2 {
                                Text("Tagged with ")
                                Span(page.tag.string).class("hashtag")
                            }
                            .class("top-h2")

                            ItemList(
                                items: context.items(
                                    taggedWith: page.tag,
                                    sortedBy: \.date,
                                    order: .descending
                                ),
                                site: context.site
                            )
                            
                            Div {
                                UnderlineButton(
                                    title: "Browse all tags",
                                    url: context.site.tagListPath.absoluteString
                                ).class("float-right")
                            }
                            .class("overflow-hidden")
                        }
                    }
                    SiteFooter(context: context)
                }
            }
        )
    }
}
