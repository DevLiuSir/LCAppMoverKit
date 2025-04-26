//
//  LCPathLocationHelper.swift
//
//  Created by DevLiuSir on 2018/4/26.
//

import Foundation
import Cocoa


/// 路径位置判断辅助类（判断路径是否在“应用程序”、“下载”等系统目录下）
final class LCPathLocationHelper {
    
    static let fileManager = LCAppMoverKit.shared.fileManager
    
    
    /// 将`指定路径`的文件或文件夹`移动到废纸篓（Trash）`
    ///
    /// - Parameter path: 要移动到废纸篓的文件路径
    /// - Returns: 是否成功移动到废纸篓
    static func trash(path: String) -> Bool {
        let pathURL = URL(fileURLWithPath: path)
        
        do {
            // 尝试将文件移动到系统废纸篓
            try fileManager.trashItem(at: pathURL, resultingItemURL: nil)
        } catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
            print("ERROR -- Could not trash \(path)")
            return false
        }
        
        return true
    }
    
    
    /// 删除`指定路径`的文件或文件夹；如果删除失败，则尝试移至废纸篓
    ///
    /// - Parameter path: 要删除的文件路径
    /// - Returns: 是否成功删除或移动到废纸篓
    static func deleteOrTrash(path: String) -> Bool {
        do {
            // 尝试直接删除文件或目录
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            // 删除失败，打印警告信息并弹出错误提示
            print("WARNING -- Could not delete '\(path)': \(error.localizedDescription)")
            NSAlert(error: error).runModal()
            
            // 删除失败时尝试将其移至废纸篓
            return trash(path: path)
        }
    }
    
    /// 判断某个路径是否在指定的系统文件夹中，例如“应用程序”、“下载”等。
    ///
    /// - Parameters:
    ///   - path: 要检查的文件路径（URL类型）。
    ///   - folder: 系统文件夹类型（如 .applicationDirectory）。
    ///   - alternativeName: 可选的备用文件夹名称（仅字符串匹配路径组件）。
    /// - Returns: 如果路径在目标文件夹中，返回 true。
    public static func IsInFolder(_ path: URL, _ folder: FileManager.SearchPathDirectory, _ alternativeName: String? = nil) -> Bool {
        let allFolders = NSSearchPathForDirectoriesInDomains(folder, .allDomainsMask, true)
        let pathstr = path.path
        for folder in allFolders {
            if pathstr.hasPrefix(folder) {
                return true
            }
        }
        
        // 如果没有匹配到标准路径，可通过提供的文件夹名称做路径组件匹配
        if let alt = alternativeName {
            let components = (path.path as NSString).pathComponents
            return components.contains(alt)
        }
        return false
    }
    
    /// 判断当前路径是否在“应用程序”文件夹中。
    ///
    /// - Parameter current: 当前应用路径。
    /// - Returns: 如果位于应用程序目录下，返回 true。
    public static func isInApplicationsFolder(_ current: URL) -> Bool {
        return IsInFolder(current, .applicationDirectory, "Applications")
    }
    
    /// 判断当前路径是否在“下载”文件夹中。
    ///
    /// - Parameter current: 当前路径。
    /// - Returns: 如果位于下载目录下，返回 true。
    public static func isInDownloadsFolder(_ current: URL) -> Bool {
        return IsInFolder(current, .downloadsDirectory)
    }
    
    /// 判断字符串路径是否在“下载”文件夹中。
    ///
    /// - Parameter path: 路径字符串。
    /// - Returns: 如果在下载目录下，返回 true。
    private func IsInDownloadsFolder(path: String?) -> Bool {
        let downloadDirs = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .allDomainsMask, true)
        for downloadsDirPath in downloadDirs {
            if path?.hasPrefix(downloadsDirPath) ?? false {
                return true
            }
        }
        return false
    }
    
}
