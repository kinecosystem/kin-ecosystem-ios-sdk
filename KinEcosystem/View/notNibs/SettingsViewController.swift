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
            case .backup: return "Keep yout Kin safe"
            case .restore: return "Restore previous wallet"
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
            return "Settings"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navigationController = navigationController else {
            return
        }
        
        let phase = dataSource[indexPath.row].phase
        
        brManager.start(phase, pushedOnto: navigationController, events: { event in
            
        }) { completed in
            
        }
    }
}
