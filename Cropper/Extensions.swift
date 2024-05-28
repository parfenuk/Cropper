//
//  Extensions.swift
//  Cropper
//
//  Created by Miraslau Parafeniuk on 28.05.24.
//

import Foundation

extension Double {
    
    func roundedDown(precision k: Int) -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = k
        formatter.maximumFractionDigits = k
        formatter.roundingMode = .floor
        
        return formatter.string(from: NSNumber(floatLiteral: self))!
    }
}
