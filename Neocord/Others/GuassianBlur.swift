import UIKit
import QuartzCore

public func applyGaussianBlur(to layer: CALayer, radius: CGFloat) {
    // Get the CAFilter class dynamically
    guard let CAFilterClass = NSClassFromString("CAFilter") as AnyObject as? NSObjectProtocol else {
        print("CAFilter not available")
        return
    }

    // Create a Gaussian blur filter
    let blurFilter = CAFilterClass.perform(NSSelectorFromString("filterWithName:"), with: "gaussianBlur")?.takeUnretainedValue()

    // Set the blur radius
    blurFilter?.perform(NSSelectorFromString("setValue:forKey:"), with: radius, with: "inputRadius")

    // Apply the filter to the layer
    layer.setValue([blurFilter as Any].compactMap { $0 }, forKey: "filters")
}



import UIKit
import QuartzCore

/// Apply a variable blur to any CALayer using a gradient mask
/// - Parameters:
///   - layer: The CALayer to blur
///   - gradientMask: UIImage where alpha determines blur intensity (1 = max blur, 0 = no blur)
///   - maxBlurRadius: Maximum blur radius
public func applyVariableBlur(to layer: CALayer, gradientMask: UIImage, maxBlurRadius: CGFloat = 20) {
    guard let gradientImageRef = gradientMask.cgImage else {
        print("Invalid gradient mask")
        return
    }

    // Dynamically access CAFilter
    guard let CAFilterClass = NSClassFromString("CAFilter") as? NSObject.Type,
          let variableBlur = CAFilterClass
            .perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?
            .takeUnretainedValue() as? NSObject else {
        print("CAFilter or variableBlur not available")
        return
    }

    // Configure the filter
    variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
    variableBlur.setValue(gradientImageRef, forKey: "inputMaskImage")
    variableBlur.setValue(true, forKey: "inputNormalizeEdges")

    // Apply to the layer
    layer.filters = [variableBlur]
}
