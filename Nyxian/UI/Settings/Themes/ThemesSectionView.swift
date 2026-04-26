/*
 SPDX-License-Identifier: AGPL-3.0-or-later

 Copyright (C) 2025 - 2026 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
 */

import SwiftUI
import Runestone
import TreeSitter
import TreeSitterC

enum ThemeDefaults {
    static let themeIndexKey = "LDETheme"
    static let fontSizeKey = "LDEFontSize"
    static let showLineNumbersKey = "LDEShowLineNumbers"
    static let showSpacesKey = "LDEShowSpaces"
    static let wrapLinesKey = "LDEWrapLines"
    static let showLineBreaksKey = "LDEShowLineBreaks"
    static let autoIndentKey = "LDEAutoindent"
}

struct ThemesSectionView: View {

    let onThemeChanged: () -> Void

    @State var selectedThemeIndex: Int = 0
    @State var fontSize: Int = 12
    @State var showLineNumbers: Bool = true
    @State var showSpaces: Bool = true
    @State var wrapLines: Bool = true
    @State var showLineBreaks: Bool = true
    @State var autoIndent: Bool = true
    @State var showManageThemesSheet: Bool = false
    @State var previewRefreshTick: Int = 0

    let sampleText = """
#include <stdio.h>

int main(void)
{
\tprintf("Hello, World\\n");
\treturn 0;
}
"""

    var themes: [LDETheme] {
        LDEThemeReader.shared.themes
    }

    var selectedTheme: LDETheme {
        guard themes.indices.contains(selectedThemeIndex) else {
            return LDEThemeReader.shared.currentlySelectedTheme()
        }
        return themes[selectedThemeIndex]
    }

    var body: some View {
        Group {
            ThemePreviewTextView(theme: selectedTheme, text: sampleText, refreshTick: previewRefreshTick)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(UIColor.opaqueSeparator), lineWidth: 1)
                )

            HStack(spacing: 12) {
                Text("Theme")
                    .foregroundStyle(Color(uiColor: currentTheme?.textColor ?? .label))
                Spacer()
                Menu {
                    ForEach(Array(themes.enumerated()), id: \.offset) { index, theme in
                        Button {
                            selectedThemeIndex = index
                            UserDefaults.standard.set(index, forKey: ThemeDefaults.themeIndexKey)
                            LDEThemeReader.shared.selectedThemeIndex = index
                            RevertUI()
                            previewRefreshTick += 1
                            onThemeChanged()
                        } label: {
                            if index == selectedThemeIndex {
                                Label(theme.name, systemImage: "checkmark")
                            } else {
                                Text(theme.name)
                            }
                        }
                    }
                    Divider()
                    Button("Manage Themes...") {
                        showManageThemesSheet = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedTheme.name)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
            }

            HStack(spacing: 12) {
                Text("Font Size")
                    .foregroundStyle(Color(uiColor: currentTheme?.textColor ?? .label))
                Spacer()
                Text("\(fontSize)")
                    .foregroundStyle(Color(uiColor: currentTheme?.textColor ?? .secondaryLabel))
                Stepper("", value: Binding(
                    get: { fontSize },
                    set: { newValue in
                        fontSize = newValue
                        UserDefaults.standard.set(newValue, forKey: ThemeDefaults.fontSizeKey)
                        previewRefreshTick += 1
                        onThemeChanged()
                    }
                ), in: 6...20)
                .labelsHidden()
            }

            Toggle("Show Line Numbers", isOn: themedToggleBinding(for: ThemeDefaults.showLineNumbersKey, value: $showLineNumbers))
            Toggle("Show Spaces", isOn: themedToggleBinding(for: ThemeDefaults.showSpacesKey, value: $showSpaces))
            Toggle("Wrap Lines", isOn: themedToggleBinding(for: ThemeDefaults.wrapLinesKey, value: $wrapLines))
            Toggle("Show Line Breaks", isOn: themedToggleBinding(for: ThemeDefaults.showLineBreaksKey, value: $showLineBreaks))
            Toggle("Autoindent", isOn: themedToggleBinding(for: ThemeDefaults.autoIndentKey, value: $autoIndent))
        }
        .onAppear(perform: loadStateFromDefaults)
        .sheet(isPresented: $showManageThemesSheet) {
            ManageThemesView()
        }
    }

    func themedToggleBinding(for key: String, value: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { value.wrappedValue },
            set: { newValue in
                value.wrappedValue = newValue
                UserDefaults.standard.set(newValue, forKey: key)
                previewRefreshTick += 1
                onThemeChanged()
            }
        )
    }

    func loadStateFromDefaults() {
        selectedThemeIndex = UserDefaults.standard.object(forKey: ThemeDefaults.themeIndexKey) as? Int ?? 0
        fontSize = UserDefaults.standard.object(forKey: ThemeDefaults.fontSizeKey) as? Int ?? 12
        showLineNumbers = UserDefaults.standard.object(forKey: ThemeDefaults.showLineNumbersKey) as? Bool ?? true
        showSpaces = UserDefaults.standard.object(forKey: ThemeDefaults.showSpacesKey) as? Bool ?? true
        wrapLines = UserDefaults.standard.object(forKey: ThemeDefaults.wrapLinesKey) as? Bool ?? true
        showLineBreaks = UserDefaults.standard.object(forKey: ThemeDefaults.showLineBreaksKey) as? Bool ?? true
        autoIndent = UserDefaults.standard.object(forKey: ThemeDefaults.autoIndentKey) as? Bool ?? true
    }
}

private struct ThemePreviewTextView: UIViewRepresentable {
    let theme: LDETheme
    let text: String
    let refreshTick: Int

    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        textView.setLanguageMode(loadLanguageMode())
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 2, bottom: 4, right: 0)
        textView.isEditable = false
        textView.isSelectable = false
        textView.lineSelectionDisplayType = .line
        textView.text = text
        applyCurrentSettings(to: textView)
        return textView
    }

    func updateUIView(_ textView: TextView, context: Context) {
        textView.theme = theme
        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.textColor
        textView.selectionBarColor = theme.textColor
        textView.selectionHighlightColor = theme.textColor.withAlphaComponent(0.2)
        applyCurrentSettings(to: textView)
        textView.setNeedsLayout()
    }

    func applyCurrentSettings(to textView: TextView) {
        textView.showLineNumbers = !textView.showLineNumbers
        textView.showLineNumbers = UserDefaults.standard.object(forKey: ThemeDefaults.showLineNumbersKey) as? Bool ?? true
        textView.showSpaces = UserDefaults.standard.object(forKey: ThemeDefaults.showSpacesKey) as? Bool ?? true
        textView.isLineWrappingEnabled = UserDefaults.standard.object(forKey: ThemeDefaults.wrapLinesKey) as? Bool ?? true
        textView.showLineBreaks = UserDefaults.standard.object(forKey: ThemeDefaults.showLineBreaksKey) as? Bool ?? true
    }

    func loadLanguageMode() -> TreeSitterLanguageMode {
        func combinedQuery(from fileURLs: [URL]) -> TreeSitterLanguage.Query? {
            let rawQuery = fileURLs.compactMap { try? String(contentsOf: $0) }.joined(separator: "\n")
            return rawQuery.isEmpty ? nil : TreeSitterLanguage.Query(string: rawQuery)
        }

        let highlightsURL = URL(fileURLWithPath: "\(Bundle.main.bundlePath)/TreeSitterC_TreeSitterC.bundle/queries/highlights.scm")
        let language = TreeSitterLanguage(tree_sitter_c(), highlightsQuery: combinedQuery(from: [highlightsURL]))
        return TreeSitterLanguageMode(language: language)
    }
}
