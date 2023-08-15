//
//  DataCenter.swift
//  FFWPChurch
//
//  Created by JooYoung Kim on 2023/08/14.
//

import Foundation
import UIKit

class DataCenter {
    static let shared = DataCenter()
    
    var isLoadMainView: Bool = false
    var schemeData: [String : String]?
    var userInfo: [AnyHashable : Any]?
    
    private init() { }
    
    public static func writeObjectToDefault(_ value : Any, _ strKey: String)
    {
        UserDefaults.standard.set(value, forKey: strKey)
        UserDefaults.standard.synchronize()
    }
    
    public static func readObjectFromDefault(_ strKey : String) -> Any
    {
        return UserDefaults.standard.object(forKey: strKey) as Any
    }
    
    public static func getStatusBarHeight() -> CGFloat {
#if os(iOS)
        if let window = UIApplication.shared.windows.first {
            let top = window.safeAreaInsets.top
            return top
        }
        return 0
#else
        return 0
#endif
    }

    public static func getSafeAreaBottom() -> CGFloat {
#if os(iOS)
        if let window = UIApplication.shared.windows.first {
            let bot = window.safeAreaInsets.bottom
            return bot
        }
        return 0
#else
        return 0
#endif
    }

}
