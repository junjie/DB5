//
//  Theme.swift
//  DB5Demo-Swift
//
//  Created by Hon Cheng Muh on 12/1/17.
//  Copyright © 2017 Clean Shaven Apps Pte. Ltd. All rights reserved.
//

import UIKit

public enum TextCaseTransform {
    case none
    case upper
    case lower
}

public func stringIsEmpty(s: String?) -> Bool {
    guard let s = s else {
        return true
    }
    return s.count == 0
}

// Picky. Crashes by design.
public func colorWithHexString(hexString: String?) -> UIColor {
    
    guard let hexString = hexString else {
        return UIColor.black
    }
    if stringIsEmpty(s: hexString) {
        return UIColor.black
    }

    let s: NSMutableString = NSMutableString(string: hexString)
    s.replaceOccurrences(of: "#", with: "", options: NSString.CompareOptions.caseInsensitive, range: NSMakeRange(0, hexString.count))
    CFStringTrimWhitespace(s)
    let redString = s.substring(to: 2)
    let greenString = s.substring(with: NSMakeRange(2, 2))
    let blueString = s.substring(with: NSMakeRange(4, 2))
    
    var r: UInt32 = 0, g: UInt32 = 0, b: UInt32 = 0
    Scanner(string: redString).scanHexInt32(&r)
    Scanner(string: greenString).scanHexInt32(&g)
    Scanner(string: blueString).scanHexInt32(&b)
    
    return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
}

public class Theme: Equatable {
    
    public var name: String
    public var parentTheme: Theme?
    
    internal var themeDictionary: [String: Any]
    
    public init?(name: String, themeDictionary: [String: Any]) {
        self.name = name
        self.themeDictionary = themeDictionary
    }
    
    public static func ==(lhs: Theme, rhs: Theme) -> Bool {
        return lhs.name == rhs.name
    }
    
    // MARK: Lazy Accessors for Cache
    
    internal lazy var colorCache: NSCache<NSString, UIColor> = {
        return NSCache()
    }()
    
    internal lazy var fontCache: NSCache<NSString, UIFont> = {
        return NSCache()
    }()
    
    internal lazy var viewSpecifierCache: NSCache<NSString, ViewSpecifier> = {
        return NSCache()
    }()
    
    internal lazy var navigationBarSpecifierCache: NSCache<NSString, NavigationBarSpecifier> = {
        return NSCache()
    }()
    
    internal lazy var textLabelSpecifierCache: NSCache<NSString, TextLabelSpecifier> = {
        return NSCache()
    }()
    
    // MARK: Basic Methods to Obtain Data from PLIST
    
    public func object(forKey key:String) -> Any? {
        
        let themeDictionary = self.themeDictionary as NSDictionary
        var obj = themeDictionary.value(forKeyPath: key)
        if obj == nil, let parentTheme = self.parentTheme {
            obj = parentTheme.object(forKey: key)
        }
        return obj
    }
    
    public func dictionary(forKey key: String) -> [String: Any]? {
        let obj = self.object(forKey: key) as? [String: Any]
        return obj
    }
    
    public func dictionary(fromObject object:Any?) -> [String: Any]? {
        return object as? [String: Any]
    }
    
    // MARK: Basic Data Types
    
    public func bool(forKey key: String) -> Bool {
        let obj = self.object(forKey: key)
        return self.bool(forObject: obj)
    }
    
    public func bool(forObject object: Any?) -> Bool {
        guard let object = object as? NSNumber else {
            return false
        }
        return object.boolValue
    }
    
    public func string(forKey key: String) -> String? {
        let obj = self.object(forKey: key)
        return self.string(fromObject: obj)
    }
    
    internal func string(fromObject object: Any?) -> String? {
        guard let object = object else {
            return nil
        }
        if let object = object as? String {
            return object
        }
        else if let object = object as? NSNumber {
            return object.stringValue
        }
        return nil
    }
    
    public func integer(forKey key:String) -> Int {
        let obj = self.object(forKey: key)
        return self.integer(fromObject: obj)
    }
    
    public func integer(fromObject object:Any?) -> Int {
        guard let object = object as? NSNumber else {
            return 0
        }
        return object.intValue
    }
    
    public func float(forKey key:String) -> Float {
        let obj = self.object(forKey: key)
        return self.float(fromObject: obj)
    }
    
    internal func float(fromObject object: Any?) -> Float {
        guard let object = object as? NSNumber else {
            return 0
        }
        return object.floatValue
    }
    
    public func timeInterval(forKey key:String) -> TimeInterval {
        let obj = self.object(forKey: key)
        return self.timeInterval(fromObject: obj)
    }
    
    public func timeInterval(fromObject object: Any?) -> TimeInterval {
        guard let object = object as? NSNumber else {
            return 0
        }
        return object.doubleValue
    }
    
    // MARK: Advanced Data Types
    
    public func image(forKey key:String) -> UIImage? {
        guard let imageName = self.string(forKey: key) else {
            return nil
        }
        if stringIsEmpty(s: imageName) {
            return nil
        }
        return UIImage(named: imageName)
    }
    
    public func color(forKey key: String) -> UIColor {
        guard let cachedColor = self.colorCache.object(forKey: key as NSString) else {
            let colorDictionary = self.dictionary(forKey: key)
            let color = self.color(fromDictionary: colorDictionary)
            self.colorCache.setObject(color, forKey: key as NSString)
            return color
        }
        return cachedColor
    }
    
    internal func color(fromDictionary dictionary: [String: Any]?) -> UIColor {

        guard let dictionary = dictionary else {
            return UIColor.black
        }
        
        var color: UIColor?
        let alphaObject = dictionary["alpha"]
        if let hexString = dictionary["hex"] as? String {
            color = colorWithHexString(hexString: hexString)
            if let alphaObject = alphaObject {
                let alpha = self.float(fromObject: alphaObject)
                color = color?.withAlphaComponent(CGFloat(alpha))
            }
        }
        else if let alphaObject = alphaObject {
            let alpha = self.float(fromObject: alphaObject)
            if alpha == 0 {
                color = UIColor.clear
            }
        }
        
        if color == nil {
            color = UIColor.black
        }
        
        return color!
    }
    
    public func edgeInsets(forKey key: String) -> UIEdgeInsets {
        let insetsDictionary = self.dictionary(forKey: key)
        let edgeInsets = self.edgeInsets(fromDictionary: insetsDictionary)
        return edgeInsets
    }
    
    internal func edgeInsets(fromDictionary dictionary: [String: Any]?) -> UIEdgeInsets {
        let left = CGFloat(self.float(fromObject: dictionary?["left"]))
        let top = CGFloat(self.float(fromObject: dictionary?["top"]))
        let right = CGFloat(self.float(fromObject: dictionary?["right"]))
        let bottom = CGFloat(self.float(fromObject: dictionary?["bottom"]))
        
        let edgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        return edgeInsets
    }
    
//    func font(forKey key: String) -> UIFont? {
//    }

    
    public func font(forKey key:String, sizeAdjustment: Float) -> UIFont {
        let cacheKey = key.appendingFormat("_%.2f", sizeAdjustment)
        guard let cachedFont = self.fontCache.object(forKey: cacheKey as NSString) else {
            let fontDictionary = self.dictionary(forKey: key)
            let font = self.font(fromDictionary: fontDictionary, sizeAdjustment: sizeAdjustment)
            self.fontCache.setObject(font, forKey: cacheKey as NSString)
            return font
        }
        return cachedFont
    }
    
    internal func font(fromDictionary dictionary: [String: Any]?, sizeAdjustment: Float) -> UIFont {
        let fontName = self.string(fromObject: dictionary?["name"])
        var fontSize = CGFloat(self.float(fromObject: dictionary?["size"]))
        
        fontSize += CGFloat(sizeAdjustment)
        
        if fontSize < 1.0 {
            fontSize = 15.0
        }
        
        var font: UIFont?
        if let fontName = fontName {
            if stringIsEmpty(s: fontName) {
                font = UIFont.systemFont(ofSize: fontSize)
            }
            else {
                font = UIFont(name: fontName, size: fontSize)
            }
        }

        if font == nil {
            font = UIFont.systemFont(ofSize: fontSize)
        }
        return font!
    }
    
    public func point(forKey key: String) -> CGPoint {
        let dictionary = self.dictionary(forKey: key)
        return self.point(fromDictionary: dictionary)
    }
    
    internal func point(fromDictionary dictionary: [String: Any]?) -> CGPoint {
        let x = CGFloat(self.float(fromObject: dictionary?["x"]))
        let y = CGFloat(self.float(fromObject: dictionary?["y"]))
        let point = CGPoint(x: x, y: y)
        return point
    }
    
    public func size(forKey key: String) -> CGSize {
        let dictionary = self.dictionary(forKey: key)
        return self.size(fromDictionary: dictionary)
    }
    
    internal func size(fromDictionary dictionary: [String: Any]?) -> CGSize {
        let width = CGFloat(self.float(fromObject: dictionary?["width"]))
        let height = CGFloat(self.float(fromObject: dictionary?["height"]))
        let size = CGSize(width: width, height: height)
        return size
    }

    func textCaseTransform(forKey key: String) -> TextCaseTransform {
        let s = self.string(forKey: key)
        return self.textCaseTransform(fromString: s)
    }
    
    internal func textCaseTransform(fromString string: String?) -> TextCaseTransform {
        guard let string = string else {
            return .none
        }
        if string.caseInsensitiveCompare("lowercase") == .orderedSame {
            return .lower
        }
        else if string.caseInsensitiveCompare("uppercase") == .orderedSame {
            return .upper
        }
        return .none
    }
    
    public func viewSpecifier(forKey key: String) -> ViewSpecifier? {
        guard let cachedSpecifier = self.viewSpecifierCache.object(forKey: key as NSString) else {
            let dictionary = self.dictionary(forKey: key)
            let viewSpecifier = self.viewSpecifier(fromDictionary: dictionary)
            if let viewSpecifier = viewSpecifier {
                self.viewSpecifierCache.setObject(viewSpecifier, forKey: key as NSString)
            }
            return viewSpecifier
        }
        return cachedSpecifier
    }
    
    internal func viewSpecifier(fromDictionary dictionary: [String: Any]?) -> ViewSpecifier? {
        guard let dictionary = dictionary else {
            return nil
        }
        
        let viewSpecifier = ViewSpecifier()
        
        let sizeDictionary = self.dictionary(fromObject: dictionary["size"])
        viewSpecifier.size = self.size(fromDictionary: sizeDictionary)
        
        let positionDictionary = self.dictionary(fromObject: dictionary["position"])
        viewSpecifier.position = self.point(fromDictionary: positionDictionary)
        
        if let backgroundColorDictionary = self.dictionary(fromObject: dictionary["backgroundColor"]) {
            viewSpecifier.backgroundColor = self.color(fromDictionary: backgroundColorDictionary)
        }
        
        if let highlightedBackgroundColorDictionary = self.dictionary(fromObject: dictionary["highlightedBackgroundColor"]) {
            viewSpecifier.highlightedBackgroundColor = self.color(fromDictionary: highlightedBackgroundColorDictionary)
        }
		
		if let disabledBackgroundColorDictionary = self.dictionary(fromObject: dictionary["disabledBackgroundColor"]) {
			viewSpecifier.disabledBackgroundColor = self.color(fromDictionary: disabledBackgroundColorDictionary)
		}
        
        let edgeInsetsDictionary = self.dictionary(fromObject: dictionary["padding"])
        viewSpecifier.padding = self.edgeInsets(fromDictionary: edgeInsetsDictionary)
        
        return viewSpecifier
    }

    private func textAlignment(fromObject object: Any?) -> NSTextAlignment {
        var alignmentString = self.string(fromObject: object)
        if !stringIsEmpty(s: alignmentString) {
            alignmentString = alignmentString?.lowercased()
			if let str = alignmentString {
				switch str {
				case "left":
					return .left
				case "center":
					return .center
				case "right":
					return .right
				case "justified":
					return .justified
				case "natural":
					return .natural
				default:
					break
				}
			}
        }
        return .left
    }

    private func lineBreakMode(fromObject object: Any?) -> NSLineBreakMode {
        var linebreakString = self.string(fromObject: object)
        if !stringIsEmpty(s: linebreakString) {
            linebreakString = linebreakString?.lowercased()
            if linebreakString == "wordwrap" {
                return .byWordWrapping
            }
            else if linebreakString == "charwrap" {
                return .byCharWrapping
            }
            else if linebreakString == "clip" {
                return .byClipping
            }
            else if linebreakString == "truncatehead" {
                return .byTruncatingHead
            }
            else if linebreakString == "truncatetail" {
                return .byTruncatingTail
            }
            else if linebreakString == "truncatemiddle" {
                return .byTruncatingMiddle
            }
        }
        return .byTruncatingTail
    }
    
    // MARK: Other Public Helper Methods
    
    public func contains(key: String) -> Bool {
        guard let _ = self.themeDictionary[key] else {
            return false
        }
        return true
    }
    
    public func containsOrInherits(key: String) -> Bool {
        guard let _ = self.object(forKey: key) else {
            return false
        }
        return true
    }
    
    public func clearFontCache() {
        self.fontCache.removeAllObjects()
    }
    
    public func clearColorCache() {
        self.colorCache.removeAllObjects()
    }
    
    public func clearViewSpecifierCache() {
        self.viewSpecifierCache.removeAllObjects()
    }
    
    public func clearNavigationBarSpecifierCache() {
        self.navigationBarSpecifierCache.removeAllObjects()
    }
    
    public func clearTextLabelSpecifierCache() {
        self.textLabelSpecifierCache.removeAllObjects()
    }
}

//class AnimationSpecifier {
//    var delay: TimeInterval = 0
//    var duration: TimeInterval = 0
//    var curve: UIViewAnimationOptions = .curveEaseInOut
//}

//class ViewSpecifier {
//    var size = CGSize.zero
//    var position = CGPoint.zero
//    var backgroundColor: UIColor?
//    var highlightedBackgroundColor: UIColor?
//    var disabledBackgroundColor: UIColor?
//
//    /** Not used when creating a view \c -viewWithViewSpecifierKey:. How padding
//     affect the view to be interpreted by interested party. */
//    var padding = UIEdgeInsets.zero
//
//    func backgroundColor(forState state: UIControlState) -> UIColor? {
//        switch state {
//        case .normal:
//            return backgroundColor
//        case .highlighted:
//            return highlightedBackgroundColor
//        case .disabled:
//            return disabledBackgroundColor
//        default:
//            return nil
//        }
//    }
//}

//class NavigationBarSpecifier {
//    
//    var translucent: Bool = false
//    var barStyle: UIBarStyle = .default
//    var popoverBackgroundColor: UIColor?
//    var barColor: UIColor?
//    var tintColor: UIColor?
//    var titleLabelSpecifier: TextLabelSpecifier?
//    var buttonsLabelSpecifier: TextLabelSpecifier?
//    func apply(toNavigationBar navigationBar: UINavigationBar, containedInClass containingClass: UIAppearanceContainer.Type?) {
//        
//        if let barColor = self.barColor {
//            navigationBar.barTintColor = barColor
//        }
//        if let tintColor = self.tintColor {
//            navigationBar.tintColor = tintColor
//        }
//        
//        navigationBar.isTranslucent = self.translucent
//        
//        if let titleLabelSpecifier = self.titleLabelSpecifier {
//            let attributes = titleLabelSpecifier.attributes(forKeys: [
//                NSAttributedStringKey.font,
//                NSAttributedStringKey.foregroundColor])
//            navigationBar.titleTextAttributes = attributes
//        }
//        
//        if let buttonsLabelSpecifier = self.buttonsLabelSpecifier {
//            let attributes = buttonsLabelSpecifier.attributes(forKeys: [
//                NSAttributedStringKey.font,
//                NSAttributedStringKey.foregroundColor])
//            if let containingClass = containingClass {
//                UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self, containingClass]).setTitleTextAttributes(attributes, for: .normal)
//            }
//            else {
//                UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes(attributes, for: .normal)
//            }
//        }
//    }
//}

//class TextLabelSpecifier {
//    
//    var font: UIFont?
//    var size = CGSize.zero
//    /** If YES, \c size should be ignored when creating a text label from it */
//    var sizeToFit: Bool = false
//    var position = CGPoint.zero
//    /** Default: 1 (single line) */
//    var numberOfLines: Int = 1
//    
//    var paragraphSpacing: Float = 0
//    var paragraphSpacingBefore: Float = 0
//    /// If multiple is > 0, takes precedence over paragraphSpacing
//    var paragraphSpacingMultiple: Float = 0
//    /// If multiple is > 0, takes precedence over paragraphSpacingBefore
//    var paragraphSpacingBeforeMultiple: Float = 0
//    
//    /// Line spacing affect line breaks (\u2028), while paragraph spacing affects paragraph breaks (\u2029). The line spacing is calculated with the font.pointSize multipled by lineSpacingMultiple.
//    var lineSpacingMultiple: Float = 0
//    
//    var alignment: NSTextAlignment = .left
//    var lineBreakMode: NSLineBreakMode = .byWordWrapping
//    var textTransform: TextCaseTransform = .none
//    
//    var color: UIColor?
//    var highlightedColor: UIColor?
//    var disabledColor: UIColor?
//    
//    var backgroundColor: UIColor?
//    var highlightedBackgroundColor: UIColor?
//    var disabledBackgroundColor: UIColor?
//    
//    /** Not used when creating a view \c -labelWithText:specifierKey:sizeAdjustment:
//     How padding affect the text label to be interpreted by interested party. */
//    var padding: UIEdgeInsets?
//    
//    /** Attributes representing the font, color, backgroundColor, alignment and lineBreakMode */
//    var attributes: [NSAttributedStringKey: Any]?
//    
//    func label(withText text: String) -> UILabel {
//        let frame = CGRect(origin: self.position, size: self.size)
//        return self.label(withText: text, frame: frame)
//    }
//    
//    func label(withText text: String, frame: CGRect) -> UILabel {
//        let label = UILabel(frame: frame)
//        self.apply(toLabel: label, withText: text)
//        return label
//    }
//    
//    func transform(text: String) -> String {
//        var transformedText: String
//        switch self.textTransform {
//        case .upper:
//            transformedText = text.uppercased()
//            break
//        case .lower:
//            transformedText = text.lowercased()
//            break
//        case .none:
//            transformedText = text
//            break
//        }
//        return transformedText
//    }
//    
//    private lazy var defaultTextLabelAttributes = {
//        return [NSAttributedStringKey.font,
//                NSAttributedStringKey.foregroundColor,
//                NSAttributedStringKey.backgroundColor,
//                NSAttributedStringKey.paragraphStyle]
//    }()
//    
//    func attributedString(withText text: String, forState state: UIControlState = .normal, generateMissingColorsUsingAlphaOfNormalColors alpha: CGFloat? = nil) -> NSAttributedString {
//        
//        var customForeground: UIColor?
//        var customBackground: UIColor?
//        
//        switch state {
//        case .normal:
//            customForeground = self.color
//            customBackground = self.backgroundColor
//        case .highlighted:
//            customForeground = self.highlightedColor
//            customBackground = self.highlightedBackgroundColor
//        case .disabled:
//            customForeground = self.disabledColor
//            customBackground = self.disabledBackgroundColor
//        default:
//            // We're generating optional custom foreground or background colors.
//            // If an invalid state is provided then we just ignore it and pass
//            // no custom colors
//            break
//        }
//        
//        // Generate missing colors if necessary
//        switch state {
//        case .highlighted, .disabled:
//            if let alpha = alpha {
//                if customForeground == nil, let normalForeground = self.color {
//                    customForeground = normalForeground.withAlphaComponent(alpha)
//                }
//                
//                if customBackground == nil, let normalBackground = self.backgroundColor {
//                    customBackground = normalBackground.withAlphaComponent(alpha)
//                }
//            }
//        default:
//            break
//        }
//        
//        let attributes = self.attributes(forKeys: defaultTextLabelAttributes, customForegroundColor: customForeground, customBackgroundColor: customBackground)
//        
//        return self.attributedString(withText: text, attributes: attributes)
//    }
//    
//    func attributedString(withText text: String, attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
//        let transformedText = self.transform(text: text)
//        return NSAttributedString(string: transformedText, attributes: attributes)
//    }
//    
//    func fontAndColorAttributes() -> [NSAttributedStringKey: Any] {
//        return self.attributes(forKeys: [
//            NSAttributedStringKey.font,
//            NSAttributedStringKey.foregroundColor,
//            NSAttributedStringKey.backgroundColor])
//    }
//    
//    func attributes(forKeys keys: [NSAttributedStringKey], customForegroundColor: UIColor? = nil, customBackgroundColor: UIColor? = nil) -> [NSAttributedStringKey: Any] {
//        var textAttributes: [NSAttributedStringKey: Any] = [:]
//        for key in keys {
//            if key == NSAttributedStringKey.paragraphStyle {
//                if let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle {
//                    
//                    paragraphStyle.lineBreakMode = self.lineBreakMode
//                    paragraphStyle.alignment = self.alignment
//                    
//                    if self.paragraphSpacingMultiple>0, let font = self.font {
//                        paragraphStyle.paragraphSpacing = font.pointSize * CGFloat(self.paragraphSpacingMultiple)
//                    }
//                    else if self.paragraphSpacing>0 {
//                        paragraphStyle.paragraphSpacing = CGFloat(paragraphSpacing)
//                    }
//                    else if self.paragraphSpacingBeforeMultiple>0, let font = self.font {
//                        paragraphStyle.paragraphSpacing = font.pointSize * CGFloat(self.paragraphSpacingBeforeMultiple)
//                    }
//                    else if self.paragraphSpacingBefore>0 {
//                        paragraphStyle.paragraphSpacing = CGFloat(paragraphSpacingBefore)
//                    }
//                    
//                    if self.lineSpacingMultiple>0, let font = self.font {
//                        paragraphStyle.lineSpacing = font.pointSize * CGFloat(self.lineSpacingMultiple)
//                    }
//                    
//                    textAttributes[key] = paragraphStyle
//                }
//            }
//            else if key == NSAttributedStringKey.font {
//                if let font = self.font {
//                    textAttributes[key] = font
//                }
//            }
//            else if key == NSAttributedStringKey.foregroundColor {
//                if let color = customForegroundColor ?? self.color {
//                    textAttributes[key] = color
//                }
//            }
//            else if key == NSAttributedStringKey.backgroundColor {
//                if let backgroundColor =  customBackgroundColor ?? self.backgroundColor {
//                    textAttributes[key] = backgroundColor
//                }
//            }
//            else {
//                assertionFailure("Invalid key \(key) to obtain attribute for")
//            }
//        }
//        
//        return textAttributes
//    }
//    
//    func apply(toLabel label: UILabel) {
//        self.apply(toLabel: label, withText: nil)
//    }
//    
//    func apply(toLabel label: UILabel, withText text: String?) {
//        if let text = text {
//            label.text = self.transform(text: text)
//        }
//        if let font = self.font {
//            label.font = font
//        }
//        label.textAlignment = self.alignment
//        label.numberOfLines = self.numberOfLines
//        if let color = self.color {
//            label.textColor = color
//        }
//        if let backgroundColor = self.backgroundColor {
//            label.backgroundColor = backgroundColor
//        }
//        if self.sizeToFit {
//            label.sizeToFit()
//        }
//    }
//
//    func apply(toButton button: UIButton, title: String, states: [UIControlState]) {
//        for state in states {
//            let attributedTitle = attributedString(withText: title, forState: state)
//            button.setAttributedTitle(attributedTitle, for: state)
//        }
//    }
//    
//    func apply(toButton button: UIButton, titleForNormalAndHighlightedState title: String, generateMissingHighlightedColorsUsingColorsWithAlphaComponent alphaComponent: CGFloat? = 0.5) {
//        let normalTitle = attributedString(withText: title)
//        button.setAttributedTitle(normalTitle, for: .normal)
//        
//        let highlightedTitle = attributedString(withText: title, forState: .highlighted, generateMissingColorsUsingAlphaOfNormalColors: alphaComponent)
//        button.setAttributedTitle(highlightedTitle, for: .highlighted)
//    }
//    
//    func apply(toButton button: UIButton, titleForDisabledState title: String) {
//        let disabledTitle = self.attributedString(withText: title)
//        button.setAttributedTitle(disabledTitle, for: .disabled)
//    }
//
//}

public class ViewSpecifier {
    public var size = CGSize.zero
    public var position = CGPoint.zero
    public var backgroundColor: UIColor?
    public var highlightedBackgroundColor: UIColor?
    public var disabledBackgroundColor: UIColor?
    
    /** Not used when creating a view \c -viewWithViewSpecifierKey:. How padding
     affect the view to be interpreted by interested party. */
    public var padding = UIEdgeInsets.zero
    
    public func backgroundColor(forState state: UIControlState) -> UIColor? {
        switch state {
        case .normal:
            return backgroundColor
        case .highlighted:
            return highlightedBackgroundColor
        case .disabled:
            return disabledBackgroundColor
        default:
            return nil
        }
    }
}

public class DashedBorderSpecifier {
    var lineWidth: Float = 0
    var color: UIColor?
    var cornerRadius: Float = 0
    var paintedSegmentLength: Float = 0
    var spacingSegmentLength: Float = 0
    var insets: UIEdgeInsets = .zero
}
