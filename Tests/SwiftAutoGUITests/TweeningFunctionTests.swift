import Testing
import Foundation
@testable import SwiftAutoGUI

@Suite("Tweening Function Tests")
struct TweeningFunctionTests {
    
    @Test("Linear tweening")
    func testLinearTweening() {
        let tween = TweeningFunction.linear
        
        #expect(tween.apply(0.0) == 0.0)
        #expect(tween.apply(0.25) == 0.25)
        #expect(tween.apply(0.5) == 0.5)
        #expect(tween.apply(0.75) == 0.75)
        #expect(tween.apply(1.0) == 1.0)
    }
    
    @Test("Quad tweening functions")
    func testQuadTweening() {
        // EaseInQuad - slow start, fast end
        let easeIn = TweeningFunction.easeInQuad
        #expect(easeIn.apply(0.0) == 0.0)
        #expect(easeIn.apply(0.5) == 0.25)
        #expect(easeIn.apply(1.0) == 1.0)
        
        // EaseOutQuad - fast start, slow end
        let easeOut = TweeningFunction.easeOutQuad
        #expect(easeOut.apply(0.0) == 0.0)
        #expect(easeOut.apply(0.5) == 0.75)
        #expect(easeOut.apply(1.0) == 1.0)
        
        // EaseInOutQuad - slow start and end
        let easeInOut = TweeningFunction.easeInOutQuad
        #expect(easeInOut.apply(0.0) == 0.0)
        #expect(easeInOut.apply(0.25) == 0.125)
        #expect(easeInOut.apply(0.5) == 0.5)
        #expect(easeInOut.apply(0.75) == 0.875)
        #expect(easeInOut.apply(1.0) == 1.0)
    }
    
    @Test("Custom tweening function")
    func testCustomTweening() {
        // Test a custom smooth step function
        let customTween = TweeningFunction.custom { t in
            return t * t * (3 - 2 * t)
        }
        
        #expect(customTween.apply(0.0) == 0.0)
        #expect(customTween.apply(0.5) == 0.5)
        #expect(customTween.apply(1.0) == 1.0)
        
        // Verify it creates a smooth curve
        let midValue = customTween.apply(0.25)
        #expect(midValue > 0.0 && midValue < 0.5)
    }
    
    @Test("Tweening value clamping")
    func testTweeningValueClamping() {
        let tween = TweeningFunction.linear
        
        // Values outside [0, 1] should be clamped
        #expect(tween.apply(-0.5) == 0.0)
        #expect(tween.apply(1.5) == 1.0)
        #expect(tween.apply(-100) == 0.0)
        #expect(tween.apply(100) == 1.0)
    }
    
    @Test("All tweening functions start and end correctly")
    func testAllTweeningFunctionsStartEnd() {
        let allTweens: [TweeningFunction] = [
            .linear,
            .easeInQuad, .easeOutQuad, .easeInOutQuad,
            .easeInCubic, .easeOutCubic, .easeInOutCubic,
            .easeInQuart, .easeOutQuart, .easeInOutQuart,
            .easeInQuint, .easeOutQuint, .easeInOutQuint,
            .easeInSine, .easeOutSine, .easeInOutSine,
            .easeInExpo, .easeOutExpo, .easeInOutExpo,
            .easeInCirc, .easeOutCirc, .easeInOutCirc,
            .easeInElastic, .easeOutElastic, .easeInOutElastic,
            .easeInBack, .easeOutBack, .easeInOutBack,
            .easeInBounce, .easeOutBounce, .easeInOutBounce
        ]
        
        for tween in allTweens {
            // All tweening functions should start at 0 and end at 1
            #expect(abs(tween.apply(0.0) - 0.0) < 0.0001, "Tween should start at 0")
            #expect(abs(tween.apply(1.0) - 1.0) < 0.0001, "Tween should end at 1")
            
            // Values should be in reasonable range (some like back/elastic can go outside [0,1])
            let midValue = tween.apply(0.5)
            #expect(midValue > -0.5 && midValue < 1.5, "Mid-value should be in reasonable range")
        }
    }
    
    @Test("Elastic and back tweening overshoot")
    func testElasticAndBackOvershoot() {
        // Back easing should overshoot slightly
        let backIn = TweeningFunction.easeInBack
        let backOut = TweeningFunction.easeOutBack
        
        // Back ease-in should go negative at the start
        let backInEarly = backIn.apply(0.1)
        #expect(backInEarly < 0.0)
        
        // Back ease-out should go above 1.0 near the end
        let backOutLate = backOut.apply(0.9)
        #expect(backOutLate > 1.0)
    }
}