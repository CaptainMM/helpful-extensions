//
//  HelpfulExtensions.swift
//  Created by Mark McCorkle
//  Copyright ® 2017. All rights reserved.
//

import UIKit
import CoreData


//MARK: - String
extension String {
    // Various String helpers and conversions
    func length() -> Int {
        return self.characters.count
    }

    func trim() -> String {
        return self.trimmingCharacters(in: NSMutableCharacterSet.whitespaceAndNewline() as CharacterSet)
    }

    func substring(_ location:Int, length:Int) -> String! {
        return (self as NSString).substring(with: NSMakeRange(location, length))
    }

    subscript(index: Int) -> String! {
        get {
            return self.substring(index, length: 1)
        }
    }

    func location(_ other: String) -> Int {
        return (self as NSString).range(of: other).location
    }

    func contains(_ other: String) -> Bool {
        return (self as NSString).contains(other)
    }

    func isNumeric() -> Bool {
        return (self as NSString).rangeOfCharacter(from: CharacterSet.decimalDigits.inverted).location == NSNotFound
    }

    var numbersOnly:String {
        return self.components(separatedBy: CharacterSet(charactersIn: "1234567890").inverted).joined(separator: "")
    }

    var numbersWithDecimalOnly:String {
        return self.components(separatedBy: CharacterSet(charactersIn: "1234567890.").inverted).joined(separator: "")
    }

    var decimalNumberValue:NSDecimalNumber {
        if NSString(string:self).doubleValue > 0 {
            return NSDecimalNumber(value: NSString(string:self).doubleValue as Double).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: NSDecimalNumber.RoundingMode.bankers, scale: 2, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
        } else {
            return NSDecimalNumber.zero
        }
    }

    var currencyValue:String {
        var number = self.numbersWithDecimalOnly
        if number.isEmpty {
            number = "0"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.locale = Locale.current
        let newValue = formatter.string(from: NSDecimalNumber(string: number)) ?? ""

        return newValue
    }

    var numbersExempt:String {
        return self.components(separatedBy: CharacterSet(charactersIn: "1234567890")).joined(separator: "")
    }

    var charactersOnly:String {
        return self.components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted).joined(separator: "")
    }

    var charactersExempt:String {
        return self.components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")).joined(separator: "")
    }

    func keep(_ keepIt: String) -> String {
        return self.components(separatedBy: CharacterSet(charactersIn: keepIt).inverted).joined(separator: "")
    }

    func exclude(_ excludeIt: String) -> String {
        return self.components(separatedBy: CharacterSet(charactersIn: excludeIt)).joined(separator: "")
    }
    var removeSpecialCharsFromString:String {
        let okayChars : Set<Character> = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
        return String(self.characters.filter {okayChars.contains($0) })
    }


    var unescaped: String {
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        var current = self
        for entity in entities {
            let descriptionCharacters = entity.debugDescription.characters.dropFirst().dropLast()
            let description = String(descriptionCharacters)
            current = current.replacingOccurrences(of: description, with: entity)
        }
        return current
    }
}

// MARK: - Core Data
extension NSManagedObject {
    // Used for prior versions of swift which did not authomatically create these relationships
    func addObject(_ value: NSManagedObject, forKey: String) {
        let items = self.mutableSetValue(forKey: forKey);
        items.add(value)
    }
}

//MARK: - UIViewController
extension UIViewController {
    // Delay a block of code for a given amount of time
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    // Display a quick simple alert even if another is already being displayed
    func displaySimpleAlert(_ title:String,message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        self.presentViewControllerWithoutConflict(alert, animated: true, completion: { (result) in
            //
        })
    }
    // Present a view regardless of whats beinh displayed currently
    func presentViewControllerWithoutConflict(_ alert:UIViewController, animated:Bool, completion: @escaping (_ result: Bool)->()) {
        DispatchQueue.main.async { () -> Void in
            if let currentVisibleController = UIApplication.topViewController() {
                print("Current visibleViewControler = \(currentVisibleController.classForCoder)")
                if currentVisibleController.isKind(of: UIAlertController.self) {
                    print("Current viewcontroller is type UIAlertController")
                    let presentingViewController = currentVisibleController.presentingViewController
                    presentingViewController?.dismiss(animated: true, completion: { () -> Void in
                        presentingViewController?.present(alert, animated: animated, completion: { () -> Void in
                            completion(true)
                        })
                    })
                } else if currentVisibleController.tabBarController != nil {
                    currentVisibleController.tabBarController?.present(alert, animated: animated, completion: { () -> Void in
                        completion(true)
                    })
                } else {
                    currentVisibleController.present(alert, animated: animated, completion: { () -> Void in
                        completion(true)
                    })
                }
            } else {
                print("PROBLEM!!!")
                completion(true)
            }
        }
    }
}

// MARK: - UITableView
extension UITableView {
    // Get the indexPath for a given view
    func indexPathForView (_ view : UIView) -> IndexPath? {
        let location = view.convert(CGPoint.zero, to:self)
        return indexPathForRow(at: location)
    }
}


// MARK: - NSMutableURLRequest
extension NSMutableURLRequest {
    // Set a nicely formatted body to an existed request
    func setBodyContent(contentMap: Dictionary<String, String>) {
        var firstOneAdded = false
        let contentKeys:Array<String> = Array(contentMap.keys)
        var contentBodyAsString = ""
        for contentKey in contentKeys {
            if(!firstOneAdded) {
                contentBodyAsString += contentKey + "=" + contentMap[contentKey]!
                firstOneAdded = true
            }
            else {
                contentBodyAsString += "&" + contentKey + "=" + contentMap[contentKey]!
            }
        }
        contentBodyAsString = contentBodyAsString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let postData = contentBodyAsString.data(using: String.Encoding.ascii)!
        let postLength = "\(postData.count)"
        self.setValue(postLength, forHTTPHeaderField: "Content-Length")
        self.httpBody = postData
    }
}


//MARK: - Date
//  Compare dates with < or ==
public func <(a: Date, b: Date) -> Bool {
    return a.compare(b) == ComparisonResult.orderedAscending
}
public func ==(a: Date, b: Date) -> Bool {
    return a.compare(b) == ComparisonResult.orderedSame
}

//MARK: - NSDate
extension NSDate {
    // Format existing date to expected postgres date format
    func convertToPostgresDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dateString = formatter.string(from: self as Date)
        return dateString
    }
}

extension NSDecimalNumber {
    // Return value in US currency format
    func currencyStringValue() -> String {
        if self > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = NumberFormatter.Style.currency
            formatter.locale = Locale.current
            let newValue = formatter.string(from: self) ?? ""
            return newValue
        }
        return "$0.00"
    }
}

//MARK: - UIImage
extension UIImage {
    // Resizing images
    func resizeWith(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }

    func resizeWith(width: CGFloat, height: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }

    func resize(size:CGSize, completionHandler:@escaping (UIImage, Foundation.Data)->()) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
            let newSize:CGSize = size
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let imageData = UIImageJPEGRepresentation(newImage!, 0.5)
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(newImage!, imageData!)
            })
        })
    }
    // A quick grayscale conversion
    func convertToGrayScale() -> UIImage {
        let imageRect:CGRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = self.size.width
        let height = self.size.height

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        context?.draw(self.cgImage!, in: imageRect)
        let imageRef = context?.makeImage()
        let newImage = UIImage(cgImage: imageRef!)

        return newImage
    }

    // Convert the image to 1bit black and white
    func blackAndWhiteImage() -> UIImage {
        let context = CIContext(options: nil)
        let ciImage = CoreImage.CIImage(image: self)!

        // Set image color to b/w
        let bwFilter = CIFilter(name: "CIColorControls")!
        bwFilter.setValuesForKeys([kCIInputImageKey:ciImage, kCIInputBrightnessKey:NSNumber(value: 0.0 as Float), kCIInputContrastKey:NSNumber(value: 1.1 as Float), kCIInputSaturationKey:NSNumber(value: 0.0 as Float)])
        let bwFilterOutput = (bwFilter.outputImage)!

        // Adjust exposure
        let exposureFilter = CIFilter(name: "CIExposureAdjust")!
        exposureFilter.setValuesForKeys([kCIInputImageKey:bwFilterOutput, kCIInputEVKey:NSNumber(value: 0.7 as Float)])
        let exposureFilterOutput = (exposureFilter.outputImage)!

        // Create UIImage from context
        let bwCGIImage = context.createCGImage(exposureFilterOutput, from: ciImage.extent)
        let resultImage = UIImage(cgImage: bwCGIImage!, scale: 1.0, orientation: self.imageOrientation)

        return resultImage
    }
}

//MARK: - UIButton
extension UIButton {
    // Set the background color of a UIButton easily use a calculated background image
    fileprivate func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
    func setBackgroundColor(_ color: UIColor, forUIControlState state: UIControlState) {
        self.setBackgroundImage(imageWithColor(color), for: state)
    }
    //
}

//MARK: - UIDevice
public extension UIDevice {
    // Get readable device names
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                    return "iPad 5"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
        case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
        case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}

//MARK: - Dictionary
extension UIApplication {
    // Check if location serveices are enabled
    func locationServicesEnabled() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                print("No access")
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
                return true
            }
        } else {
            print("Location services are not enabled")
            return false
        }
    }

    // Returns the actual top view controller useful for determining if alerts and such are displayed
    class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

//MARK: - NSDecimalNumber
extension NSDecimalNumber: Comparable {}

public func ==(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedSame
}

public func <(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedAscending
}

public func >(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedDescending
}

public func <=(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedAscending || lhs.compare(rhs) == .orderedSame
}

public func >=(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
    return lhs.compare(rhs) == .orderedDescending || lhs.compare(rhs) == .orderedSame
}

// MARK: - Arithmetic Operators

public prefix func -(value: NSDecimalNumber) -> NSDecimalNumber {
    return value.multiplying(by: NSDecimalNumber(mantissa: 1, exponent: 0, isNegative: true))
}

public func +(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.adding(rhs)
}

public func -(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.subtracting(rhs)
}

public func *(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.multiplying(by: rhs)
}

public func /(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.dividing(by: rhs)
}

public func ^(lhs: NSDecimalNumber, rhs: Int) -> NSDecimalNumber {
    return lhs.raising(toPower: rhs)
}
