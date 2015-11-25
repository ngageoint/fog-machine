//
//  StreamScanner.swift
//  Viewshed
//
//  Created by Anthony Shoumikhin on 6/25/15.
//  Copyright © 2015 shoumikh.in. All rights reserved.
//

import Foundation

public protocol Scannable {}

extension String: Scannable {}
extension Int: Scannable {}
extension Int32: Scannable {}
extension Int64: Scannable {}
extension UInt64: Scannable {}
extension Float: Scannable {}
extension Double: Scannable {}

public class StreamScanner : GeneratorType, SequenceType
{
    public static let standardInput = StreamScanner(source: NSFileHandle.fileHandleWithStandardInput())
    private let source: NSFileHandle
    private let delimiters: NSCharacterSet
    private var buffer: NSScanner?
    
    public init(source: NSFileHandle, delimiters: NSCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet())
    {
        self.source = source
        self.delimiters = delimiters
    }
    
    public func next() -> String?
    {
        return read()
    }
    
    public func generate() -> Self
    {
        return self
    }
    
    public func ready() -> Bool
    {
        if buffer == nil || buffer!.atEnd
        {   //init or append the buffer
            let availableData = source.availableData
            
            if
                availableData.length > 0,
                let nextInput = NSString(data: availableData, encoding: NSUTF8StringEncoding)
            {
                buffer = NSScanner(string: nextInput as String)
            }
        }
        
        return buffer != nil && !buffer!.atEnd
    }
    
    public func read<T: Scannable>() -> T?
    {
        if ready()
        {
            var token: NSString?
            
            //grab the next valid characters into token
            if buffer!.scanUpToCharactersFromSet(delimiters, intoString: &token) && token != nil
            {
                //skip delimiters for the next invocation
                buffer!.scanCharactersFromSet(delimiters, intoString: nil)
                
                //convert the token into an instance of type T and return it
                return convert(token as! String)
            }
        }
        
        return nil
    }
    
    private func convert<T: Scannable>(token: String) -> T?
    {
        var ret: T? = nil
        
        if ret is String? { return token as? T }
        
        let scanner = NSScanner(string: token)
        
        switch ret
        {
        case is Int? :
            var value: Int = 0
            if scanner.scanInteger(&value)
            {
                ret = value as? T
            }
        case is Int32? :
            var value: Int32 = 0
            if scanner.scanInt(&value)
            {
                ret = value as? T
            }
        case is Int64? :
            var value: Int64 = 0
            if scanner.scanLongLong(&value)
            {
                ret = value as? T
            }
        case is UInt64? :
            var value: UInt64 = 0
            if scanner.scanUnsignedLongLong(&value)
            {
                ret = value as? T
            }
        case is Float? :
            var value: Float = 0
            if scanner.scanFloat(&value)
            {
                ret = value as? T
            }
        case is Double? :
            var value: Double = 0
            if scanner.scanDouble(&value)
            {
                ret = value as? T
            }
        default :
            ret = nil
        }
        
        return ret
    }
}
