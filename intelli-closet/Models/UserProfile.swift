//
//  UserProfile.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import Foundation
import SwiftData

@Model
class UserProfile {
    var id: UUID
    var height: Double?
    var weight: Double?
    @Attribute(.externalStorage) var headshotPhoto: Data?
    @Attribute(.externalStorage) var fullBodyPhoto: Data?

    init(height: Double? = nil, weight: Double? = nil) {
        self.id = UUID()
        self.height = height
        self.weight = weight
    }
}
