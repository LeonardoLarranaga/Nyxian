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

struct ManageThemesView: View {
    let customThemes: [LDETheme] = []
    let nyxianThemes: [LDETheme] = LDEThemeReader.shared.themes

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !customThemes.isEmpty {
                        sectionHeader("Custom Themes")
                        ForEach(Array(customThemes.enumerated()), id: \.offset) { _, theme in
                            themeRow(theme.name)
                        }
                        sectionGap()
                    }

                    sectionHeader("Nyxian Themes")
                    ForEach(Array(nyxianThemes.enumerated()), id: \.offset) { _, theme in
                        themeRow(theme.name)
                    }
                }
                .background(Color(uiColor: currentTheme?.appTableCell ?? .secondarySystemBackground))
            }
            .navigationTitle("Manage Themes")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: currentTheme?.appTableView ?? .systemGroupedBackground))
        }
    }

    @ViewBuilder
    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(Color(uiColor: currentTheme?.appTableView ?? .systemGroupedBackground))
    }

    @ViewBuilder
    func themeRow(_ title: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color(uiColor: currentTheme?.textColor ?? .label))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: currentTheme?.appTableCell ?? .secondarySystemBackground))
    }

    @ViewBuilder
    func sectionGap() -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 14)
            .background(Color(uiColor: currentTheme?.appTableView ?? .systemGroupedBackground))
    }
}
