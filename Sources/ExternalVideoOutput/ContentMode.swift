import Foundation
import CoreImage

/// Content scaling mode for external display output.
public enum ExternalVideoContentMode {
    /// Scale frame to fit within the display bounds, preserving aspect ratio.
    case aspectFit
    /// Scale frame to fill the display bounds, preserving aspect ratio (may crop).
    case aspectFill
}
