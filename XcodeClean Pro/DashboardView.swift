//
//  DashboardView.swift
//  XcodeClean Pro
//
//  Created by Antigravity on 03/08/26.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var scanner: XcodeScanner
    @EnvironmentObject var cleaner: XcodeCleaner
    @EnvironmentObject var scheduler: SchedulerManager
    
    @State private var selectedTab: String = "scan" // "scan" o "settings"
    @State private var selectedCategoryForDetail: XcodeCategory? = nil
    @State private var searchSubItemQuery = ""
    @State private var rotationAngle: Double = 0.0
    @State private var showCleanSuccessAlert = false
    @State private var showDesktopWidget = false
    
    let accentGradient = Gradient(colors: [Color.indigo, Color.purple, Color.pink])
    
    var body: some View {
        HStack(spacing: 0) {
            // Lateral Navigation Bar
            sidebarView
            
            Divider()
            
            // Main Content Area
            VStack(spacing: 0) {
                if selectedTab == "scan" {
                    scanDashboardView
                } else {
                    settingsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        }
        .frame(minWidth: 780, minHeight: 520)
        .sheet(item: $selectedCategoryForDetail) { category in
            categoryDetailView(for: category)
        }
        .alert(isPresented: $showCleanSuccessAlert) {
            Alert(
                title: Text("¡Limpieza Completada!"),
                message: Text("Se han liberado con éxito \(cleaner.lastCleanedBytes.formattedByteCount()).\n\nTu Mac ahora tiene más espacio libre."),
                dismissButton: .default(Text("Entendido"))
            )
        }
        .onAppear {
            Task {
                await scanner.scanAll()
            }
        }
    }
    
    // MARK: - Sidebar Navigation
    var sidebarView: some View {
        VStack(spacing: 20) {
            // App Logo / Icon
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(gradient: accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                Text("XcodeClean")
                    .font(.system(size: 14, weight: .bold))
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1.5)
                    .background(Color.purple)
                    .cornerRadius(4)
            }
            
            Spacer().frame(height: 20)
            
            // Navigation Buttons
            VStack(spacing: 8) {
                sidebarButton(title: "Dashboard", icon: "square.grid.2x2.fill", tab: "scan")
                sidebarButton(title: "Ajustes", icon: "gearshape.fill", tab: "settings")
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Desktop Widget Toggle
            Button(action: {
                toggleDesktopWidget()
            }) {
                HStack {
                    Image(systemName: showDesktopWidget ? "macwindow.badge.plus" : "macwindow")
                    Text("Widget Flotante")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(showDesktopWidget ? Color.purple.opacity(0.15) : Color.clear)
                .foregroundColor(showDesktopWidget ? .purple : .gray)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(showDesktopWidget ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .frame(width: 150)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
    }
    
    func sidebarButton(title: String, icon: String, tab: String) -> some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundColor(selectedTab == tab ? .white : .primary.opacity(0.7))
            .background(selectedTab == tab ? Color.purple.opacity(0.3) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Scan Dashboard View
    var scanDashboardView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                // Header & Large Gauge
                HStack(spacing: 30) {
                    // Gauge Orb
                    ZStack {
                        // Background glow
                        Circle()
                            .fill(LinearGradient(gradient: accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .opacity(0.08)
                            .frame(width: 140, height: 140)
                            .blur(radius: 10)
                        
                        // Circle track
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                            .frame(width: 130, height: 130)
                        
                        // Active ring
                        Circle()
                            .trim(from: 0.0, to: scanner.isScanning ? 0.3 : 1.0)
                            .stroke(
                                LinearGradient(gradient: accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 130, height: 130)
                            .rotationEffect(Angle(degrees: rotationAngle))
                            .animation(scanner.isScanning ? Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : .default, value: rotationAngle)
                        
                        // Text inside
                        VStack(spacing: 4) {
                            Text(scanner.isScanning ? "Escaneando..." : "Recuperable")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(scanner.totalRecoverableSize.formattedByteCount())
                                .font(.system(size: 20, weight: .bold))
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                        }
                    }
                    .onAppear {
                        if scanner.isScanning {
                            withAnimation {
                                rotationAngle = 360
                            }
                        }
                    }
                    .onChange(of: scanner.isScanning) { scanning in
                        if scanning {
                            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        } else {
                            rotationAngle = 0
                        }
                    }
                    
                    // Welcome & Global buttons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Optimiza tu espacio de desarrollo")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Xcode acumula cachés y temporales masivos que no se eliminan solos. Escanea tu sistema y realiza una limpieza inteligente de forma segura.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        
                        HStack(spacing: 12) {
                            // Scan Button
                            Button(action: {
                                Task {
                                    await scanner.scanAll()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Escanear")
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .disabled(scanner.isScanning || cleaner.isCleaning)
                            
                            // Smart Clean Button
                            Button(action: {
                                triggerSmartClean()
                            }) {
                                HStack {
                                    if cleaner.isCleaning {
                                        ProgressView()
                                            .controlSize(.small)
                                            .padding(.trailing, 4)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text("Limpieza Inteligente")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(
                                    LinearGradient(gradient: accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(8)
                                .shadow(color: Color.purple.opacity(0.2), radius: 5, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                            .disabled(scanner.isScanning || cleaner.isCleaning || scanner.totalRecoverableSize == 0)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Categories Grid/List
                VStack(alignment: .leading, spacing: 14) {
                    Text("Detalle de almacenamiento")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 400))], spacing: 16) {
                        ForEach(XcodeCategory.allCases) { category in
                            categoryCard(for: category)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Category Card Component
    func categoryCard(for category: XcodeCategory) -> some View {
        let size = scanner.sizes[category] ?? 0
        let subItemsCount = scanner.subItems[category]?.count ?? 0
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(size.formattedByteCount())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Details button
                if category == .derivedData || category == .deviceSupport || category == .archives {
                    Button(action: {
                        selectedCategoryForDetail = category
                    }) {
                        Text("Detalles (\(subItemsCount))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.purple)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(category.description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(height: 32, alignment: .topLeading)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
    
    // MARK: - Settings View
    var settingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Configuración de XcodeClean Pro")
                    .font(.system(size: 18, weight: .bold))
                
                VStack(alignment: .leading, spacing: 16) {
                    // Periodic reminders settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Programación de Limpiezas")
                            .font(.system(size: 13, weight: .bold))
                        
                        Text("Elige con qué frecuencia te gustaría recibir recordatorios para optimizar el almacenamiento de Xcode.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $scheduler.cleanInterval) {
                            Text("No programar").tag("none")
                            Text("Diario").tag("daily")
                            Text("Semanal").tag("weekly")
                            Text("Mensual").tag("monthly")
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                    }
                    
                    Divider()
                    
                    // Space threshold settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Límite de Advertencia de Espacio: \(Int(scheduler.sizeThresholdGB)) GB")
                            .font(.system(size: 13, weight: .bold))
                        
                        Text("Te notificaremos cuando el espacio recuperable acumulado de Xcode supere este límite.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $scheduler.sizeThresholdGB, in: 5...100, step: 5)
                            .accentColor(.purple)
                    }
                    
                    Divider()
                    
                    // Notifications authorization
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Permiso de Notificaciones")
                                .font(.system(size: 13, weight: .bold))
                            
                            Spacer()
                            
                            if scheduler.notificationsAuthorized {
                                Text("Autorizado")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            } else {
                                Button("Permitir") {
                                    scheduler.requestNotificationPermission()
                                }
                                .font(.system(size: 11))
                            }
                        }
                        
                        Text("Para recibir alertas de espacio excedido de fondo, XcodeClean Pro requiere autorización de notificaciones locales de macOS.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(24)
        }
    }
    
    // MARK: - Category Detail Modal Sheet
    func categoryDetailView(for category: XcodeCategory) -> some View {
        let items = scanner.subItems[category] ?? []
        
        let filteredItems = items.filter { item in
            searchSubItemQuery.isEmpty || item.name.localizedCaseInsensitiveContains(searchSubItemQuery)
        }
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 16, weight: .bold))
                    Text(category.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Cerrar") {
                    selectedCategoryForDetail = nil
                    searchSubItemQuery = ""
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Search & Selection controls
            HStack {
                TextField("Buscar...", text: $searchSubItemQuery)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                Spacer()
                
                Button("Seleccionar todo") {
                    setAllSubItems(selected: true, for: category)
                }
                .buttonStyle(.link)
                
                Button("Deseleccionar todo") {
                    setAllSubItems(selected: false, for: category)
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            // List of items
            List {
                if filteredItems.isEmpty {
                    Text("No hay elementos disponibles.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(filteredItems) { item in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { item.isSelected },
                                set: { newValue in
                                    toggleSubItemSelection(item, category: category, isSelected: newValue)
                                }
                            ))
                            .toggleStyle(.checkbox)
                            
                            Text(item.name)
                                .font(.system(size: 12))
                            
                            Spacer()
                            
                            Text(item.size.formattedByteCount())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            Divider()
            
            // Actions
            HStack {
                let selectedSize = calculateSelectedSize(for: category)
                Text("Seleccionado: \(selectedSize.formattedByteCount())")
                    .font(.system(size: 12, weight: .semibold))
                
                Spacer()
                
                Button("Eliminar Seleccionados") {
                    triggerSelectiveClean(category: category)
                }
                .disabled(selectedSize == 0 || cleaner.isCleaning)
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(selectedSize == 0 ? Color.gray.opacity(0.3) : Color.purple)
                .cornerRadius(6)
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 400)
    }
    
    // MARK: - Helper Lógica de Interfaz
    
    private func setAllSubItems(selected: Bool, for category: XcodeCategory) {
        guard var items = scanner.subItems[category] else { return }
        for i in 0..<items.count {
            items[i].isSelected = selected
        }
        scanner.subItems[category] = items
    }
    
    private func toggleSubItemSelection(_ item: XcodeSubItem, category: XcodeCategory, isSelected: Bool) {
        guard var items = scanner.subItems[category] else { return }
        if let index = items.firstIndex(where: { $0.path == item.path }) {
            items[index].isSelected = isSelected
            scanner.subItems[category] = items
        }
    }
    
    private func calculateSelectedSize(for category: XcodeCategory) -> Int64 {
        let items = scanner.subItems[category] ?? []
        return items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    private func triggerSmartClean() {
        Task {
            // Smart Clean limpia todos los elementos marcados en todas las categorías
            let categories = XcodeCategory.allCases
            let bytesCleaned = await cleaner.clean(categories: categories, selectedSubItems: scanner.subItems)
            if bytesCleaned > 0 {
                showCleanSuccessAlert = true
            }
            await scanner.scanAll()
        }
    }
    
    private func triggerSelectiveClean(category: XcodeCategory) {
        Task {
            let bytesCleaned = await cleaner.clean(categories: [category], selectedSubItems: scanner.subItems)
            selectedCategoryForDetail = nil
            if bytesCleaned > 0 {
                showCleanSuccessAlert = true
            }
            await scanner.scanAll()
        }
    }
    
    private func toggleDesktopWidget() {
        // Toggle la ventana del Widget flotante de escritorio
        NotificationCenter.default.post(name: NSNotification.Name("ToggleXcodeCleanProWidget"), object: nil)
        showDesktopWidget.toggle()
    }
}

// MARK: - Byte Formatting Extensions
extension Int64 {
    func formattedByteCount() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}
