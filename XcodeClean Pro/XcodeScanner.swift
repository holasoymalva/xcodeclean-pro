//
//  XcodeScanner.swift
//  XcodeClean Pro
//
//  Created by Antigravity on 03/08/26.
//

import Foundation
import Combine

public struct XcodeSubItem: Identifiable, Codable, Equatable {
    public var id: String { path }
    public let name: String
    public let size: Int64
    public let path: String
    public var isSelected: Bool
    
    public init(name: String, size: Int64, path: String, isSelected: Bool = true) {
        self.name = name
        self.size = size
        self.path = path
        self.isSelected = isSelected
    }
}

@MainActor
public class XcodeScanner: ObservableObject {
    @Published public var sizes: [XcodeCategory: Int64] = [:]
    @Published public var subItems: [XcodeCategory: [XcodeSubItem]] = [:]
    @Published public var isScanning = false
    @Published public var progress: Double = 0.0
    
    public init() {
        for category in XcodeCategory.allCases {
            sizes[category] = 0
            subItems[category] = []
        }
    }
    
    public var totalRecoverableSize: Int64 {
        sizes.values.reduce(0, +)
    }
    
    /// Realiza un escaneo asíncrono de todas las categorías
    public func scanAll() async {
        isScanning = true
        progress = 0.0
        
        let categories = XcodeCategory.allCases
        let totalSteps = Double(categories.count)
        
        for (index, category) in categories.enumerated() {
            let sizeAndItems = await scanCategoryInBackground(category)
            
            sizes[category] = sizeAndItems.size
            subItems[category] = sizeAndItems.items
            
            progress = Double(index + 1) / totalSteps
        }
        
        isScanning = false
    }
    
    /// Escanea una sola categoría en segundo plano
    private func scanCategoryInBackground(_ category: XcodeCategory) async -> (size: Int64, items: [XcodeSubItem]) {
        // Extraemos los paths e info en el MainActor para pasarlos con seguridad al thread en segundo plano
        let resolvedPaths = category.resolvedPaths
        
        return await Task.detached(priority: .userInitiated) {
            var totalSize: Int64 = 0
            var items: [XcodeSubItem] = []
            let fileManager = FileManager.default
            
            for folderURL in resolvedPaths {
                guard fileManager.fileExists(atPath: folderURL.path) else { continue }
                
                if category == .derivedData {
                    let contents = (try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)) ?? []
                    for itemURL in contents {
                        let size = XcodeScanner.calculateFolderSizeStatic(at: itemURL)
                        if size > 0 {
                            let name = XcodeScanner.cleanDerivedDataNameStatic(itemURL.lastPathComponent)
                            items.append(XcodeSubItem(name: name, size: size, path: itemURL.path))
                            totalSize += size
                        }
                    }
                } else if category == .deviceSupport {
                    let contents = (try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)) ?? []
                    for itemURL in contents {
                        let size = XcodeScanner.calculateFolderSizeStatic(at: itemURL)
                        if size > 0 {
                            items.append(XcodeSubItem(name: itemURL.lastPathComponent, size: size, path: itemURL.path))
                            totalSize += size
                        }
                    }
                } else if category == .archives {
                    let archivesList = XcodeScanner.findArchivesStatic(at: folderURL)
                    for archive in archivesList {
                        items.append(XcodeSubItem(name: archive.name, size: archive.size, path: archive.path))
                        totalSize += archive.size
                    }
                } else {
                    let size = XcodeScanner.calculateFolderSizeStatic(at: folderURL)
                    totalSize += size
                    if size > 0 {
                        items.append(XcodeSubItem(name: category.name, size: size, path: folderURL.path))
                    }
                }
            }
            
            items.sort { $0.size > $1.size }
            
            return (totalSize, items)
        }.value
    }
    
    /// Calcula el tamaño total de un directorio de forma recursiva (Estático/No-aislado)
    nonisolated private static func calculateFolderSizeStatic(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            return (attrs?[.size] as? Int64) ?? 0
        }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if let isDirectory = resourceValues.isDirectory, !isDirectory,
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                // Silenciar errores
            }
        }
        return totalSize
    }
    
    /// Limpia el nombre crudo de la carpeta de DerivedData para que sea legible (Estático/No-aislado)
    nonisolated private static func cleanDerivedDataNameStatic(_ rawName: String) -> String {
        let parts = rawName.split(separator: "-")
        if parts.count > 1 {
            let potentialHash = String(parts.last!)
            if potentialHash.count >= 20 {
                return parts.dropLast().joined(separator: "-")
            }
        }
        return rawName
    }
    
    /// Estructura interna estática para transferir información de archives
    private struct ArchiveInfoStatic {
        let name: String
        let size: Int64
        let path: String
    }
    
    /// Busca recursivamente archivos .xcarchive (Estático/No-aislado)
    nonisolated private static func findArchivesStatic(at url: URL) -> [ArchiveInfoStatic] {
        let fileManager = FileManager.default
        var results: [ArchiveInfoStatic] = []
        
        let keys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return [] }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "xcarchive" {
                enumerator.skipDescendants()
                let size = calculateFolderSizeStatic(at: fileURL)
                
                let pathComponents = fileURL.pathComponents
                var displayName = fileURL.deletingPathExtension().lastPathComponent
                if pathComponents.count >= 2 {
                    let dateFolder = pathComponents[pathComponents.count - 2]
                    if dateFolder.contains("-") && dateFolder.count >= 8 {
                        displayName += " (\(dateFolder))"
                    }
                }
                
                results.append(ArchiveInfoStatic(name: displayName, size: size, path: fileURL.path))
            }
        }
        return results
    }
}
