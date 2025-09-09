import Testing
import Foundation
@testable import Freewrite

/// Comprehensive tests for FreewriteTimer service
@MainActor
struct FreewriteTimerTests {
    
    // MARK: - Setup & Teardown
    
    private func createTimer() -> FreewriteTimer {
        return FreewriteTimer()
    }
    
    // MARK: - Initialization Tests
    
    @Test("Timer initializes with default values")
    func testInitialState() async throws {
        let timer = createTimer()
        
        #expect(timer.timeRemaining == FreewriteConstants.defaultTimerDuration)
        #expect(timer.isRunning == false)
        #expect(timer.isFinished == false)
        #expect(timer.formattedTime == "15:00")
    }
    
    // MARK: - Basic Timer Operations
    
    @Test("Start timer changes state correctly")
    func testStartTimer() async throws {
        let timer = createTimer()
        
        timer.start()
        
        #expect(timer.isRunning == true)
        #expect(timer.isFinished == false)
    }
    
    @Test("Cannot start timer when already running")
    func testStartTimerWhenRunning() async throws {
        let timer = createTimer()
        timer.start()
        let initialTime = timer.timeRemaining
        
        timer.start() // Should be ignored
        
        #expect(timer.timeRemaining == initialTime)
        #expect(timer.isRunning == true)
    }
    
    @Test("Pause timer stops execution")
    func testPauseTimer() async throws {
        let timer = createTimer()
        timer.start()
        
        timer.pause()
        
        #expect(timer.isRunning == false)
        #expect(timer.isFinished == false)
    }
    
    @Test("Reset timer restores default duration")
    func testResetTimer() async throws {
        let timer = createTimer()
        timer.adjustTime(by: -300) // Reduce by 5 minutes
        timer.start()
        
        timer.reset()
        
        #expect(timer.timeRemaining == FreewriteConstants.defaultTimerDuration)
        #expect(timer.isRunning == false)
        #expect(timer.isFinished == false)
    }
    
    // MARK: - Time Adjustment Tests
    
    @Test("Adjust time increases duration correctly")
    func testAdjustTimeIncrease() async throws {
        let timer = createTimer()
        let initialTime = timer.timeRemaining
        
        timer.adjustTime(by: 300) // Add 5 minutes
        
        #expect(timer.timeRemaining == initialTime + 300)
    }
    
    @Test("Adjust time decreases duration correctly")  
    func testAdjustTimeDecrease() async throws {
        let timer = createTimer()
        let initialTime = timer.timeRemaining
        
        timer.adjustTime(by: -300) // Subtract 5 minutes
        
        #expect(timer.timeRemaining == initialTime - 300)
    }
    
    @Test("Adjust time respects minimum bound")
    func testAdjustTimeMinimum() async throws {
        let timer = createTimer()
        
        timer.adjustTime(by: -2000) // Try to go negative
        
        #expect(timer.timeRemaining == 0)
    }
    
    @Test("Adjust time respects maximum bound")
    func testAdjustTimeMaximum() async throws {
        let timer = createTimer()
        
        timer.adjustTime(by: 5000) // Try to exceed max
        
        #expect(timer.timeRemaining == FreewriteConstants.maxTimerDuration)
    }
    
    // MARK: - Set Time Tests
    
    @Test("Set time updates duration correctly")
    func testSetTime() async throws {
        let timer = createTimer()
        
        timer.setTime(1800) // 30 minutes
        
        #expect(timer.timeRemaining == 1800)
    }
    
    @Test("Set time clamps to valid range")
    func testSetTimeValidRange() async throws {
        let timer = createTimer()
        
        timer.setTime(-100) // Negative
        #expect(timer.timeRemaining == 0)
        
        timer.setTime(10000) // Too large
        #expect(timer.timeRemaining == FreewriteConstants.maxTimerDuration)
    }
    
    // MARK: - Scroll Adjustment Tests
    
    @Test("Scroll adjustment increases time correctly")
    func testScrollAdjustmentUp() async throws {
        let timer = createTimer()
        let initialTime = timer.timeRemaining
        
        timer.handleScrollAdjustment(deltaY: 15.0) // Scroll up
        
        #expect(timer.timeRemaining == initialTime + (5 * 60)) // +5 minutes
    }
    
    @Test("Scroll adjustment decreases time correctly") 
    func testScrollAdjustmentDown() async throws {
        let timer = createTimer()
        let initialTime = timer.timeRemaining
        
        timer.handleScrollAdjustment(deltaY: -15.0) // Scroll down
        
        #expect(timer.timeRemaining == initialTime - (5 * 60)) // -5 minutes
    }
    
    @Test("Small scroll adjustments are ignored")
    func testSmallScrollIgnored() async throws {
        let timer = createTimer()
        let initialTime = timer.timeRemaining
        
        timer.handleScrollAdjustment(deltaY: 5.0) // Below threshold
        
        #expect(timer.timeRemaining == initialTime) // No change
    }
    
    // MARK: - Formatted Time Tests
    
    @Test("Formatted time displays correctly")
    func testFormattedTime() async throws {
        let timer = createTimer()
        
        timer.setTime(900) // 15:00
        #expect(timer.formattedTime == "15:00")
        
        timer.setTime(125) // 2:05
        #expect(timer.formattedTime == "2:05")
        
        timer.setTime(61) // 1:01
        #expect(timer.formattedTime == "1:01")
        
        timer.setTime(0) // 0:00
        #expect(timer.formattedTime == "0:00")
    }
    
    // MARK: - Timer Finish Behavior Tests
    
    @Test("Timer finishes when reaching zero")
    func testTimerFinish() async throws {
        let timer = createTimer()
        timer.setTime(0)
        timer.start()
        
        // Simulate timer finishing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(timer.isFinished == true)
        #expect(timer.isRunning == false)
        #expect(timer.timeRemaining == 0)
    }
    
    @Test("Adjusting to zero while running triggers finish")
    func testAdjustToZeroWhileRunning() async throws {
        let timer = createTimer()
        timer.start()
        
        timer.adjustTime(by: -timer.timeRemaining) // Set to 0
        
        #expect(timer.isFinished == true)
        #expect(timer.isRunning == false)
    }
    
    // MARK: - Constraint Tests
    
    @Test("Cannot start timer with zero time")
    func testCannotStartWithZeroTime() async throws {
        let timer = createTimer()
        timer.setTime(0)
        
        timer.start()
        
        #expect(timer.isRunning == false)
    }
    
    @Test("Reset to specific duration works correctly")
    func testResetToSpecificDuration() async throws {
        let timer = createTimer()
        
        timer.reset(to: 1200) // 20 minutes
        
        #expect(timer.timeRemaining == 1200)
        #expect(timer.isRunning == false)
        #expect(timer.isFinished == false)
    }
}