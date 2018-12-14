//
//  SettingsViewController.swift
//  Base64
//
//  Created by Corey Werner on 01/11/2018.
//

import UIKit
import KinCoreSDK

@available(iOS 9.0, *)
class SettingsViewController: UITableViewController {
    private let brManager = BRManager(with: Kin.shared)
    
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
        
        var icon: UIImage? {
            switch self {
            case .backup: return UIImage(named: "greyBackupIcon", in: Bundle.ecosystem, compatibleWith: nil)
            case .restore: return UIImage(named: "blueRestoreIcon", in: Bundle.ecosystem, compatibleWith: nil)
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
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
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
        
        cell.imageView?.image = rowData.icon
        cell.textLabel?.text = rowData.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navigationController = navigationController else {
            return
        }
        
        let phase = dataSource[indexPath.row].phase
        
        Kin.track { try SettingsOptionTapped(settingOption: phase == .backup ? KBITypes.SettingOption.backup : KBITypes.SettingOption.backup) }
        
        brManager.start(phase, pushedOnto: navigationController, events: { event in
            
        }) { completed in
            if case .restore = phase {
                Kin.track { try RestoreWalletCompleted() }
            } else {
                Kin.track { try BackupWalletCompleted() }
            }
        }
    }
}
