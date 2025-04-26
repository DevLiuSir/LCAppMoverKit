//
//  Extension.swift
//
//  Created by DevLiuSir on 2018/4/26.
//

import Foundation


extension String {
    
    /// 将当前字符串视为路径，并追加一个路径组件，返回新的完整路径字符串。
    ///
    /// 等效于使用 `URL(fileURLWithPath:)` 并调用 `.appendingPathComponent(_:)`，适用于构建文件路径。
    ///
    /// - Parameter string: 要追加的路径组件。
    /// - Returns: 追加后的完整路径字符串。
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
    }
}
