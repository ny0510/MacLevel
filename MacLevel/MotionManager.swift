import Foundation
import IOKit
import IOKit.hid
import SwiftUI
import AppKit
import Combine

class MotionManager: ObservableObject {
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var isLevel: Bool = false
    
    // Settings
    @AppStorage("calibration_offset_pitch") var offsetPitch: Double = 0.0
    @AppStorage("calibration_offset_roll") var offsetRoll: Double = 0.0
    @AppStorage("is_haptic_enabled") var isHapticEnabled: Bool = true
    @AppStorage("is_background_update_enabled") var isBackgroundUpdateEnabled: Bool = true
    
    // Track UI Visibility
    var isUIVisible: Bool = false
    
    private var manager: IOHIDManager?
    
    // Internal thread-safe sensor storage
    private var lastX: Double = 0.0
    private var lastY: Double = 0.0
    private var lastZ: Double = 1.0
    
    private var updateTimer: AnyCancellable?
    
    init() {
        setupSensor()
        startUpdateTimer()
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.publish(every: 1.0/30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.calculateAndPublish()
            }
    }
    
    func setupSensor() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = manager else { return }
        
        let deviceMatch: [String: Any] = [
            kIOHIDPrimaryUsagePageKey: 0xFF00,
            kIOHIDPrimaryUsageKey: 3
        ]
        
        IOHIDManagerSetDeviceMatching(manager, deviceMatch as CFDictionary)
        
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        IOHIDManagerRegisterInputReportCallback(manager, { (context, result, sender, type, reportID, report, reportLength) in
            guard let context = context else { return }
            let this = Unmanaged<MotionManager>.fromOpaque(context).takeUnretainedValue()
            this.handleReport(report: report, length: reportLength)
        }, context)
        
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        DispatchQueue.global(qos: .background).async {
            self.wakeSPUDrivers()
        }
    }
    
    private func wakeSPUDrivers() {
        let matching = IOServiceMatching("AppleSPUHIDDriver")
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                IORegistryEntrySetCFProperty(service, "SensorPropertyReportingState" as CFString, 1 as CFNumber)
                IORegistryEntrySetCFProperty(service, "SensorPropertyPowerState" as CFString, 1 as CFNumber)
                IORegistryEntrySetCFProperty(service, "ReportInterval" as CFString, 1000 as CFNumber)
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    private func handleReport(report: UnsafeMutablePointer<UInt8>, length: Int) {
        guard length >= 18 else { return }
        let data = UnsafeRawPointer(report)
        
        let x = Double(Int32(littleEndian: data.loadUnaligned(fromByteOffset: 6, as: Int32.self))) / 65536.0
        let y = Double(Int32(littleEndian: data.loadUnaligned(fromByteOffset: 10, as: Int32.self))) / 65536.0
        let z = Double(Int32(littleEndian: data.loadUnaligned(fromByteOffset: 14, as: Int32.self))) / 65536.0
        
        lastX = (x * 0.2) + (lastX * 0.8)
        lastY = (y * 0.2) + (lastY * 0.8)
        lastZ = (z * 0.2) + (lastZ * 0.8)
    }
    
    private func calculateAndPublish() {
        if !isBackgroundUpdateEnabled && !isUIVisible {
            return
        }
        
        let rawRoll = atan2(lastX, sqrt(lastY * lastY + lastZ * lastZ)) * 180.0 / .pi
        let rawPitch = atan2(lastY, sqrt(lastX * lastX + lastZ * lastZ)) * 180.0 / .pi
        
        let newRoll = rawRoll - offsetRoll
        let newPitch = rawPitch - offsetPitch
        
        self.roll = newRoll
        self.pitch = newPitch
        
        let threshold = 0.5
        let currentLevel = abs(self.roll) < threshold && abs(self.pitch) < threshold
        
        if currentLevel && !self.isLevel {
            triggerHaptic()
        }
        self.isLevel = currentLevel
    }
    
    func calibrate() {
        offsetRoll = (roll + offsetRoll)
        offsetPitch = (pitch + offsetPitch)
    }
    
    func resetCalibration() {
        offsetRoll = 0.0
        offsetPitch = 0.0
    }
    
    private func triggerHaptic() {
        if isHapticEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
    }
}
