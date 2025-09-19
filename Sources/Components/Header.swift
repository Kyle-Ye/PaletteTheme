//
//  Header.swift
//  
//
//  Created by Yuhan Chen on 2022/02/06.
//

import Publish
import Plot

struct SiteHeader<Site: PaletteWebsite>: Component {
    var context: PublishingContext<Site>
    var selectedItem: PalettePage?

    var body: Component {
        let profilePath = context.site.profileIconPath
        
        return Header {
            Div {
                if let profilePath = profilePath {
                    Image(url: profilePath, description: "Profile icon")
                        .class("w-[60px] h-[60px] rounded-full")
                }
                Div {
                    Link(context.site.name, url: "/")
                        .class("header-title font-extrabold text-4xl")
                    NavigationBar(context: context, selectedItem: selectedItem)
                }
            }
            .class("my-16")
            .class(profilePath == nil ? "" : "flex flex-col items-center gap-2 ssm:flex-row")
        }
        .class("text-zinc-900 dark:text-zinc-50")
    }
}

struct FlatHeader<Site: PaletteWebsite>: Component {
    var context: PublishingContext<Site>
    var selectedItem: PalettePage?

    var body: Component {
        Header {
            Div {
                Link(context.site.name, url: "/")
                    .class("header-title font-extrabold text-3xl")
                NavigationBar(context: context, selectedItem: selectedItem)
                    .class("my-auto")
            }
            .class("flex flex-wrap justify-between my-4 gap-x-16 max-w-screen-lg w-full")
        }
        .class("flex justify-center p-4")
        .class("text-zinc-900 dark:text-zinc-50")
    }
}

private struct NavigationBar<Site: PaletteWebsite>: Component {
    var context: PublishingContext<Site>
    var selectedItem: PalettePage?

    var body: Component {
        Navigation {
            List(context.site.pages + [languagePickerItem]) { navigationItem in
                if navigationItem.title == "Language" {
                    RootLanguagePicker()
                } else {
                    Link(navigationItem.title, url: navigationItem.link)
                        .class(navigationItem == selectedItem ? "selected" : "")
                        .class("hover:underline underline-offset-4")
                }
            }
            .class("flex flex-wrap gap-4")
        }
    }

    private var languagePickerItem: PalettePage {
        PalettePage(id: "language", title: "Language", link: "#", isIndex: false, listType: .default)
    }
}

struct RootLanguagePicker: Component {
    var body: Component {
        Node<HTML.BodyContext>.raw("""
        <div class="language-picker-container" style="position: relative; display: inline-block;">
            <button class="language-picker-button hover:underline underline-offset-4" onclick="toggleRootLanguagePicker()" style="
                background: none;
                border: none;
                color: inherit;
                cursor: pointer;
                font-size: inherit;
                text-decoration: none;
            ">
                English ▼
            </button>
            <div class="language-dropdown" style="
                display: none;
                position: absolute;
                top: 100%;
                right: 0;
                background: white;
                border: 2px solid #e2e8f0;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.15);
                z-index: 1000;
                min-width: 120px;
                margin-top: 4px;
            ">
                <button onclick="switchRootLanguage('en')" style="
                    display: block;
                    width: 100%;
                    text-align: left;
                    padding: 8px 12px;
                    border: none;
                    cursor: pointer;
                    font-size: 14px;
                    background: #3b82f6; color: white;
                ">English</button>
                <button onclick="switchRootLanguage('zh')" style="
                    display: block;
                    width: 100%;
                    text-align: left;
                    padding: 8px 12px;
                    border: none;
                    cursor: pointer;
                    font-size: 14px;
                    background: white; color: #374151;
                ">中文</button>
            </div>
        </div>

        <script>
        function toggleRootLanguagePicker() {
            const dropdown = document.querySelector('.language-dropdown');
            dropdown.style.display = dropdown.style.display === 'none' ? 'block' : 'none';
        }

        function getCurrentRootLanguage() {
            const stored = localStorage.getItem('preferredLanguage');
            if (stored) return stored === 'zh_cn' ? 'zh' : stored;

            const browserLang = navigator.language || navigator.userLanguage;
            if (browserLang.toLowerCase().includes('zh') ||
                browserLang.toLowerCase().includes('chinese')) {
                return 'zh';
            }
            return 'en';
        }

        function switchRootLanguage(lang) {
            const dropdown = document.querySelector('.language-dropdown');
            dropdown.style.display = 'none';

            const storedLang = lang === 'zh' ? 'zh_cn' : lang;
            localStorage.setItem('preferredLanguage', storedLang);
            document.documentElement.lang = (lang === 'zh') ? 'zh-CN' : 'en';

            const langName = lang === 'zh' ? '中文' : 'English';
            const pickerButton = document.querySelector('.language-picker-button');
            if (pickerButton) {
                pickerButton.innerHTML = langName + ' ▼';
            }

            document.querySelectorAll('.language-dropdown button').forEach(btn => {
                const btnLang = btn.getAttribute('onclick').match(/switchRootLanguage\\('(.+)'\\)/)[1];
                if (btnLang === lang) {
                    btn.style.background = '#3b82f6';
                    btn.style.color = 'white';
                } else {
                    btn.style.background = 'white';
                    btn.style.color = '#374151';
                }
            });

            updateRootPageContent(lang);
        }

        function updateRootPageContent(lang) {
            // First, handle multi-language items with data attributes (if any exist)
            const multiLangItems = document.querySelectorAll('[data-multilang-item]');
            multiLangItems.forEach(item => {
                item.querySelectorAll('[data-lang]').forEach(variant => {
                    variant.style.display = variant.getAttribute('data-lang') === lang ? 'block' : 'none';
                });
            });

            // Then, handle homepage content updates using injected language data
            if (typeof window.updateHomepageContent === 'function') {
                window.updateHomepageContent(lang);
            }

            // Finally, translate UI elements if the function is available
            if (typeof window.translateUIElements === 'function') {
                window.translateUIElements(lang);
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            const currentLang = getCurrentRootLanguage();
            switchRootLanguage(currentLang);
        });

        document.addEventListener('click', function(event) {
            const container = event.target.closest('.language-picker-container');
            if (!container) {
                const dropdown = document.querySelector('.language-dropdown');
                if (dropdown) dropdown.style.display = 'none';
            }
        });
        </script>
        """)
    }
}
