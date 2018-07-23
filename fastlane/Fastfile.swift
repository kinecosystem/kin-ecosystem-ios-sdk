// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
    
    func releaseLane() {
        
        // make sure we're on master
        guard gitBranch() == "master" else {
            stop(message: "pod releases can only be done from the master branch.")
            return
        }
        // make sure everything is commited
        ensureGitStatusClean(showUncommittedChanges: true, showDiff: true)
        
        let podspecPath = "KinEcosystem.podspec"
        // get current version
        let command = RubyCommand(commandID: "",
                                  methodName: "version_get_podspec",
                                  className: nil,
                                  args: [RubyCommand.Argument(name: "path",
                                                              value: podspecPath),
                                         RubyCommand.Argument(name: "require_variable_prefix",
                                                              value: true)])
        let current = runner.executeCommand(command)
        // request version input
        let version = prompt(text: "Please enter a new pod version (current version is \(current)):", ciInput: "", boolean: false, secureText: false, multiLineEndKeyword: nil)
        
        // verify podspec version
        versionBumpPodspec(path: podspecPath, bumpType: "patch", versionNumber: version, versionAppendix: nil, requireVariablePrefix: true)
        
        let kinFileURL = URL(fileURLWithPath: "KinEcosystem/Core/Kin.swift")
        let readmeFileURL = URL(fileURLWithPath: "README.md")
        do {
            // verify bi version
            try replace(pattern: "let SDKVersion =.*", in: kinFileURL, with: "let SDKVersion = \"\(version)\"")
            // verify version in readme
            try replace(pattern: "pod 'KinEcosystem',.*", in: readmeFileURL, with: "pod 'KinEcosystem', '\(version)'")
        } catch {
            puts(message: "error at \(#line)")
        }
        addGitTag(tag: version, grouping: "", prefix: "", postfix: "", buildNumber: "", message: nil, commit: nil, force: false, sign: false)
        gitAdd(path: ".", shellEscape: true, pathspec: nil)
        gitCommit(path: ".", message: "Release \(version)")
        pushToGitRemote(localBranch: "master", remoteBranch: "master", force: false, tags: true, remote: "origin")
        podPush()
    }
    
    func replace(pattern: String, in file: URL, with template: String) throws {
        let fileString = try String(contentsOf:file, encoding: .utf8)
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSMakeRange(0, fileString.count)
        let modified = regex.stringByReplacingMatches(in: fileString, options: [], range: range, withTemplate: template)
        try modified.write(to: file, atomically: true, encoding: .utf8)
    }
    
    func stop(message: String? = nil) {
        let shutdownCommand = ControlCommand(commandType: .cancel(cancelReason: .clientError), message: message)
        _ = runner.executeCommand(shutdownCommand)
    }
}


