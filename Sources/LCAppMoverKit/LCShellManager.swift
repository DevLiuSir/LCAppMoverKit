//
//  LCShellManager.swift
//
//  Created by DevLiuSir on 2018/4/26.
//

import Foundation



/// 命令管理器
final class LCShellManager {
    
    /// 使用 AppleScript 以管理员权限执行一个 Shell 命令。
    ///
    /// - Parameters:
    ///   - cmd: 要执行的命令（如 `/bin/mv`）
    ///   - args: 命令的参数数组（如 ["source", "dest"]）
    /// - Returns: 命令执行结果字符串（如有），或 nil
    static func sudoShellCmd(cmd: String, args: String...) -> String? {
        let fullScript = String(format: "'%@' %@", cmd, args.joined(separator: " "))
        let script = String(format: "do shell script \"%@\" with administrator privileges", fullScript)
        
        var errorInfo: NSDictionary?
        if let result = NSAppleScript(source: script)?.executeAndReturnError(&errorInfo).stringValue {
            return result
        }
        
        // 错误处理
        if let errorStr = errorInfo?[NSAppleScript.errorMessage] {
            print("Error running process as administrator: \(errorStr)")
        } else {
            print("Error running process as administrator.")
        }
        return nil
    }
    
    /// 执行指定的命令，忽略其输出结果。
    /// - Parameter command: 要执行的命令字符串。
    static func run(command: String) {
        // 定义 shell 路径
        let shellPath: String
        
        // 根据 macOS 版本动态选择 shell
        if #available(macOS 10.15, *) {
            shellPath = "/bin/zsh" // macOS Catalina 及更高版本
        } else {
            shellPath = "/bin/bash" // macOS Mojave 及更早版本
        }
        
        // 创建一个进程对象，用于执行命令
        let process = Process()
        process.launchPath = shellPath  // 设置进程的启动路径（指定 shell 程序）
        process.arguments = ["-c", command]  // 将命令作为参数传递给 shell
        
        // 启动进程
        process.launch()
        
        // 等待进程结束
        process.waitUntilExit()
    }
    
    
    /// 执行`给定的命令`并返回`输出结果。`
    /// - Parameter command: 要执行的命令。
    /// - Returns: 命令执行后的输出结果。
    static func execute(command: String) -> String {
        // 初始化 Process 对象
        let process = Process()
        
        // 设置操作系统的默认 shell，如 bash 或 zsh
        process.launchPath = "/bin/bash"
        
        // 设置要执行的命令和选项
        process.arguments = ["-c", command]
        
        // 创建管道，以便从子进程中读取输出
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // 启动子进程，等待子进程结束，并等待输出管道有数据
        process.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        // 返回输出结果
        return output ?? ""
    }
    
    /// 执行`远程`命令
    ///
    /// 此方法通过 `NSTask` 在 Bash shell 中执行指定的命令字符串，并返回任务执行状态。
    ///
    /// - Parameter cmd: 要执行的命令字符串。
    /// - Returns: 命令执行的返回状态码，0 表示成功，其他值表示失败。
    @discardableResult
    static func executeRemoteCommand(_ cmd: String) -> Int {
        // 初始化并设置 shell 路径
        let task = Process()
        task.launchPath = "/bin/bash"
        
        // -c 用来执行命令字符串
        task.arguments = ["-c", cmd]
        
        // 新建输出管道作为 Task 的输出
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // 获取文件句柄
        let file = pipe.fileHandleForReading
        
        do {
            // 启动任务
            try task.run()
        } catch {
            // 捕获异常并打印错误信息
            print("exception executeCmd = \(error.localizedDescription)")
            return 100
        }
        
        // 获取运行结果
//        let data = file.readDataToEndOfFile()
        task.waitUntilExit()
        
        // 获取任务终止状态
        let status = task.terminationStatus
        if status == 0 {
            print("\(#function), Task succeeded.")
        } else {
            task.terminate()
            print("\(#function), Task failed.")
        }
        
        file.closeFile()
        return Int(status)
    }
    
    
    
    
    /// `退出`指定的进程
    /// - Parameter pid: 要终止的进程 ID
    static func terminateProcess(pid: Int32) {
        // 设置可执行文件路径，这里是系统的 `kill` 命令
        // 设置命令的参数，`-9` 表示强制终止进程，后跟要终止的进程 ID
        let process = Process()
        process.launchPath = "/bin/kill"
        process.arguments = ["-9", "\(pid)"]
        do {
            try process.run()          // 尝试运行该进程
            process.waitUntilExit()     // 等待子进程执行完成
            // 获取子进程的退出状态码
            let status = process.terminationStatus
            if status == 0 {    // 根据状态码判断是否成功
                print("Process \(pid) terminated successfully.")
            } else {
                print("Failed to terminate process \(pid). Status code: \(status)")
            }
        } catch {
            // 捕获可能的异常并打印错误信息
            print("Error: \(error.localizedDescription)")
        }
    }
    
    
    
}
