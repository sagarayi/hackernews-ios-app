//
//  AboutViewController.swift
//  HackerNews
//
//  Presented from the info button: app identity, version, unofficial
//  disclaimer, and entry points to the privacy policy and terms.
//

import UIKit

final class AboutViewController: UITableViewController {
    private enum Row: Int, CaseIterable {
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

    private let showsDoneButton: Bool

    init(showsDoneButton: Bool = true) {
        self.showsDoneButton = showsDoneButton
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported — AboutViewController is programmatic")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
        navigationController?.navigationBar.prefersLargeTitles = false
        if showsDoneButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done, target: self, action: #selector(dismissAbout)
            )
        }
        tableView.backgroundColor = HNTheme.beige
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LegalRow")
    }

    @objc private func dismissAbout() {
        dismiss(animated: true)
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        "HN Reader"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String {
        "Version \(Self.appVersion())\nUnofficial Hacker News client. Not affiliated with or endorsed by Y Combinator.\n© 2026 sagarayi"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LegalRow", for: indexPath)
        cell.textLabel?.text = Row(rawValue: indexPath.row)?.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = Row(rawValue: indexPath.row) else { return }
        navigationController?.pushViewController(
            LegalTextViewController(title: row.title, text: row.text),
            animated: true
        )
    }

    // MARK: - Version

    private static func appVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        return "\(version) (\(build))"
    }
}
