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

class CustomizationHostingController: UIThemedViewController {
    lazy var hostingController = UIHostingController(
        rootView: CustomizationRootView(
            onThemeChanged: { [weak self] in
                self?.view.backgroundColor = currentTheme?.appTableView
            }
        )
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Customization"

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

struct CustomizationRootView: View {
    
    @State var username: String = ""
    @State var hostname: String = ""
    @State var currentIconName: String = UIApplication.shared.alternateIconName ?? "Default"
    @State var appTableCellColor: UIColor = currentTheme?.appTableCell ?? .secondarySystemBackground
    @State var appTableViewColor: UIColor = currentTheme?.appTableView ?? .systemGroupedBackground
    @State var appLabelColor: UIColor = currentTheme?.appLabel ?? .systemBlue
    @State var textColor: UIColor = currentTheme?.textColor ?? .label

    let onThemeChanged: () -> Void

    let icons: [String] = [
        "Default",
        "Drawn",
        "Nyxcat",
        "Nyxcat2",
        "Nyxcat3"
    ]

    var insetColor: Color {
        Color(uiColor: appTableCellColor)
    }

    var body: some View {
        Form {
            Section("Credentials") {
                HStack(spacing: 12) {
                    Text("Username")
                    TextField("i.e Anonymous", text: $username)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: username) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "LDEUsername")
                        }
                }
                .listRowBackground(insetColor)
#if !JAILBREAK_ENV
                HStack(spacing: 12) {
                    Text("Hostname")
                    TextField("localhost", text: $hostname)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: hostname) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "LDEHostname")
                            ksurface_sethostname(newValue)
                        }
                }
                .listRowBackground(insetColor)
#endif // !JAILBREAK_ENV
            }

            Section("Themes") {
                ThemesSectionView(onThemeChanged: handleThemeChanged)
                    .listRowBackground(insetColor)
            }

            Section("Icons") {
                ForEach(icons, id: \.self) { iconName in
                    Button {
                        setIcon(iconName)
                    } label: {
                        HStack(spacing: 12) {
                            if let image = UIImage(named: previewAssetName(for: iconName)) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius))
                            }
                            Text(iconName)
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            if iconName == currentIconName {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundStyle(Color(uiColor: textColor))
                    .listRowBackground(insetColor)
                }
            }
        }
        .tint(Color(uiColor: appLabelColor))
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: appTableViewColor))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCredentials()
            refreshThemeSnapshot()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("uiColorChangeNotif"))) { _ in
            refreshThemeSnapshot()
        }
    }

    var iconCornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            15
        } else {
            10
        }
    }

    func previewAssetName(for iconName: String) -> String {
        if #available(iOS 18.0, *) {
            "IconPreview\(iconName)"
        } else {
            "IconPreview\(iconName)Old"
        }
    }

    func setIcon(_ iconName: String) {
        if iconName == "Default" {
            UIApplication.shared.setAlternateIconName(nil)
        } else {
            UIApplication.shared.setAlternateIconName(iconName)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIconName = UIApplication.shared.alternateIconName ?? "Default"
        }
    }

    func loadCredentials() {
        username = UserDefaults.standard.string(forKey: "LDEUsername") ?? "Anonym"
        hostname = UserDefaults.standard.string(forKey: "LDEHostname") ?? "localhost"
        currentIconName = UIApplication.shared.alternateIconName ?? "Default"
    }

    func handleThemeChanged() {
        refreshThemeSnapshot()
        onThemeChanged()
    }

    func refreshThemeSnapshot() {
        appTableCellColor = currentTheme?.appTableCell ?? .secondarySystemBackground
        appTableViewColor = currentTheme?.appTableView ?? .systemGroupedBackground
        appLabelColor = currentTheme?.appLabel ?? .systemBlue
        textColor = currentTheme?.textColor ?? .label
    }
}
