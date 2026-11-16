import SwiftUI

extension CGFloat {
    static func lerp(_ a: CGFloat, _ b: CGFloat, t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
}

func clamp<T: Comparable>(_ value: T, min minVal: T, max maxVal: T) -> T {
    return min(max(value, minVal), maxVal)
}
