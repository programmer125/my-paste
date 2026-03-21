import AppKit
import ApplicationServices
import Foundation

protocol CaretLocator {
    func currentAnchorPoint() -> CGPoint?
}

final class AccessibilityCaretLocator: CaretLocator {
    func currentAnchorPoint() -> CGPoint? {
        guard AXIsProcessTrusted() else { return nil }
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedObject: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedObject
        )

        guard focusedResult == .success,
              let focusedObject,
              CFGetTypeID(focusedObject) == AXUIElementGetTypeID() else {
            return nil
        }

        let focusedElement = unsafeDowncast(focusedObject, to: AXUIElement.self)

        if let point = pointFromSelectedRange(focusedElement) {
            return point
        }

        return pointFromElementFrame(focusedElement)
    }

    private func pointFromSelectedRange(_ element: AXUIElement) -> CGPoint? {
        var selectedRangeValue: CFTypeRef?
        let selectedRangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRangeValue
        )

        guard selectedRangeResult == .success,
              let selectedRangeValue,
              CFGetTypeID(selectedRangeValue) == AXValueGetTypeID() else {
            return nil
        }

        let selectedAXValue = unsafeDowncast(selectedRangeValue, to: AXValue.self)
        guard AXValueGetType(selectedAXValue) == .cfRange else { return nil }

        var selectedRange = CFRange()
        AXValueGetValue(selectedAXValue, .cfRange, &selectedRange)

        guard let rangeAXValue = AXValueCreate(.cfRange, &selectedRange) else {
            return nil
        }

        var boundsValue: CFTypeRef?
        let boundsResult = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeAXValue,
            &boundsValue
        )

        guard boundsResult == .success,
              let boundsValue,
              CFGetTypeID(boundsValue) == AXValueGetTypeID() else {
            return nil
        }

        let boundsAXValue = unsafeDowncast(boundsValue, to: AXValue.self)
        guard AXValueGetType(boundsAXValue) == .cgRect else { return nil }

        var rect = CGRect.zero
        AXValueGetValue(boundsAXValue, .cgRect, &rect)
        let converted = convertAXRectToAppKit(rect)
        return CGPoint(x: converted.midX, y: converted.minY)
    }

    private func pointFromElementFrame(_ element: AXUIElement) -> CGPoint? {
        var positionValue: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        )

        var sizeValue: CFTypeRef?
        let sizeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            &sizeValue
        )

        guard positionResult == .success,
              sizeResult == .success,
              let positionValue,
              let sizeValue,
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID() else {
            return nil
        }

        let positionAXValue = unsafeDowncast(positionValue, to: AXValue.self)
        let sizeAXValue = unsafeDowncast(sizeValue, to: AXValue.self)
        guard AXValueGetType(positionAXValue) == .cgPoint,
              AXValueGetType(sizeAXValue) == .cgSize else { return nil }

        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionAXValue, .cgPoint, &origin)
        AXValueGetValue(sizeAXValue, .cgSize, &size)
        let rect = CGRect(origin: origin, size: size)
        let converted = convertAXRectToAppKit(rect)
        return CGPoint(x: converted.midX, y: converted.midY)
    }

    private func convertAXRectToAppKit(_ rect: CGRect) -> CGRect {
        guard let screen = screen(forAXRect: rect) else { return rect }
        let flippedY = screen.frame.maxY - rect.origin.y - rect.height
        return CGRect(x: rect.origin.x, y: flippedY, width: rect.width, height: rect.height)
    }

    private func screen(forAXRect rect: CGRect) -> NSScreen? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return NSScreen.screens.first { screen in
            screen.frame.minX <= center.x && center.x <= screen.frame.maxX
        } ?? NSScreen.main
    }
}
