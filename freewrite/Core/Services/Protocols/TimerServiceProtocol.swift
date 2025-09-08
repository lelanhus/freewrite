import Foundation

/// Service responsible for managing the freewriting timer
@MainActor
protocol TimerServiceProtocol: Observable, Sendable {
    /// Current time remaining in seconds
    var timeRemaining: Int { get }
    
    /// Whether the timer is currently running
    var isRunning: Bool { get }
    
    /// Whether the timer has finished (reached zero)
    var isFinished: Bool { get }
    
    /// Starts the timer
    func start()
    
    /// Pauses the timer
    func pause()
    
    /// Resets the timer to its default duration
    func reset()
    
    /// Resets the timer to a specific duration
    /// - Parameter duration: Duration in seconds
    func reset(to duration: Int)
    
    /// Adjusts the timer duration by a specific amount
    /// - Parameter seconds: Number of seconds to add (positive) or subtract (negative)
    func adjustTime(by seconds: Int)
    
    /// Sets the timer to a specific time
    /// - Parameter seconds: Time in seconds to set
    func setTime(_ seconds: Int)
    
    /// Gets the formatted time string (MM:SS)
    var formattedTime: String { get }
}