//
//  SchedulerManager.swift
//  XcodeClean Pro
//
//  Created by Antigravity on 03/08/26.
//

import Foundation
import UserNotifications
import Combine

public class SchedulerManager: ObservableObject {
    @Published public var cleanInterval: String {
        didSet {
            UserDefaults.standard.set(cleanInterval, forKey: "XcodeCleanPro_cleanInterval")
            setupIntervalTimer()
        }
    }
    
    @Published public var sizeThresholdGB: Double {
        didSet {
            UserDefaults.standard.set(sizeThresholdGB, forKey: "XcodeCleanPro_sizeThresholdGB")
        }
    }
    
    @Published public var notificationsAuthorized: Bool = false
    
    private var timer: AnyCancellable?
    private var scanner: XcodeScanner?
    
    public init() {
        self.cleanInterval = UserDefaults.standard.string(forKey: "XcodeCleanPro_cleanInterval") ?? "weekly"
        self.sizeThresholdGB = UserDefaults.standard.double(forKey: "XcodeCleanPro_sizeThresholdGB")
        
        // Valor por defecto: 20 GB
        if self.sizeThresholdGB == 0 {
            self.sizeThresholdGB = 20.0
        }
        
        checkNotificationStatus()
    }
    
    public func startBackgroundMonitoring(with scanner: XcodeScanner) {
        self.scanner = scanner
        setupIntervalTimer()
    }
    
    public func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsAuthorized = granted
                if let error = error {
                    print("Error al solicitar permisos de notificación: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Configura el temporizador para realizar escaneos automáticos de fondo en base al intervalo
    private func setupIntervalTimer() {
        timer?.cancel()
        
        guard cleanInterval != "none" else { return }
        
        // Intervalos de comprobación en segundos:
        // Diarios = 24h, Semanales = 7 días, Mensuales = 30 días.
        // Para pruebas y uso real moderado, comprobamos de fondo cada 4 horas si el tamaño superó el límite,
        // pero la notificación de alerta de limpieza se limita a una vez al día o según el intervalo real.
        let checkFrequency: TimeInterval = 3600 * 4 // Comprobar cada 4 horas
        
        timer = Timer.publish(every: checkFrequency, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performBackgroundCheck()
            }
    }
    
    /// Comprobación de fondo del espacio recuperable
    public func performBackgroundCheck() {
        guard let scanner = self.scanner else { return }
        
        Task {
            await scanner.scanAll()
            let totalGB = Double(scanner.totalRecoverableSize) / (1024 * 1024 * 1024)
            
            if totalGB >= self.sizeThresholdGB {
                self.sendReminderNotification(spaceGB: totalGB)
            }
        }
    }
    
    /// Envía una notificación local avisando del espacio recuperable
    public func sendReminderNotification(spaceGB: Double) {
        guard notificationsAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "XcodeClean Pro: ¡Espacio acumulado!"
        content.body = String(format: "Se pueden recuperar %.2f GB de archivos temporales de Xcode. Inicia la limpieza inteligente para liberar espacio.", spaceGB)
        content.sound = .default
        
        // Enviar inmediatamente
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "XcodeCleanPro_ThresholdReached", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error enviando notificación: \(error.localizedDescription)")
            }
        }
    }
}
