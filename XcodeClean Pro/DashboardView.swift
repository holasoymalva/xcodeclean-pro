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
    
    @State private var selectedTab: String = "dashboard" // "dashboard", "clean", "program", "settings"
    @State private var showCleanSuccessAlert = false
    @State private var categoryToDetail: XcodeCategory? = nil
    
    // Configuración persistida con AppStorage
    @AppStorage("XcodeCleanPro_autoCleanEnabled") private var autoCleanEnabled = true
    @AppStorage("XcodeCleanPro_autoCleanCategories") private var autoCleanCategoriesData: String = "[\"derivedData\",\"deviceSupport\",\"archives\",\"simulators\",\"buildLogs\"]"
    @AppStorage("XcodeCleanPro_launchAtLogin") private var launchAtLogin = false
    @AppStorage("XcodeCleanPro_menuBarWidgetEnabled") private var menuBarWidgetEnabled = true
    @AppStorage("XcodeCleanPro_confirmBeforeClean") private var confirmBeforeClean = true
    @AppStorage("XcodeCleanPro_forceDarkMode") private var forceDarkMode = false
    
    // Categorías seleccionadas para el borrado en la pestaña "Limpiar"
    @State private var categoriesSelectedToClean: Set<XcodeCategory> = Set(XcodeCategory.allCases)
    
    // Colores Hex
    let colorBg = Color(hex: "0D0D0D")
    let colorSidebar = Color(hex: "090909")
    let colorCard = Color(hex: "131314")
    let colorAccent = Color(hex: "00D2A0") // Verde menta / cian
    
    var body: some View {
        HStack(spacing: 0) {
            // BARRA LATERAL (Sidebar)
            sidebarView
            
            // CONTENIDO PRINCIPAL
            VStack(spacing: 0) {
                // Cabecera común a todas las vistas
                headerView
                
                Divider()
                    .background(Color.white.opacity(0.05))
                
                // Vista de escaneo o contenido de pestaña
                if scanner.isScanning {
                    scanningOverlayView
                } else {
                    tabContentView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorBg)
        }
        .frame(minWidth: 840, minHeight: 560)
        .alert(isPresented: $showCleanSuccessAlert) {
            Alert(
                title: Text("Limpieza completada"),
                message: Text("Se han liberado \(cleaner.lastCleanedBytes.formattedByteCount()) de espacio en disco."),
                dismissButton: .default(Text("Cerrar"))
            )
        }
        .onAppear {
            if scanner.totalRecoverableSize == 0 && !scanner.isScanning {
                Task {
                    await scanner.scanAll()
                }
            }
        }
    }
    
    // MARK: - Cabecera Superior
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tabTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Último escaneo: hace 2 minutos") // Metadato simple como en la captura
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Botón Escanear ahora (en verde menta/cian con texto negro y con viewfinder/scan icon)
            Button(action: {
                Task {
                    await scanner.scanAll()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Escanear ahora")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(colorAccent)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(scanner.isScanning || cleaner.isCleaning)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(colorBg)
    }
    
    // MARK: - Pestañas de Navegación
    @ViewBuilder
    var tabContentView: some View {
        switch selectedTab {
        case "dashboard":
            dashboardTab
        case "clean":
            cleanTab
        case "program":
            programTab
        case "settings":
            settingsTab
        default:
            dashboardTab
        }
    }
    
    // MARK: - Sidebar View
    var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Padding superior para compensar los botones de control de la ventana
            Spacer().frame(height: 38)
            
            // Logo / Header
            VStack(alignment: .leading, spacing: 2) {
                Text("XCODECLEAN")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.5)
                
                Text("Pro v2.4.1")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(colorAccent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            // Botones de Navegación
            VStack(spacing: 4) {
                sidebarButton(title: "Vista General", icon: "macwindow", tab: "dashboard")
                sidebarButton(title: "Limpiar", icon: "trash", tab: "clean")
                sidebarButton(title: "Programar", icon: "clock", tab: "program")
                sidebarButton(title: "Ajustes", icon: "gearshape", tab: "settings")
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Tarjeta Inferior de Almacenamiento "Recuperable ahora"
            sidebarStorageCard
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
        }
        .frame(width: 220)
        .background(colorSidebar)
    }
    
    func sidebarButton(title: String, icon: String, tab: String) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? colorAccent : .gray)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color(hex: "1B1B1C") : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    var sidebarStorageCard: some View {
        let totalBytes = scanner.totalRecoverableSize
        let totalGB = Double(totalBytes) / (1024 * 1024 * 1024)
        let estimatedMaxGB: Double = 80.0
        let progress = min(totalGB / estimatedMaxGB, 1.0)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Recuperable ahora")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f GB", totalGB))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(colorAccent)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colorAccent)
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 6)
            
            Text(String(format: "de %.0f GB estimados", estimatedMaxGB))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(hex: "131314"))
        .cornerRadius(12)
    }
    
    // MARK: - 1. Pestaña Dashboard (Vista General)
    var dashboardTab: some View {
        HStack(spacing: 20) {
            // Columna Izquierda: Gráfico Circular
            VStack {
                ZStack {
                    // Gráfico Segmentado Circular
                    SegmentedRingChart(sizes: scanner.sizes)
                        .frame(width: 140, height: 140)
                    
                    // Texto Central
                    VStack(spacing: 2) {
                        let totalGB = Double(scanner.totalRecoverableSize) / (1024 * 1024 * 1024)
                        Text(String(format: "%.1f", totalGB))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text("GB")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 30)
                
                Text("Total recuperable")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
                
                Spacer()
            }
            .frame(width: 200)
            .background(colorCard)
            .cornerRadius(16)
            
            // Columna Derecha: Tarjetas de Categoría
            VStack(spacing: 12) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(XcodeCategory.allCases) { category in
                            categoryProgressRow(for: category)
                        }
                    }
                }
                
                Spacer().frame(height: 8)
                
                // Botón inferior "Limpiar todo ahora"
                Button(action: {
                    triggerCleanAll()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Limpiar todo ahora ->")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(colorAccent)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(colorAccent.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(cleaner.isCleaning || scanner.totalRecoverableSize == 0)
            }
        }
        .padding(24)
    }
    
    func categoryProgressRow(for category: XcodeCategory) -> some View {
        let size = scanner.sizes[category] ?? 0
        let total = scanner.totalRecoverableSize
        let percentage = total > 0 ? Double(size) / Double(total) : 0.0
        let fileCount = scanner.fileCounts[category] ?? 0
        let dateString = scanner.relativeDates[category] ?? "nunca"
        
        return HStack(spacing: 12) {
            // Icono
            Image(systemName: category.iconName)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: category.colorHex))
                .frame(width: 28, height: 28)
                .background(Color(hex: category.colorHex).opacity(0.12))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(category.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(size.formattedByteCount())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Barra de progreso horizontal
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.05))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: category.colorHex))
                            .frame(width: geo.size.width * CGFloat(percentage))
                    }
                }
                .frame(height: 4)
            }
            
            // Metadatos derecha
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%@ archivos", NumberFormatter.localizedString(from: NSNumber(value: fileCount), number: .decimal)))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(dateString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(14)
        .background(colorCard)
        .cornerRadius(12)
    }
    
    // MARK: - 2. Pestaña Limpiar
    var cleanTab: some View {
        VStack(spacing: 16) {
            // Cabecera de Selección
            HStack {
                Button(action: {
                    if categoriesSelectedToClean.count == XcodeCategory.allCases.count {
                        categoriesSelectedToClean.removeAll()
                    } else {
                        categoriesSelectedToClean = Set(XcodeCategory.allCases)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: categoriesSelectedToClean.count == XcodeCategory.allCases.count ? "checkmark.square.fill" : "square")
                            .foregroundColor(categoriesSelectedToClean.isEmpty ? .secondary : colorAccent)
                        Text("Seleccionar todo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                let selectedBytes = calculateSelectedCleanSize()
                Text(String(format: "%d de 5 seleccionados • %@", categoriesSelectedToClean.count, selectedBytes.formattedByteCount()))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(colorAccent)
            }
            .padding(.horizontal, 8)
            
            // Listado de Categorías con Checkboxes
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(XcodeCategory.allCases) { category in
                        cleanCategoryCard(for: category)
                    }
                }
            }
            
            // Botón de Limpiar Seleccionado
            let selectedBytes = calculateSelectedCleanSize()
            Button(action: {
                triggerCleanSelected()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Limpiar \(selectedBytes.formattedByteCount())")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(selectedBytes == 0 ? Color.gray.opacity(0.3) : colorAccent)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(selectedBytes == 0 || cleaner.isCleaning)
        }
        .padding(24)
    }
    
    func cleanCategoryCard(for category: XcodeCategory) -> some View {
        let isSelected = categoriesSelectedToClean.contains(category)
        let size = scanner.sizes[category] ?? 0
        let fileCount = scanner.fileCounts[category] ?? 0
        
        return Button(action: {
            if isSelected {
                categoriesSelectedToClean.remove(category)
            } else {
                categoriesSelectedToClean.insert(category)
            }
        }) {
            HStack(spacing: 14) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? colorAccent : .gray)
                
                // Icono
                Image(systemName: category.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: category.colorHex))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: category.colorHex).opacity(0.12))
                    .cornerRadius(6)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(category.displayPath)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Tamaño y cantidad de archivos
                VStack(alignment: .trailing, spacing: 2) {
                    Text(size.formattedByteCount())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(String(format: "%@ archivos", NumberFormatter.localizedString(from: NSNumber(value: fileCount), number: .decimal)))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(colorCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? colorAccent.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 3. Pestaña Programar
    var programTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Card 1: Limpieza automática toggle
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $autoCleanEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Limpieza automática")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("Xcode se limpia solo, sin interrumpirte")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: colorAccent))
                }
                .padding(16)
                .background(colorCard)
                .cornerRadius(12)
                
                // Card 2: Frecuencia Segmented Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("FRECUENCIA")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 8) {
                        frequencyBarButton(label: "Diario", interval: "daily")
                        frequencyBarButton(label: "Semanal", interval: "weekly")
                        frequencyBarButton(label: "Mensual", interval: "monthly")
                    }
                }
                .padding(16)
                .background(colorCard)
                .cornerRadius(12)
                
                // Card 3: Limpiar automáticamente (Listado de categorías)
                VStack(alignment: .leading, spacing: 12) {
                    Text("LIMPIAR AUTOMÁTICAMENTE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.0)
                    
                    ForEach(XcodeCategory.allCases) { category in
                        let isChecked = isCategoryAutoCleanEnabled(category)
                        
                        Button(action: {
                            toggleCategoryAutoClean(category)
                        }) {
                            HStack {
                                Image(systemName: category.iconName)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: category.colorHex))
                                
                                Text(category.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text((scanner.sizes[category] ?? 0).formattedByteCount())
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 8)
                                
                                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14))
                                    .foregroundColor(isChecked ? colorAccent : .gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(colorCard)
                .cornerRadius(12)
                
                // Card 4: Notificaciones toggle
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $scheduler.notificationsAuthorized) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notificaciones")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("Aviso tras cada limpieza automática")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: colorAccent))
                    .onChange(of: scheduler.notificationsAuthorized) { authorized in
                        if authorized {
                            scheduler.requestNotificationPermission()
                        }
                    }
                }
                .padding(16)
                .background(colorCard)
                .cornerRadius(12)
            }
        }
        .padding(24)
    }
    
    func frequencyBarButton(label: String, interval: String) -> some View {
        let isSelected = scheduler.cleanInterval == interval
        return Button(action: {
            scheduler.cleanInterval = interval
        }) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? colorAccent : Color.white.opacity(0.04))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 4. Pestaña Ajustes
    var settingsTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Card 1: Abrir al iniciar sesión
                settingsToggleRow(title: "Abrir al iniciar sesión", subtitle: "XcodeClean Pro arranca con macOS", isOn: $launchAtLogin)
                
                // Card 2: Widget en barra de menú
                settingsToggleRow(title: "Widget en barra de menú", subtitle: "Muestra espacio recuperable en la menubar", isOn: $menuBarWidgetEnabled)
                
                // Card 3: Confirmar antes de limpiar
                settingsToggleRow(title: "Confirmar antes de limpiar", subtitle: "Pide confirmación antes de borrar archivos", isOn: $confirmBeforeClean)
                
                // Card 4: Modo oscuro al lanzar
                settingsToggleRow(title: "Modo oscuro al lanzar", subtitle: "Fuerza tema oscuro independiente del sistema", isOn: $forceDarkMode)
                
                // Card 5: ZONA PELIGROSA
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("ZONA PELIGROSA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                            .tracking(1.0)
                    }
                    
                    HStack(spacing: 12) {
                        // Reset Config
                        Button(action: {
                            resetAllConfiguration()
                        }) {
                            Text("Resetear configuración")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        // Clean ALL without confirm
                        Button(action: {
                            triggerCleanAllWithoutConfirm()
                        }) {
                            Text("Limpiar TODO sin confirmar")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                        .background(Color.red.opacity(0.02))
                )
                
                Spacer().frame(height: 20)
                
                // Footer
                let osName = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15 ? "Sequoia" : "Sonoma"
                let osVersion = "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)"
                Text("XcodeClean Pro 2.4.1 • macOS \(osVersion) \(osName) • Xcode 26.6")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }
        }
        .padding(24)
    }
    
    func settingsToggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: colorAccent))
        }
        .padding(16)
        .background(colorCard)
        .cornerRadius(12)
    }
    
    // MARK: - 5. Pantalla de Escaneo (Overlay)
    var scanningOverlayView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(scanner.progress))
                    .stroke(colorAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: -90))
                
                Text(String(format: "%.0f%%", scanner.progress * 100))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Finalizing results...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorBg)
    }
    
    // MARK: - Helper getters & setters
    
    var tabTitle: String {
        switch selectedTab {
        case "dashboard": return "Vista General"
        case "clean": return "Limpiar Archivos"
        case "program": return "Limpieza Programada"
        case "settings": return "Ajustes"
        default: return "Vista General"
        }
    }
    
    private func isCategoryAutoCleanEnabled(_ category: XcodeCategory) -> Bool {
        var list: Set<String> = []
        if let data = autoCleanCategoriesData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            list = Set(decoded)
        }
        return list.contains(category.rawValue)
    }
    
    private func toggleCategoryAutoClean(_ category: XcodeCategory) {
        var list: Set<String> = []
        if let data = autoCleanCategoriesData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            list = Set(decoded)
        }
        
        if list.contains(category.rawValue) {
            list.remove(category.rawValue)
        } else {
            list.insert(category.rawValue)
        }
        
        if let data = try? JSONEncoder().encode(Array(list)),
           let str = String(data: data, encoding: .utf8) {
            autoCleanCategoriesData = str
        }
    }
    
    private func calculateSelectedCleanSize() -> Int64 {
        categoriesSelectedToClean.reduce(0) { $0 + (scanner.sizes[$1] ?? 0) }
    }
    
    // MARK: - Operaciones de Limpieza
    
    private func triggerCleanAll() {
        if confirmBeforeClean {
            let alert = NSAlert()
            alert.messageText = "¿Confirmar limpieza total?"
            alert.informativeText = "Se eliminarán de forma definitiva todas las cachés y temporales seleccionados de Xcode."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Limpiar todo")
            alert.addButton(withTitle: "Cancelar")
            
            if alert.runModal() == .alertFirstButtonReturn {
                performCleanAction(categories: XcodeCategory.allCases)
            }
        } else {
            performCleanAction(categories: XcodeCategory.allCases)
        }
    }
    
    private func triggerCleanSelected() {
        let categoriesToClean = Array(categoriesSelectedToClean)
        
        if confirmBeforeClean {
            let alert = NSAlert()
            alert.messageText = "¿Confirmar limpieza seleccionada?"
            alert.informativeText = "Se eliminarán definitivamente los archivos temporales de las categorías seleccionadas."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Limpiar")
            alert.addButton(withTitle: "Cancelar")
            
            if alert.runModal() == .alertFirstButtonReturn {
                performCleanAction(categories: categoriesToClean)
            }
        } else {
            performCleanAction(categories: categoriesToClean)
        }
    }
    
    private func triggerCleanAllWithoutConfirm() {
        performCleanAction(categories: XcodeCategory.allCases)
    }
    
    private func performCleanAction(categories: [XcodeCategory]) {
        Task {
            // Pasamos los sub-items (vacíos para forzar borrado completo de estas categorías)
            let subItemsMapping = [XcodeCategory: [XcodeSubItem]]()
            let freed = await cleaner.clean(categories: categories, selectedSubItems: subItemsMapping)
            if freed > 0 {
                showCleanSuccessAlert = true
            }
            await scanner.scanAll()
        }
    }
    
    private func resetAllConfiguration() {
        autoCleanEnabled = true
        autoCleanCategoriesData = "[\"derivedData\",\"deviceSupport\",\"archives\",\"simulators\",\"buildLogs\"]"
        launchAtLogin = false
        menuBarWidgetEnabled = true
        confirmBeforeClean = true
        forceDarkMode = false
        scheduler.cleanInterval = "weekly"
        scheduler.sizeThresholdGB = 20.0
    }
}

// MARK: - Custom Ring Chart Component
struct SegmentedRingChart: View {
    let sizes: [XcodeCategory: Int64]
    
    struct Segment: Identifiable {
        let id = UUID()
        let start: Double
        let end: Double
        let color: Color
    }
    
    var body: some View {
        let total = sizes.values.reduce(0, +)
        let segments = getSegments(total: total)
        
        ZStack {
            // Fondo oscuro de pista circular
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 16)
            
            if total == 0 {
                // Si está vacío, muestra un arco genérico gris
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 16)
            } else {
                ForEach(segments) { segment in
                    Circle()
                        .trim(from: CGFloat(segment.start), to: CGFloat(segment.end))
                        .stroke(segment.color, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
                        .rotationEffect(Angle(degrees: -90)) // Comenzar a las 12 en punto
                }
            }
        }
    }
    
    private func getSegments(total: Int64) -> [Segment] {
        guard total > 0 else { return [] }
        
        var segments: [Segment] = []
        var currentTrim = 0.0
        
        for category in XcodeCategory.allCases {
            let size = sizes[category] ?? 0
            let percentage = Double(size) / Double(total)
            
            if percentage > 0 {
                segments.append(Segment(
                    start: currentTrim,
                    end: currentTrim + percentage,
                    color: Color(hex: category.colorHex)
                ))
                currentTrim += percentage
            }
        }
        
        return segments
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
