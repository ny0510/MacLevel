import SwiftUI

struct ContentView: View {
    @EnvironmentObject var motion: MotionManager
    
    var body: some View {
        VStack(spacing: 20) {
//            Text("MacLevel")
//                .font(.title)

            // Level Visualization
            ZStack {
                // Outer Ring
                Circle()
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                // Crosshairs (Properly Centered)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 200)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 200, height: 1)
                
                // Horizontal Axis Guide (Bottom)
                Rectangle()
                    .fill(abs(motion.roll) < 0.5 ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 200, height: 4)
                    .cornerRadius(10)
                    .offset(y: 120)
                
                // Horizontal Center Tick
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: 2, height: 10)
                    .offset(y: 120)
                
                // Vertical Axis Guide (Right)
                Rectangle()
                    .fill(abs(motion.pitch) < 0.5 ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 4, height: 200)
                    .cornerRadius(10)
                    .offset(x: 120)
                
                // Vertical Center Tick
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: 10, height: 2)
                    .offset(x: 120)
                
                // Horizontal Axis Indicator
                Circle()
                    .fill(abs(motion.roll) < 0.5 ? Color.green : Color.primary)
                    .frame(width: 10, height: 10)
                    .offset(x: clamp(motion.roll * 8, -100, 100), y: 120)
                
                // Vertical Axis Indicator
                Circle()
                    .fill(abs(motion.pitch) < 0.5 ? Color.green : Color.primary)
                    .frame(width: 10, height: 10)
                    .offset(x: 120, y: clamp(-motion.pitch * 8, -100, 100))
                
                // The Main Bubble
                Circle()
                    .fill(motion.isLevel ? Color.green : Color.red)
                    .frame(width: 30, height: 30)
                    .offset(x: clamp(motion.roll * 8, -100, 100),
                            y: clamp(-motion.pitch * 8, -100, 100))
                    .animation(.interactiveSpring(), value: motion.roll)
                    .animation(.interactiveSpring(), value: motion.pitch)
            }
            .frame(width: 250, height: 250)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Roll")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f°", motion.roll))
                        .font(.system(.body, design: .monospaced))
                }
                
                VStack {
                    Text("Pitch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f°", motion.pitch))
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Divider()
            
            VStack(spacing: 12) {
                Button(action: {
                    motion.calibrate()
                }) {
                    Label("Calibrate (Set to 0°)", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    motion.resetCalibration()
                }) {
                    Text("Reset Calibration")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 5)
                
                Toggle("Haptic Feedback", isOn: $motion.isHapticEnabled)
                
                Toggle("Background Update", isOn: $motion.isBackgroundUpdateEnabled)
            }
            
            Divider()
            
            Button("Quit MacLevel") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            motion.isUIVisible = true
        }
        .onDisappear {
            motion.isUIVisible = false
        }
    }
    
    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> CGFloat {
        return CGFloat(Swift.min(Swift.max(value, min), max))
    }
}

#Preview {
    ContentView()
        .environmentObject(MotionManager())
}
