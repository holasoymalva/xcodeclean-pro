//
//  MenuBarView.swift
//  XcodeClean Pro
//
//  Created by Antigravity on 03/08/26.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var scanner: XcodeScanner
    @EnvironmentObject var cleaner: XcodeCleaner
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("XcodeClean Pro")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            Text("Espacio recuperable: \(scanner.totalRecoverableSize.formattedByteCount())")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            Divider()
            
            Button(action: {
                Task {
                    await scanner.scanAll()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Escanear ahora")
                }
            }
            
            Button(action: {
                triggerQuickClean()
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Limpieza inteligente")
                }
            }
            .disabled(scanner.isScanning || cleaner.isCleaning || scanner.totalRecoverableSize == 0)
            
            Divider()
            
            Button(action: {
                showMainWindow()
            }) {
                HStack {
                    Image(systemName: "macwindow")
                    Text("Mostrar ventana principal")
                }
            }
            
            Button(action: {
                toggleDesktopWidget()
            }) {
                HStack {
                    Image(systemName: "macwindow.badge.plus")
                    Text("Widget flotante de escritorio")
                }
            }
            
            Divider()
            
            Button(action: {
                NSApp.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Salir de XcodeClean Pro")
                }
            }
        }
    }
    
    private func triggerQuickClean() {
        Task {
            let categories = XcodeCategory.allCases
            _ = await cleaner.clean(categories: categories, selectedSubItems: scanner.subItems)
            await scanner.scanAll()
        }
    }
    
    private func showMainWindow() {
        // En macOS, podemos traer la ventana principal al frente
        if let window = NSApp.windows.first(where: { $0.title == "XcodeClean Pro" && $0.className != "XcodeClean_Pro_Widget" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Si la ventana no existe, creamos una o la mostramos
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    private func toggleDesktopWidget() {
        DesktopWidgetWindow.toggle(scanner: scanner, cleaner: cleaner)
    }
}
