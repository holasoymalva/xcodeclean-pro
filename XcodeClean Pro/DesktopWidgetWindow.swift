//
//  DesktopWidgetWindow.swift
//  XcodeClean Pro
//
//  Created by Antigravity on 03/08/26.
//

import Cocoa
import SwiftUI

public class DesktopWidgetWindow: NSWindow {
    public static var shared: DesktopWidgetWindow?
    
    public static func show(scanner: XcodeScanner, cleaner: XcodeCleaner) {
        if let window = shared {
            window.makeKeyAndOrderFront(nil)
        } else {
            let window = DesktopWidgetWindow(scanner: scanner, cleaner: cleaner)
            shared = window
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    public static func hide() {
        shared?.orderOut(nil)
        shared = nil
    }
    
    public static func toggle(scanner: XcodeScanner, cleaner: XcodeCleaner) {
        if shared != nil {
            hide()
        } else {
            show(scanner: scanner, cleaner: cleaner)
        }
    }
    
    private init(scanner: XcodeScanner, cleaner: XcodeCleaner) {
        let view = DesktopWidgetView()
            .environmentObject(scanner)
            .environmentObject(cleaner)
        
        let hostingController = NSHostingController(rootView: view)
        
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 260, height: 130),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.contentViewController = hostingController
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.level = .floating // Flota por encima de las ventanas. Se puede arrastrar
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        self.title = "XcodeClean Pro Widget"
        
        // Posicionar en la esquina superior derecha por defecto
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 280
            let y = screenRect.maxY - 150
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    // Permitir arrastrar la ventana borderless
    public override var canBecomeKey: Bool {
        return true
    }
}

// MARK: - SwiftUI Widget View
struct DesktopWidgetView: View {
    @EnvironmentObject var scanner: XcodeScanner
    @EnvironmentObject var cleaner: XcodeCleaner
    
    @State private var hoverState = false
    @State private var cleanPulsing = false
    
    var body: some View {
        ZStack {
            // Fondo de Glassmorphism Premium
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.75))
                .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .purple.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            
            // Contenido
            HStack(spacing: 12) {
                // Indicador visual izquierdo
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 4)
                        .frame(width: 66, height: 66)
                    
                    Circle()
                        .trim(from: 0, to: scanner.isScanning ? 0.3 : 1.0)
                        .stroke(
                            LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 66, height: 66)
                        .rotationEffect(Angle(degrees: scanner.isScanning ? 360 : 0))
                        .animation(scanner.isScanning ? Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : .default, value: scanner.isScanning)
                    
                    VStack(spacing: 0) {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                            .padding(.bottom, 2)
                        
                        Text("Clean")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 12)
                
                // Texto y botones del widget
                VStack(alignment: .leading, spacing: 4) {
                    Text("Xcode temporal")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(scanner.totalRecoverableSize.formattedByteCount())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer().frame(height: 6)
                    
                    HStack(spacing: 8) {
                        // Botón de cerrar widget flotante
                        Button(action: {
                            DesktopWidgetWindow.hide()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.primary.opacity(0.4))
                                .frame(width: 20, height: 20)
                                .background(Color.primary.opacity(0.05))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        // Botón limpiar rápido
                        Button(action: {
                            triggerQuickClean()
                        }) {
                            Text(cleaner.isCleaning ? "Limpiando..." : "Limpiar")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(scanner.isScanning || cleaner.isCleaning || scanner.totalRecoverableSize == 0)
                    }
                }
                .padding(.trailing, 12)
                
                Spacer()
            }
        }
        .frame(width: 260, height: 130)
        .onAppear {
            if scanner.totalRecoverableSize == 0 && !scanner.isScanning {
                Task {
                    await scanner.scanAll()
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
}

// MARK: - NSVisualEffectView Bridge for SwiftUI Glassmorphism
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
