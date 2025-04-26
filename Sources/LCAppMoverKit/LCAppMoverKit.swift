//
//  LCAppMoverKit.swift
//
//  Created by DevLiuSir on 2018/4/26.
//


import AppKit
import Security


// App 名称
public let kAPP_Name: String = {
    // 尝试从本地化字典中获取应用名称
    let localizedName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
    // 如果本地化字典中没有，尝试从非本地化字典中获取
    let displayName = localizedName ?? (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
    // 如果还是没有，尝试从本地化字典中获取应用名称
    return displayName ?? (Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String) ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? ""
}()




public func LCAppMoverKitLocalizeString(_ key: String) -> String {
#if SWIFT_PACKAGE
    // 如果是通过 Swift Package Manager 使用
    return Bundle.module.localizedString(forKey: key, value: "", table: "LCAppMoverKit")
#else
    // 如果是通过 CocoaPods 使用
    return Bundle(for: LCAppMoverKit.self).localizedString(forKey: key, value: "", table: "LCAppMoverKit")
#endif
}



final class LCAppMoverKit: NSObject {
    
    // 单例实例，供全局使用
    public static let shared = LCAppMoverKit()
    
    // 是否使用较小字号的“下次不再提示”复选框
    private let UseSmallAlertSuppressCheckbox = true
    
    // UserDefaults 中用于记录用户是否选择“不再提示”的键
    private let AlertSuppressKey = "moveToApplicationsFolderAlertSuppress"
    
    // 默认文件管理器，用于文件路径、权限等操作
    public let fileManager = FileManager.default
    
    /// 如果有必要，将应用移动到“应用程序”文件夹
    public func moveToApplicationsFolderIfNecessary() {
        
        // 本地化提示文字定义
        struct MoveStrings {
            let couldNotMove = LCAppMoverKitLocalizeString("Could_Not_Move_Applications_Folder")
            let questionTitle = LCAppMoverKitLocalizeString("Move_To_Applications_Folder_Title")
            let questionTitleHome = LCAppMoverKitLocalizeString("Move_To_Home_Applications_Folder_Title")
            let questionMessage = String(format: LCAppMoverKitLocalizeString("Move_To_Applications_Message"), kAPP_Name)
            let buttonMove = LCAppMoverKitLocalizeString("Button_Move_To_Applications")
            let buttonStay = LCAppMoverKitLocalizeString("Button_Do_Not_Move")
            let infoNeedsPassword = LCAppMoverKitLocalizeString("Info_Needs_Admin_Password")
            let infoInDownloads = LCAppMoverKitLocalizeString("Info_Cleanup_Downloads")
        }
        
        
        let moveStrings = MoveStrings()
        
        // 如果用户之前选择了不再提示，则直接返回
        guard UserDefaults.standard.bool(forKey: AlertSuppressKey) == false else { return }
        
        // 获取当前应用的路径
        let bundlePath = Bundle.main.bundlePath
        let bundleNameURL = URL(string: bundlePath)
        
        // 如果应用已在任意“应用程序”目录下，则无需移动
        guard LCPathLocationHelper.isInApplicationsFolder(bundleNameURL!) == false else { return }
        
        // 获取推荐的安装目录（可能是系统或用户级别的“应用程序”文件夹）
        let (applicationsDirectory, installToUserApplications) = PreferredInstallLocation()
        let bundleName = bundleNameURL!.lastPathComponent
        let destinationURL = applicationsDirectory!.appendingPathComponent(bundleName)
        
        // 检查是否需要管理员权限进行写入
        let isWritableFileSrc = fileManager.isWritableFile(atPath: applicationsDirectory!.absoluteString)
        let isFileExists =  fileManager.fileExists(atPath: destinationURL.absoluteString)
        let isWritableFileDst = fileManager.isWritableFile(atPath: destinationURL.absoluteString)
        
        let isNeedAuthorization = isWritableFileSrc == false || (isFileExists == true && isWritableFileDst == false)
        
        // 构建提示对话框
        let alert = NSAlert()
        alert.messageText = installToUserApplications ? moveStrings.questionTitleHome : moveStrings.questionTitle
        var informativeText = moveStrings.questionMessage
        
        if isNeedAuthorization == true {
            //informativeText += " " + moveStrings.infoNeedsPassword
        } else if LCPathLocationHelper.isInDownloadsFolder(bundleNameURL!) {
            informativeText += " " + moveStrings.infoInDownloads
        }
        
        alert.informativeText = informativeText
        
        // 添加“移动”按钮
        alert.addButton(withTitle: moveStrings.buttonMove)
        
        // 添加“保持不动”按钮，并设置 ESC 快捷键
        let cancelButton = alert.addButton(withTitle: moveStrings.buttonStay)
        cancelButton.keyEquivalent = "\u{1B}"
        
        // 显示“不再提示”复选框
        alert.showsSuppressionButton = true
        
        if UseSmallAlertSuppressCheckbox == true {
            if let cell = alert.suppressionButton?.cell {
                cell.font = NSFont(name: "HelveticaNeue", size: 10)
            }
        }
        
        // 激活应用，防止因系统“未知来源”对话框引起的焦点问题
        if NSApp.isActive == false {
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // 处理用户点击“移动”的情况
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            print("INFO -- Moving myself to the Applications folder")
            
            if isNeedAuthorization == true {
                // 需要管理员权限进行复制
                if authorizedInstall(srcPath: bundlePath, dstPath: destinationURL.absoluteString) == false {
                    print("ERROR -- Could not copy myself to /Applications with authorization")
                    //failureAlert()
                    return
                }
            } else {
                // 如果目标位置已有应用副本，先检查是否正在运行
                if fileManager.fileExists(atPath: destinationURL.absoluteString) {
                    if isApplicationAtPathRunning(path: destinationURL.absoluteString) == true {
                        // 已在运行，切换到已有应用并退出当前实例
                        print("INFO -- Switching to an already running version")
                        Process.launchedProcess(launchPath: "/usr/bin/open", arguments: [destinationURL.absoluteString]).waitUntilExit()
                        exit(0)
                    } else {
                        // 没有运行，尝试移除旧副本
                        let path = applicationsDirectory!.appendingPathComponent(bundleName).absoluteString
                        if LCPathLocationHelper.trash(path: path) == false {
                            let alert = NSAlert()
                            alert.messageText = moveStrings.couldNotMove
                            alert.runModal()
                            return
                        }
                    }
                }
                
                // 执行复制操作
                if copyBundle(srcPath: bundlePath, dstPath: destinationURL.absoluteString) == false {
                    print("Could not copy myself to \(destinationURL.absoluteString)")
                    return
                }
            }
            
            // 尝试删除原始应用副本（非关键）
            if LCPathLocationHelper.deleteOrTrash(path: bundlePath) == false {
                print("WARNING -- Could not delete application after moving it to Applications folder")
            }
            
            // 重新启动应用
            print("relaunch")
            relaunch(destinationPath: destinationURL.absoluteString)
            exit(0)
            
        } else if alert.suppressionButton!.state == .on {
            // 如果用户勾选“不再提示”，则记录偏好
            UserDefaults.standard.set(true, forKey: AlertSuppressKey)
        }
    }
    
}


//MARK: - Private
extension LCAppMoverKit {
    
    /// 判断指定路径下的 app 是否已在运行中
    ///
    /// - Parameter path: app 的路径
    /// - Returns: 如果该路径的应用程序已在运行，返回 true；否则返回 false
    private func isApplicationAtPathRunning(path: String) -> Bool {
        // 遍历当前运行中的所有应用程序
        for runningApplication in NSWorkspace.shared.runningApplications {
            // 获取正在运行的应用的可执行路径
            if let executablePath = runningApplication.executableURL?.path {
                // 判断是否以指定路径作为前缀
                if executablePath.hasPrefix(path) {
                    return true
                }
            }
        }
        return false
    }
    
    
    /// 重新启动当前应用，跳转到指定的路径运行新的副本。
    ///
    /// - Parameter destinationPath: 应用目标路径（通常是 `/Applications/YourApp.app`）
    ///
    /// 该方法执行以下步骤：
    /// 1. 使用 shell 脚本等待当前进程退出。
    /// 2. 移除 com.apple.quarantine 标记（避免二次提示“该程序来自互联网”警告）。
    /// 3. 使用 `open` 命令打开新的目标路径中的应用。
    private func relaunch(destinationPath: String) {
        let pid = ProcessInfo.processInfo.processIdentifier
        
        // 将目标路径进行 Shell 安全转义，避免空格或特殊字符影响命令执行
        let quotedDestinationPath = shellQuotedString(string: destinationPath)
        
        // 移除 quarantine 标志，避免 macOS 再次弹出“来自互联网”的提示
        let preOpenCmd = String(format: "/usr/bin/xattr -d -r com.apple.quarantine %@", quotedDestinationPath)
        
        // 构造 Shell 脚本：
        //  - 等待当前进程完全退出
        //  - 执行 preOpenCmd 清除 quarantine
        //  - 用 `open` 启动新位置的应用
        let script = String(format: "(while /bin/kill -0 %d >&/dev/null; do /bin/sleep 0.1; done; %@; /usr/bin/open %@) &",
                            pid, preOpenCmd, quotedDestinationPath)
        
        Process.launchedProcess(launchPath: "/bin/sh", arguments: ["-c", script])
    }
    
    
    /// 将字符串进行 shell 引号包装和转义（用于安全执行路径）
    ///
    /// - Parameter string: 要转义的字符串
    /// - Returns: 被单引号包裹且安全转义后的字符串
    private func shellQuotedString(string: String) -> String {
        return String(format: "'%@'", string.replacingOccurrences(of: "'", with: "'\\''"))
    }
    
    /// 使用`普通权限``拷贝`一个`应用 bundle` 到`目标路径`。
    ///
    /// - Parameters:
    ///   - srcPath: 源路径（完整的 app 路径）
    ///   - dstPath: 目标路径
    /// - Returns: 拷贝是否成功
    private func copyBundle(srcPath: String, dstPath: String) -> Bool {
        do {
            try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
            return true
        } catch {
            print("ERROR -- Could not copy '\(srcPath)' to '\(dstPath)' (\(error.localizedDescription))")
            // 显示系统级错误对话框提醒用户
            NSAlert(error: error).runModal()
            return false
        }
    }
    
    /// 返回推荐的安装位置（优先选择用户目录中的 ~/Applications）
    ///
    /// - Returns: 元组 (应用程序目录 URL, 是否为用户目录)
    ///            若用户目录下存在 ~/Applications 且其中包含 .app 文件，则认为用户偏好此位置
    private func PreferredInstallLocation() -> (URL?, Bool) {
        
        var appDir: URL?
        var isUserDir = false
        
        // 获取用户域下的 Applications 目录路径
        let userAppDirs = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true)
        if let userDir = userAppDirs.first {
            var directory: ObjCBool = ObjCBool(true)
            
            // 检查该路径是否存在且为目录
            if fileManager.fileExists(atPath: userDir, isDirectory: &directory) {
                // 获取该目录下所有内容
                let contents = (try? fileManager.contentsOfDirectory(atPath: userDir)) ?? []
                
                // 如果其中包含任何 .app 文件，认为用户偏好该目录
                if contents.contains(where: { $0.hasSuffix(".app") }) {
                    appDir = URL(fileURLWithPath: userDir)
                    isUserDir = true
                }
            }
        }
        
        // 如果用户目录无效，则使用系统级 Applications 目录
        if appDir == nil {
            let localLocations = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .localDomainMask, true)
            if let last = localLocations.last {
                appDir = URL(string: last)
            }
        }
        
        return (appDir, isUserDir)
    }
    
    
    /// 使用`管理员权限`将`应用程序`从`源路径`安装到`目标路径`。
    ///
    /// - Parameters:
    ///   - srcPath: 源路径（通常是临时运行路径）
    ///   - dstPath: 目标路径（通常是 /Applications/YourApp.app）
    /// - Returns: 安装是否成功
    private func authorizedInstall(srcPath: String, dstPath: String) -> Bool {
        
        // 确保目标路径是 .app 结尾（避免误删其他内容）
        guard dstPath.hasSuffix(".app") == true else { return false }
        
        // 检查路径是否为空或仅包含空格，避免意外删除或拷贝
        if dstPath.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if srcPath.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        
        // 删除目标位置旧的应用副本（注意：需要管理员权限）
        if LCShellManager.sudoShellCmd(cmd: "/bin/rm", args: "-rf", dstPath) == nil {
            return false
        }
        
        // 拷贝新版本应用到目标路径（保留权限和资源）
        if LCShellManager.sudoShellCmd(cmd: "/bin/cp", args: "-pR", srcPath, dstPath) == nil {
            return false
        }
        return true
    }
    
    
}
