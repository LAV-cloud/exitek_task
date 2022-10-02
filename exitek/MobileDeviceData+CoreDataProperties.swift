//
//  MobileDeviceData+CoreDataProperties.swift
//  exitek
//
//  Created by Ромка Бережной on 02.10.2022.
//
//

import Foundation
import CoreData


extension MobileDeviceData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MobileDeviceData> {
        return NSFetchRequest<MobileDeviceData>(entityName: "MobileDeviceData")
    }

    @NSManaged public var imei: String?
    @NSManaged public var model: String?

}

extension MobileDeviceData : Identifiable {

}
