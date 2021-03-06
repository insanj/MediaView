//
//  UIImage+GIF.swift
//  MediaView
//
//  Created by Andrew Boryk on 8/28/17.
//

import Foundation
import CoreGraphics

extension UIImage {
    
    private static func delayCentisecondsForImageAtIndex(source: CGImageSource, i: size_t) -> Int {
        var delayCentiseconds = 1
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) else {
            return delayCentiseconds
        }
        
        let gifProperties = unsafeBitCast(CFDictionaryGetValue(properties, unsafeBitCast(kCGImagePropertyGIFDictionary, to: UnsafeRawPointer.self)), to: CFDictionary.self)
        let number = unsafeBitCast(CFDictionaryGetValue(gifProperties, unsafeBitCast(kCGImagePropertyGIFUnclampedDelayTime, to: UnsafeRawPointer.self)), to: CFString.self)
        
        guard var numberValue = Double("\(number)") else {
            return delayCentiseconds
        }
        
        if numberValue == 0 {
            numberValue = CFStringGetDoubleValue(unsafeBitCast(CFDictionaryGetValue(gifProperties, unsafeBitCast(kCGImagePropertyGIFDelayTime, to: UnsafeRawPointer.self)), to: CFString.self))
        }
        
        if numberValue > 0 {
            delayCentiseconds = Int(lrint(numberValue * 100))
        }
        
        return delayCentiseconds
    }
    
    private static func createImagesAndDelays(source: CGImageSource, count: size_t) -> (imagesOut: [CGImage], delayCentisecondsOut: [Int]) {
        var imagesOut = [CGImage]()
        var delayCentisecondsOut = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                imagesOut.append(image)
                delayCentisecondsOut.append(delayCentisecondsForImageAtIndex(source: source, i: i))
            }
        }
        
        return (imagesOut: imagesOut, delayCentisecondsOut: delayCentisecondsOut)
    }
    
    private static func sum(count: size_t, values: [Int]) -> Int {
        var theSum = 0
        
        for i in 0..<count {
            theSum += values[i]
        }
        
        return theSum
    }
    
    private static func pairGCD(a: Int, b: Int) -> Int {
        var valueA = a
        var valueB = b
        guard valueA <= valueB else {
            return pairGCD(a: valueB, b: valueA)
        }
        
        while true {
            let r = valueA % valueB
            if r == 0 {
                return valueB
            }
            
            valueA = valueB
            valueB = r
        }
    }
    
    private static func vectorGCD(count: size_t, values: [Int]) -> Int {
        var gcd = values[0]
        
        if values.count > 1 {
            for i in 1..<count {
                gcd = pairGCD(a: values[i], b: gcd)
            }
        }
        
        return gcd
    }
    
    private static func frameArray(count: size_t, images: [CGImage], delayCentiseconds: [Int]) -> [UIImage] {
        let gcd = vectorGCD(count: count, values: delayCentiseconds)
        var frames = [UIImage]()
        for i in 0..<count {
            let frame = UIImage(cgImage: images[i])
            var j = (delayCentiseconds[i] / gcd)
            while j > 0 {
                frames.append(frame)
                j -= 1
            }
        }
        
        return frames
    }
    
    private static func animatedImageWithAnimatedGIFImageSource(source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        let result = createImagesAndDelays(source: source, count: count)
        let images = result.imagesOut
        let delayCentiseconds = result.delayCentisecondsOut
        let totalDurationCentiseconds = sum(count: count, values: delayCentiseconds)
        let frames = frameArray(count: count, images: images, delayCentiseconds: delayCentiseconds)
        let animation = UIImage.animatedImage(with: frames, duration: TimeInterval(totalDurationCentiseconds) / 100)
        
        return animation
    }
    
    static func animatedImageWithAnimatedGIFData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData((data as NSData) as CFData, nil) else {
            return nil
        }
        
        return animatedImageWithAnimatedGIFImageSource(source: source)
    }
    
    static func animatedImageWithAnimatedGIFUrl(_ url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL((url as NSURL) as CFURL, nil) else {
            return nil
        }
        
        return animatedImageWithAnimatedGIFImageSource(source: source)
    }
}
