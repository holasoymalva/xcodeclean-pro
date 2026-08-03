//
//  XcodeClean_ProApp.swift
//  XcodeClean Pro
//
//  Created by Malva on 03/08/26.
//

import SwiftUI

@main
struct XcodeClean_ProApp: App {
    @StateObject private var scanner = XcodeScanner()
    @StateObject private var cleaner = XcodeCleaner()
    @StateObject private var scheduler = SchedulerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanner)
                .environmentObject(cleaner)
                .environmentObject(scheduler)
                .onAppear {
                    // Inicializar monitoreo en segundo plano
                    scheduler.startBackgroundMonitoring(with: scanner)
                    // Solicitar permiso de notificación amigablemente
                    scheduler.requestNotificationPermission()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleXcodeCleanProWidget"))) { _ in
                    DesktopWidgetWindow.toggle(scanner: scanner, cleaner: cleaner)
                }
                .navigationTitle("XcodeClean Pro")
        }
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra {
            MenuBarView()
                .environmentObject(scanner)
                .environmentObject(cleaner)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "paintbrush.fill")
                Text(scanner.totalRecoverableSize == 0 ? "XcodeClean" : scanner.totalRecoverableSize.formattedByteCount())
            }
        }
    }
}
