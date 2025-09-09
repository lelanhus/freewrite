import Foundation

/// Timer service implementation for freewriting sessions
@MainActor
@Observable
final class FreewriteTimer: TimerServiceProtocol {
    private(set) var timeRemaining: Int = FreewriteConstants.defaultTimerDuration
    private(set) var isRunning: Bool = false
    private(set) var isFinished: Bool = false
    
    // Simple timer implementation without complex dispatch queues
    private var timer: Timer?
    
    init() {}
    
    deinit {
        // Timer cleanup will be handled by the invalidate call
        // Cannot access MainActor properties from nonisolated deinit
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func start() {
        guard !isRunning && timeRemaining > 0 else { return }
        
        isRunning = true
        isFinished = false
        
        startSystemTimer()
        print("Timer started with \(timeRemaining) seconds remaining")
    }
    
    func pause() {
        guard isRunning else { return }
        
        isRunning = false
        stopSystemTimer()
        print("Timer paused at \(timeRemaining) seconds")
    }
    
    func reset() {
        reset(to: FreewriteConstants.defaultTimerDuration)
    }
    
    func reset(to duration: Int) {
        stopSystemTimer()
        
        timeRemaining = max(0, min(duration, FreewriteConstants.maxTimerDuration))
        isRunning = false
        isFinished = false
        
        print("Timer reset to \(timeRemaining) seconds")
    }
    
    func adjustTime(by seconds: Int) {
        let newTime = timeRemaining + seconds
        let clampedTime = max(0, min(newTime, FreewriteConstants.maxTimerDuration))
        
        timeRemaining = clampedTime
        
        if timeRemaining == 0 && isRunning {
            timerDidFinish()
        }
        
        print("Timer adjusted by \(seconds) seconds, now \(timeRemaining) seconds")
    }
    
    func setTime(_ seconds: Int) {
        let clampedTime = max(0, min(seconds, FreewriteConstants.maxTimerDuration))
        timeRemaining = clampedTime
        
        if timeRemaining == 0 && isRunning {
            timerDidFinish()
        }
        
        print("Timer set to \(timeRemaining) seconds")
    }
    
    /// Handles scroll wheel adjustments (5-minute increments)
    func handleScrollAdjustment(deltaY: CGFloat) {
        let scrollSensitivity: CGFloat = 10.0
        let adjustmentThreshold: CGFloat = scrollSensitivity
        
        if abs(deltaY) >= adjustmentThreshold {
            let direction = deltaY > 0 ? 1 : -1
            let adjustment = direction * FreewriteConstants.timerStepSize * 60 // 5 minutes
            adjustTime(by: adjustment)
        }
    }
    
    // MARK: - Private Methods
    
    private func startSystemTimer() {
        stopSystemTimer() // Ensure no duplicate timers
        
        // Simple timer that runs on main queue to avoid threading issues
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }
    
    private func stopSystemTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timerTick() {
        guard isRunning && timeRemaining > 0 else { return }
        
        timeRemaining -= 1
        
        if timeRemaining <= 0 {
            timerDidFinish()
        }
    }
    
    private func timerDidFinish() {
        stopSystemTimer()
        
        timeRemaining = 0
        isRunning = false
        isFinished = true
        
        print("Timer finished!")
        
        // Post notification for UI updates if needed
        NotificationCenter.default.post(
            name: .timerDidFinish,
            object: self
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let timerDidFinish = Notification.Name("FreewriteTimerDidFinish")
}