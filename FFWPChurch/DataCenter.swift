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

extension UIColor {
    static func fromRGB(rgbValue: Int) -> UIColor {
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0, green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0, blue: CGFloat(rgbValue & 0xFF)/255.0, alpha: 1.0)
    }
    
    static func fromRGBA(rgbValue: Int, alpha: CGFloat) -> UIColor {
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0, green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0, blue: CGFloat(rgbValue & 0xFF)/255.0, alpha: alpha)
    }
}
