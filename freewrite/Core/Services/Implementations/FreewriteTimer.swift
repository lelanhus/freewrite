import Foundation

/// Timer service implementation for freewriting sessions
@MainActor
@Observable
final class FreewriteTimer: TimerServiceProtocol {
    private(set) var timeRemaining: Int = FreewriteConstants.defaultTimerDuration
    private(set) var isRunning: Bool = false
    private(set) var isFinished: Bool = false
    
    // Use more efficient timer implementation to reduce system resource contention
    private var timerSource: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "freewrite.timer", qos: .userInteractive)
    
    init() {}
    
    deinit {
        // Timer will be cleaned up when stopSystemTimer() is called
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
        
        // Use DispatchSourceTimer for more efficient, lower-contention timing
        timerSource = DispatchSource.makeTimerSource(flags: [], queue: timerQueue)
        
        timerSource?.schedule(deadline: .now() + 1.0, repeating: 1.0, leeway: .milliseconds(50))
        
        timerSource?.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.timerTick()
            }
        }
        
        timerSource?.resume()
    }
    
    private func stopSystemTimer() {
        timerSource?.cancel()
        timerSource = nil
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