//
//  Item.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
