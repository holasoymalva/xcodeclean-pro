//
//  XcodeCleaner.swift
//  XcodeClean Pro
//
//  Created by Antigravity on 03/08/26.
//

import Foundation
import Combine

@MainActor
public class XcodeCleaner: ObservableObject {
    @Published public var isCleaning = false
    @Published public var lastCleanedBytes: Int64 = 0
    @Published public var isCleanCompleted = false
    
    public init() {}
    
    /// Limpia las categorías y sub-items seleccionados. Retorna la cantidad de bytes liberados.
    public func clean(categories: [XcodeCategory], selectedSubItems: [XcodeCategory: [XcodeSubItem]]) async -> Int64 {
        isCleaning = true
        isCleanCompleted = false
        
        // 1. Preparar los datos e historiales en el actor principal para evitar accesos concurrentes prohibidos.
        var subItemPathsToClean: [String] = []
        var foldersToClean: [URL] = []
        var shouldRunSimctl = false
        
        for category in categories {
            if let items = selectedSubItems[category], !items.isEmpty {
                for item in items where item.isSelected {
                    subItemPathsToClean.append(item.path)
                }
            } else {
                foldersToClean.append(contentsOf: category.resolvedPaths)
                if category == .simulators {
                    shouldRunSimctl = true
                }
            }
        }
        
        // 2. Ejecutar la operación de eliminación pesada en segundo plano sin capturar `self`.
        let bytesFreed = await Task.detached(priority: .userInitiated) {
            var totalFreed: Int64 = 0
            let fileManager = FileManager.default
            
            // Eliminar sub-items específicos seleccionados
            for path in subItemPathsToClean {
                if fileManager.fileExists(atPath: path) {
                    let url = URL(fileURLWithPath: path)
                    let size = XcodeCleaner.calculatePathSizeStatic(at: url)
                    do {
                        try fileManager.removeItem(atPath: path)
                        totalFreed += size
                    } catch {
                        print("Error eliminando sub-item en \(path): \(error.localizedDescription)")
                    }
                }
            }
            
            // Eliminar contenido de carpetas completas
            if shouldRunSimctl {
                _ = XcodeCleaner.runSimctlCleanupStatic()
            }
            
            for folderURL in foldersToClean {
                guard fileManager.fileExists(atPath: folderURL.path) else { continue }
                
                let contents = (try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [])) ?? []
                for itemURL in contents {
                    let size = XcodeCleaner.calculatePathSizeStatic(at: itemURL)
                    do {
                        try fileManager.removeItem(at: itemURL)
                        totalFreed += size
                    } catch {
                        print("No se pudo eliminar \(itemURL.path): \(error.localizedDescription)")
                    }
                }
            }
            
            return totalFreed
        }.value
        
        self.lastCleanedBytes = bytesFreed
        self.isCleaning = false
        self.isCleanCompleted = true
        return bytesFreed
    }
    
    /// Ejecuta el comando de Xcode para limpiar simuladores huérfanos o no disponibles
    nonisolated private static func runSimctlCleanupStatic() -> Int64 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "delete", "unavailable"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            print("simctl delete unavailable completado con código: \(process.terminationStatus)")
        } catch {
            print("Error ejecutando simctl: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    /// Helper estático no-aislado para calcular el tamaño de una ruta antes de eliminarla
    nonisolated private static func calculatePathSizeStatic(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            return (attrs?[.size] as? Int64) ?? 0
        }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
}
