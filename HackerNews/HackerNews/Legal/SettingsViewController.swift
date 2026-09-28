//
//  SettingsViewController.swift
//  HackerNews
//
//  Appearance switcher (light / dark / automatic) plus the About section
//  (version, disclaimer, privacy policy, terms).
//

import UIKit

final class SettingsViewController: UITableViewController {
    private enum AppearanceRow: Int, CaseIterable {
        case light
        case dark
        case automatic

        var mode: ThemeMode {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .automatic: return .automatic
            }
        }
    }

    private enum AboutRow: Int, CaseIterable {
        case privacy
        case terms

        var title: String {
            switch self {
            case .privacy: return "Privacy Policy"
            case .terms: return "Terms & Conditions"
            }
        }

        var text: String {
            switch self {
            case .privacy: return LegalTexts.privacyPolicy
            case .terms: return LegalTexts.termsAndConditions
            }
        }
    }

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported — SettingsViewController is programmatic")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.backgroundColor = HNTheme.beige
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? AppearanceRow.allCases.count : AboutRow.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        section == 0 ? "Appearance" : "About"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 1 ? "Version \(Self.appVersion())\nUnofficial Hacker News client. Not affiliated with or endorsed by Y Combinator.\n© 2026 sagarayi" : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        if indexPath.section == 0, let row = AppearanceRow(rawValue: indexPath.row) {
            cell.textLabel?.text = row.mode.title
            cell.accessoryType = row.mode == ThemeManager.current ? .checkmark : .none
        } else if let row = AboutRow(rawValue: indexPath.row) {
            cell.textLabel?.text = row.title
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0, let row = AppearanceRow(rawValue: indexPath.row) {
            ThemeManager.set(row.mode, window: view.window)
            tableView.reloadSections(IndexSet(integer: 0), with: .none)
        } else if let row = AboutRow(rawValue: indexPath.row) {
            navigationController?.pushViewController(
                LegalTextViewController(title: row.title, text: row.text),
                animated: true
            )
        }
    }

    // MARK: - Version

    private static func appVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        return "\(version) (\(build))"
    }
}
