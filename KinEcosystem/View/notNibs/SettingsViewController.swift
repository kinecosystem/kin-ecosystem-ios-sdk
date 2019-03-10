//
//  SettingsViewController.swift
//  Base64
//
//  Created by Corey Werner on 01/11/2018.
//

import UIKit
import KinCoreSDK

protocol SettingsViewControllerDelegate {
    var didPerformBackup: Bool { get }
}

@available(iOS 9.0, *)
class SettingsViewController: UITableViewController {
    private let brManager = BRManager(with: Kin.shared)
    
    var delegate: SettingsViewControllerDelegate?
    // MARK: Datasource
    
    private enum Row {
        case backup
        case restore
        
        var phase: BRPhase {
            switch self {
            case .backup: return .backup
            case .restore: return .restore
            }
        }
        
        var title: String {
            switch self {
            case .backup: return "kinecosystem_settings_row_backup".localized()
            case .restore: return "kinecosystem_settings_row_restore".localized()
            }
        }
    }
    
    private let dataSource: [Row] = [
        .backup,
        .restore
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
            Kin.track { try SettingsBackButtonTapped() }
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
    
    // MARK: Table View
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let rowData = dataSource[indexPath.row]
        
        
        cell.textLabel?.text = rowData.title
        cell.accessoryType = .disclosureIndicator
        
        guard let delegate = delegate else {
            return cell
        }
        
        if case .backup = rowData {
            cell.imageView?.image = UIImage(named: delegate.didPerformBackup ? "blueBackupIcon" : "backupBadge", in: Bundle.ecosystem, compatibleWith: nil)
        } else {
            cell.imageView?.image = UIImage(named: "blueRestoreIcon", in: Bundle.ecosystem, compatibleWith: nil)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navigationController = navigationController else {
            return
        }
        
        let phase = dataSource[indexPath.row].phase
        
        Kin.track { try SettingsOptionTapped(settingOption: phase == .backup ? KBITypes.SettingOption.backup : KBITypes.SettingOption.backup) }
        
        brManager.start(phase, pushedOnto: navigationController) { completed in
            guard completed else { return }
            if case .restore = phase {
                Kin.track { try RestoreWalletCompleted() }
            } else {
                Kin.track { try BackupWalletCompleted() }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
}
