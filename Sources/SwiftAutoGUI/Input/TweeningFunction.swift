import Foundation

/// Represents different easing functions for smooth mouse movement animations.
///
/// These functions create natural-looking transitions by varying the speed of movement over time.
/// Each function takes a progress value (0.0 to 1.0) and returns a modified progress value.
public enum TweeningFunction: Sendable {
    // Quad functions (t^2)
    case linear
    case easeInQuad
    case easeOutQuad
    case easeInOutQuad
    
    // Cubic functions (t^3)
    case easeInCubic
    case easeOutCubic
    case easeInOutCubic
    
    // Quart functions (t^4)
    case easeInQuart
    case easeOutQuart
    case easeInOutQuart
    
    // Quint functions (t^5)
    case easeInQuint
    case easeOutQuint
    case easeInOutQuint
    
    // Sine functions
    case easeInSine
    case easeOutSine
    case easeInOutSine
    
    // Exponential functions
    case easeInExpo
    case easeOutExpo
    case easeInOutExpo
    
    // Circular functions
    case easeInCirc
    case easeOutCirc
    case easeInOutCirc
    
    // Elastic functions (spring-like)
    case easeInElastic
    case easeOutElastic
    case easeInOutElastic
    
    // Back functions (overshooting)
    case easeInBack
    case easeOutBack
    case easeInOutBack
    
    // Bounce functions
    case easeInBounce
    case easeOutBounce
    case easeInOutBounce
    
    /// Custom tweening function
    case custom(@Sendable (Double) -> Double)
    
    /// Applies the easing function to a progress value.
    ///
    /// - Parameter t: The input progress value (0.0 to 1.0)
    /// - Returns: The eased progress value
    public func apply(_ t: Double) -> Double {
        let t = max(0, min(1, t)) // Clamp to [0, 1]
        
        switch self {
        case .linear:
            return t
            
        // Quad
        case .easeInQuad:
            return t * t
        case .easeOutQuad:
            return t * (2 - t)
        case .easeInOutQuad:
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
            
        // Cubic
        case .easeInCubic:
            return t * t * t
        case .easeOutCubic:
            return 1 + pow(t - 1, 3)
        case .easeInOutCubic:
            return t < 0.5 ? 4 * t * t * t : 1 + pow(2 * t - 2, 3) / 2
            
        // Quart
        case .easeInQuart:
            return t * t * t * t
        case .easeOutQuart:
            return 1 - pow(1 - t, 4)
        case .easeInOutQuart:
            return t < 0.5 ? 8 * t * t * t * t : 1 - pow(-2 * t + 2, 4) / 2
            
        // Quint
        case .easeInQuint:
            return t * t * t * t * t
        case .easeOutQuint:
            return 1 - pow(1 - t, 5)
        case .easeInOutQuint:
            return t < 0.5 ? 16 * t * t * t * t * t : 1 - pow(-2 * t + 2, 5) / 2
            
        // Sine
        case .easeInSine:
            return 1 - cos((t * Double.pi) / 2)
        case .easeOutSine:
            return sin((t * Double.pi) / 2)
        case .easeInOutSine:
            return -(cos(Double.pi * t) - 1) / 2
            
        // Exponential
        case .easeInExpo:
            return t == 0 ? 0 : pow(2, 10 * t - 10)
        case .easeOutExpo:
            return t == 1 ? 1 : 1 - pow(2, -10 * t)
        case .easeInOutExpo:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            return t < 0.5 ? pow(2, 20 * t - 10) / 2 : (2 - pow(2, -20 * t + 10)) / 2
            
        // Circular
        case .easeInCirc:
            return 1 - sqrt(1 - pow(t, 2))
        case .easeOutCirc:
            return sqrt(1 - pow(t - 1, 2))
        case .easeInOutCirc:
            return t < 0.5 
                ? (1 - sqrt(1 - pow(2 * t, 2))) / 2
                : (sqrt(1 - pow(-2 * t + 2, 2)) + 1) / 2
            
        // Elastic
        case .easeInElastic:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            let c4 = (2 * Double.pi) / 3
            return -pow(2, 10 * t - 10) * sin((t * 10 - 10.75) * c4)
            
        case .easeOutElastic:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            let c4 = (2 * Double.pi) / 3
            return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1
            
        case .easeInOutElastic:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            let c5 = (2 * Double.pi) / 4.5
            return t < 0.5
                ? -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * c5)) / 2
                : (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * c5)) / 2 + 1
            
        // Back
        case .easeInBack:
            let c1 = 1.70158
            let c3 = c1 + 1
            return c3 * t * t * t - c1 * t * t
            
        case .easeOutBack:
            let c1 = 1.70158
            let c3 = c1 + 1
            return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
            
        case .easeInOutBack:
            let c1 = 1.70158
            let c2 = c1 * 1.525
            return t < 0.5
                ? (pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
                : (pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
            
        // Bounce
        case .easeInBounce:
            return 1 - TweeningFunction.easeOutBounce.apply(1 - t)
            
        case .easeOutBounce:
            let n1 = 7.5625
            let d1 = 2.75
            
            if t < 1 / d1 {
                return n1 * t * t
            } else if t < 2 / d1 {
                let t = t - 1.5 / d1
                return n1 * t * t + 0.75
            } else if t < 2.5 / d1 {
                let t = t - 2.25 / d1
                return n1 * t * t + 0.9375
            } else {
                let t = t - 2.625 / d1
                return n1 * t * t + 0.984375
            }
            
        case .easeInOutBounce:
            return t < 0.5
                ? (1 - TweeningFunction.easeOutBounce.apply(1 - 2 * t)) / 2
                : (1 + TweeningFunction.easeOutBounce.apply(2 * t - 1)) / 2
            
        case .custom(let function):
            return function(t)
        }
    }
}