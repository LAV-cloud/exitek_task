//
//  exitekApp.swift
//  exitek
//
//  Created by Ромка Бережной on 02.10.2022.
//

import SwiftUI

@main
struct exitekApp: App {
    
    private let coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
        }
    }
}
