//
//  SettingsViewController.swift
//  Base64
//
//  Created by Corey Werner on 01/11/2018.
//

import UIKit
import KinCoreSDK

private enum Row {
    case backup
    case restore
    case transfer

    var phase: BRPhase? {
        switch self {
        case .backup: return .backup
        case .restore: return .restore
        default: return nil
        }
    }

    var imageName: String {
        switch self {
        case .backup: return "SettingsBackupIcon"
        case .restore: return "SettingsRestoreIcon"
        case .transfer: return "SettingsRestoreIcon"
        }
    }

    var title: String {
        switch self {
        case .backup: return "kinecosystem_settings_row_backup".localized()
        case .restore: return "kinecosystem_settings_row_restore".localized()
        case .transfer: return "kinecosystem_settings_row_transfer".localized()
        }
    }
}

class SettingsViewController: UITableViewController {
    private let brManager = BRManager(with: Kin.shared)
    let themeLinkBag = LinkBag()
    fileprivate var theme: Theme = .light
    
    private let rows: [Row] = [
        .backup,
        .restore,
        .transfer
    ]
    
    // MARK: Lifecycle
    
    override var title: String? {
        set {}
        get {
            return "kinecosystem_settings_title".localized()
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            Kin.track { try SettingsBackButtonTapped(exitType: .xButton) }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Kin.track { try SettingsPageViewed() }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 54
        tableView.separatorColor = .kinLightBlueGrey
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
    
    // MARK: Table View
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let rowData = rows[indexPath.row]

        cell.textLabel?.attributedText = rowData.title
            .styled(as: theme.subtitle14)
            .applyingTextAlignment(.left)
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(named: rowData.imageName, in: KinBundle.ecosystem.rawValue, compatibleWith: nil)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        if let phase = row.phase {
            Kin.track { try SettingsOptionTapped(settingOption: phase == .backup ? KBITypes.SettingOption.backup : KBITypes.SettingOption.backup) }

            brManager.start(phase, presentedOn: self) { completed in
                guard completed else { return }
                if case .restore = phase {
                    Kin.track { try RestoreWalletCompleted() }
                } else {
                    Kin.track { try BackupWalletCompleted() }
                }
            }
        } else if row == .transfer {
            tableView.deselectRow(at: indexPath, animated: true)
            Kin.shared.startSendKin()
        }
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme

        tableView.reloadData()
    }
}
