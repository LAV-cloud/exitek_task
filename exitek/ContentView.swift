//
//  ContentView.swift
//  exitek
//
//  Created by Ромка Бережной on 02.10.2022.
//

import SwiftUI
import CoreData


protocol CoreDataManagerProtocol {
    var viewContext: NSManagedObjectContext { get }
    
    func fetch<Entity: NSManagedObject>(_ entity: Entity.Type) -> Set<Entity>
    func create<Entity: NSManagedObject>(_ entity: Entity.Type) -> Entity
    func remove(_ object: NSManagedObject) -> Void
    func find<Entity: NSManagedObject>(_ imei: String) -> Set<Entity>
    func save() throws -> Void
}

class CoreDataManager: CoreDataManagerProtocol {
    static let shared: CoreDataManager = CoreDataManager()
    
    private let persistentContainer: NSPersistentContainer = NSPersistentContainer(name: "MobileModel")
    
    var viewContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    private init() {
        self.persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("DEBUG: Core Data failed to load: \(error)")
            }
        }
    }
    
    
    func create<Entity: NSManagedObject>(_ entity: Entity.Type) -> Entity {
        return Entity(context: self.viewContext)
    }
    
    func fetch<Entity: NSManagedObject>(_ entity: Entity.Type) -> Set<Entity> {
        let request: NSFetchRequest<Entity> = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        
        do {
            return Set(try viewContext.fetch(request))
        } catch {
            return []
        }
    }
    
    func find<Entity: NSManagedObject>(_ imei: String) -> Set<Entity> {
        let request: NSFetchRequest<Entity> = NSFetchRequest(entityName: String(describing: Entity.self))
        request.predicate = NSPredicate(format: "imei CONTAINS %@", imei)
        
        do {
            return Set(try viewContext.fetch(request))
        } catch {
            return []
        }
    }
    
    func save() throws {
        do {
            try self.viewContext.save()
        } catch let error {
            self.viewContext.rollback()
            throw error
        }
    }
    
    func remove(_ object: NSManagedObject) -> Void {
        self.viewContext.delete(object)
    }
}

protocol MobileStorageProtocol {
    func getAll() -> Set<Mobile>
    func findByImei(_ imei: String) -> Mobile?
    func save(_ mobile: Mobile) throws -> Mobile
    func delete(_ product: Mobile) throws
    func exists(_ product: Mobile) -> Bool
}

class MobileStorage: MobileStorageProtocol {
    
    private let coreDataManager: CoreDataManagerProtocol
    
    init(coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
    }
    
    func getAll() -> Set<Mobile> {
        let mobiles = coreDataManager.fetch(MobileDeviceData.self)
            .map { Mobile($0) }
        return Set(mobiles)
    }
    
    func findByImei(_ imei: String) -> Mobile? {
        let devices: Set<MobileDeviceData> = coreDataManager.find(imei)
        return devices
            .map { Mobile($0) }
            .first
    }
    
    func save(_ mobile: Mobile) throws -> Mobile {
        do {
            let data: MobileDeviceData = self.coreDataManager.create(MobileDeviceData.self)
            
            data.imei = mobile.imei
            data.model = mobile.model
            
            try self.coreDataManager.save()
            
            return Mobile(data)
        } catch let error {
            throw error
        }
    }
    
    func delete(_ product: Mobile) throws {
        let mobileData: MobileDeviceData? = self.coreDataManager.find(product.imei).first
        
        guard let mobileData = mobileData else {
            throw NSError()
        }
        
        self.coreDataManager.remove(mobileData)
    }
    
    func exists(_ product: Mobile) -> Bool {
        if self.findByImei(product.imei) == nil {
            return false
        }
        return true
    }
    
}

struct Mobile: Hashable {
    let imei: String
    let model: String
    
    init(imei: String, model: String) {
        self.imei = imei
        self.model = model
    }
    
    init(_ data: MobileDeviceData) {
        self.imei = data.imei ?? ""
        self.model = data.model ?? ""
    }
}

struct ContentView: View {
    
    private let thisDevice: Mobile = Mobile(
        imei: UIDevice().identifierForVendor?.uuidString ?? "",
        model: UIDevice().name
    )
    private let mobileStorage: MobileStorageProtocol = MobileStorage()
    @State private var devices: Set<Mobile> = []
    @State private var thisDeviceExists: Bool = false
    
    private func fetchDevices() -> Void {
        if self.mobileStorage.exists(self.thisDevice) {
            thisDeviceExists.on()
        } else {
            thisDeviceExists.off()
        }
        
        self.devices = self.mobileStorage.getAll()
    }
    
    private func onAppear() -> Void {
        self.fetchDevices()
    }
    
    private func save() -> Void {
        do {
            let _: Mobile = try self.mobileStorage.save(self.thisDevice)
            
            DispatchQueue.main.async {
                self.fetchDevices()
            }
        } catch let error {
            print("DEBUG: Error", error.localizedDescription)
        }
    }
    
    private func clear() -> Void {
        self.devices.forEach { device in
            try? self.mobileStorage.delete(device)
        }
        
        self.fetchDevices()
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack {
                if thisDeviceExists == false {
                    Button {
                        self.save()
                    } label: {
                        Text("Save this device")
                    }
                    
                    Divider()
                        .backgroundStyle(Color.gray)
                        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 2, alignment: .center)
                }
                
                GeometryReader { proxy in
                    if devices.isEmpty {
                        VStack(alignment: .center) {
                            Spacer()
                            Text("Devices is Empty")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: UIScreen.main.bounds.width, alignment: .center)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            ForEach(devices.map { $0 }, id: \.self) { mobile in
                                Text("\(mobile.model) - \(mobile.imei)")
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: UIScreen.main.bounds.width, alignment: .leading)
                                    .padding(10)
                            }
                            Text("Total: \(self.devices.count) devices")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if devices.isEmpty == false {
                    Button {
                        self.clear()
                    } label: {
                        Text("Remove all devices")
                    }

                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
        }
        .onAppear { self.onAppear() }
        .edgesIgnoringSafeArea(.all)
    }
}

extension Bool {
    mutating func on() -> Void {
        self = true
    }
    
    mutating func off() -> Void {
        self = false
    }
}
