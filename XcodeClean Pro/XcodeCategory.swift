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
    case caches
    case spm
    case deviceLogs
    case simulators
    
    public var id: String { self.rawValue }
    
    public var name: String {
        switch self {
        case .derivedData:
            return "Derived Data"
        case .deviceSupport:
            return "Soporte de Dispositivos"
        case .archives:
            return "Archivos de Compilación"
        case .caches:
            return "Cachés de Xcode"
        case .spm:
            return "Cachés de Swift Package Manager"
        case .deviceLogs:
            return "Logs de Dispositivos"
        case .simulators:
            return "Datos de Simuladores"
        }
    }
    
    public var description: String {
        switch self {
        case .derivedData:
            return "Archivos intermedios de compilación, índices y registros generados al compilar tus proyectos. Seguro de borrar, Xcode lo regenera."
        case .deviceSupport:
            return "Datos de soporte para depurar en dispositivos físicos iOS, watchOS, etc. Los archivos para versiones antiguas ocupan gigabytes innecesarios."
        case .archives:
            return "Historial de versiones y compilaciones exportadas (.xcarchive). Borra si no necesitas depurar versiones antiguas de producción."
        case .caches:
            return "Cachés del IDE, documentación descargada e índices globales de Xcode."
        case .spm:
            return "Repositorios Git clonados y dependencias descargadas por Swift Package Manager."
        case .deviceLogs:
            return "Registros de fallos y logs de depuración recolectados de dispositivos físicos conectados."
        case .simulators:
            return "Archivos de estado, cachés y datos de las aplicaciones instaladas en los simuladores de iOS."
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
        case .caches:
            return "icloud.and.arrow.down.fill"
        case .spm:
            return "shippingbox.fill"
        case .deviceLogs:
            return "doc.text.below.ecg.fill"
        case .simulators:
            return "iphone.gen3"
        }
    }
    
    /// Rutas físicas de las carpetas que componen esta categoría.
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
        case .caches:
            return [
                "~/Library/Caches/com.apple.dt.Xcode",
                "~/Library/Developer/Xcode/DocumentationCache"
            ]
        case .spm:
            return ["~/Library/Caches/org.swift.swiftpm"]
        case .deviceLogs:
            return ["~/Library/Developer/Xcode/iOS Device Logs"]
        case .simulators:
            return ["~/Library/Developer/CoreSimulator/Devices"]
        }
    }
    
    /// Rutas absolutas expandiendo la tilde del home (~)
    public var resolvedPaths: [URL] {
        return paths.map { path in
            let expanded = (path as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
    }
}
