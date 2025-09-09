import Foundation
@testable import Freewrite

@MainActor
final class MockTimerService: @unchecked Sendable, TimerServiceProtocol {
    private(set) var timeRemaining: Int = 900
    private(set) var isRunning: Bool = false
    private(set) var isFinished: Bool = false
    var shouldFailOperations = false
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func start() {
        guard !isRunning && timeRemaining > 0 else { return }
        isRunning = true
        isFinished = false
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
    }
    
    func reset() {
        reset(to: 900)
    }
    
    func reset(to duration: Int) {
        timeRemaining = max(0, min(duration, 2700))
        isRunning = false
        isFinished = false
    }
    
    func adjustTime(by seconds: Int) {
        let newTime = timeRemaining + seconds
        timeRemaining = max(0, min(newTime, 2700))
        
        if timeRemaining == 0 && isRunning {
            isRunning = false
            isFinished = true
        }
    }
    
    func setTime(_ seconds: Int) {
        timeRemaining = max(0, min(seconds, 2700))
        
        if timeRemaining == 0 && isRunning {
            isRunning = false
            isFinished = true
        }
    }
    
    func handleScrollAdjustment(deltaY: CGFloat) {
        let direction = deltaY > 0 ? 1 : -1
        let adjustment = direction * 5 * 60 // 5 minutes
        adjustTime(by: adjustment)
    }
}