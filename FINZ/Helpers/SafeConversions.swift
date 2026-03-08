import Foundation

/// Safe Double → Int conversion that returns 0 for NaN/Infinity
/// instead of crashing the app with a fatal error.
extension Double {
    /// Converts to Int safely, returning 0 if the value is NaN or Infinity.
    var safeInt: Int {
        guard self.isFinite else { return 0 }
        return Int(self)
    }
}

/// Safe CGFloat → Int conversion
#if canImport(CoreGraphics)
import CoreGraphics
extension CGFloat {
    var safeInt: Int {
        guard self.isFinite else { return 0 }
        return Int(self)
    }
}
#endif
