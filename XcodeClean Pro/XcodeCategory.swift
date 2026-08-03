//
//  XcodeCategory.swift
//  XcodeClean Pro
//
//  Created by Antigravity on 03/08/26.
//

import Foundation

public enum XcodeCategory: String, CaseIterable, Identifiable, Codable {
    case derivedData
    case deviceSupport
    case archives
    case simulators
    case buildLogs
    
    public var id: String { self.rawValue }
    
    public var name: String {
        switch self {
        case .derivedData:
            return "DerivedData"
        case .deviceSupport:
            return "DeviceSupport"
        case .archives:
            return "Archives"
        case .simulators:
            return "Caches de Simulador"
        case .buildLogs:
            return "Logs de Build"
        }
    }
    
    public var description: String {
        switch self {
        case .derivedData:
            return "Archivos intermedios de compilación e índices."
        case .deviceSupport:
            return "Archivos de soporte para dispositivos físicos iOS/watchOS."
        case .archives:
            return "Historial de versiones y compilaciones exportadas."
        case .simulators:
            return "Cachés de estados y datos del simulador de iOS."
        case .buildLogs:
            return "Registros de fallas y logs de compilación de simulación."
        }
    }
    
    public var iconName: String {
        switch self {
        case .derivedData:
            return "hammer.fill"
        case .deviceSupport:
            return "ipad.and.iphone"
        case .archives:
            return "archivebox.fill"
        case .simulators:
            return "square.stack.3d.up.fill"
        case .buildLogs:
            return "folder.fill"
        }
    }
    
    /// Color hexadecimal para la barra de progreso y el gráfico circular
    public var colorHex: String {
        switch self {
        case .derivedData:
            return "FF7A00" // Naranja
        case .deviceSupport:
            return "A155FF" // Púrpura
        case .archives:
            return "3B82F6" // Azul
        case .simulators:
            return "10B981" // Verde menta
        case .buildLogs:
            return "F43F5E" // Rosa
        }
    }
    
    /// Ruta legible para mostrar en la UI
    public var displayPath: String {
        switch self {
        case .derivedData:
            return "~/Library/Developer/Xcode/DerivedData"
        case .deviceSupport:
            return "~/Library/Developer/Xcode/iOS DeviceSupport"
        case .archives:
            return "~/Library/Developer/Xcode/Archives"
        case .simulators:
            return "~/Library/Developer/CoreSimulator"
        case .buildLogs:
            return "~/Library/Logs/CoreSimulator"
        }
    }
    
    /// Rutas físicas de las carpetas a escanear/eliminar
    public var paths: [String] {
        switch self {
        case .derivedData:
            return ["~/Library/Developer/Xcode/DerivedData"]
        case .deviceSupport:
            return [
                "~/Library/Developer/Xcode/iOS DeviceSupport",
                "~/Library/Developer/Xcode/watchOS DeviceSupport",
                "~/Library/Developer/Xcode/tvOS DeviceSupport",
                "~/Library/Developer/Xcode/macOS DeviceSupport"
            ]
        case .archives:
            return ["~/Library/Developer/Xcode/Archives"]
        case .simulators:
            return ["~/Library/Developer/CoreSimulator/Devices"]
        case .buildLogs:
            return [
                "~/Library/Developer/Xcode/iOS Device Logs",
                "~/Library/Logs/CoreSimulator"
            ]
        }
    }
    
    public var resolvedPaths: [URL] {
        return paths.map { path in
            let expanded = (path as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
    }
}

extension Int64 {
    public func formattedByteCount() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}
