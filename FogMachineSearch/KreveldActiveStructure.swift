//
//  KreveldActiveStructure.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/11/15.
//  Copyright © 2015 Ram Subramaniam. All rights reserved.
//

import Foundation

public class KreveldActiveStructure {
    let FLAG_FALSE: Bool   = false;
    let FLAG_TRUE: Bool = true;
    
    var root: StatusEntry!
    
    var reference: ElevationPoint!
    
    init(reference: ElevationPoint) {
        self.reference = reference
    }
    
    public func insert (value: ElevationPoint) {
        
        let key : Double = reference.calcDistance(value)
        let slope: Double = reference.calcSlope(value);
        
        var y: StatusEntry! = nil
        var x: StatusEntry! = root
        //var tempCount: Int = 0
       // print("slope: \(slope)")
        
        while x != nil {
            //tempCount++
            //print("counter: \(tempCount)")
            y = x
            y.maxSlope = max(y.maxSlope, slope)
            if (key < x.key) {
                x = x.left
            } else {
                x = x.right
                 //print("x.value.height: \n\(x.value.height)")
            }
            //print("x: \n\(x)")
        }
        
        let z: StatusEntry = StatusEntry(key: key, value: value, slope: slope, parent: y)
        if (y == nil) {
            root = z;
        } else {
            if (key < y.key) {
                y.left = z
            } else {
                y.right = z
            }
        }
        fixAfterInsertion(z)
        //print("")
    }
    
    func fixAfterInsertion(var xx: StatusEntry!) {
        //var xx : StatusEntry! = x

        while xx != nil &&  xx !== root && xx.parent !== nil && xx.parent.flag == FLAG_FALSE {
//        while xx != nil &&  xx !== root && xx.parent != nil {
//            if (xx.parent.flag == FLAG_FALSE) {
                var parent1: StatusEntry! = parentOf(xx)
                var parent2: StatusEntry! = parentOf(parent1)
                
                if (parentOf(xx) === leftOf(parent2)) {
                    var y:StatusEntry! = rightOf(parentOf(parentOf(xx)))
                    if flagOf(y) == FLAG_FALSE {
                        setFlag(parentOf(xx), c: FLAG_TRUE)
                        setFlag(y, c: FLAG_TRUE)
                        setFlag(parentOf(parentOf(xx)), c: FLAG_FALSE)
                        xx = parentOf(parentOf(xx))
                    } else {
                        if xx === rightOf(parentOf(xx)) {
                            xx = parentOf(xx)
                            rotateLeft(xx)
                        }
                        setFlag(parentOf(xx), c: FLAG_TRUE)
                        setFlag(parentOf(parentOf(xx)), c: FLAG_FALSE)
                        rotateRight(parentOf(parentOf(xx)))
                    }
                } else {
                    var y:StatusEntry! = rightOf(parentOf(parentOf(xx)))
                    if flagOf(y) == FLAG_FALSE {
                        setFlag(parentOf(xx), c: FLAG_TRUE)
                        setFlag(y, c: FLAG_TRUE)
                        setFlag(parentOf(parentOf(xx)), c: FLAG_FALSE)
                        xx = parentOf(parentOf(xx))
                    } else {
                        if xx === leftOf(parentOf(xx)) {
                            xx = parentOf(xx)
                            rotateRight(xx)
                        }
                        setFlag(parentOf(xx), c: FLAG_TRUE)
                        setFlag(parentOf(parentOf(xx)), c: FLAG_FALSE)
                        rotateLeft(parentOf(parentOf(xx)))
                    }
                }
//            }
        }
        if root != nil {
            root!.flag = FLAG_TRUE
        }
    }
    
    public func delete (pt: ElevationPoint) {
        
        var p: StatusEntry! = getEntry(pt)
        if p == nil {
            return
        }
        // If strictly internal, copy successor's element to p and then make p
        // point to successor.
        // Because of (p.right != null) the successor of p is the minimum of p.right
        if p.left != nil && p.right != nil {
            let s:StatusEntry! = getMinimum(p.right) // = successor(p)
            p.key = s.key
            p.value = s.value
            p.slope = s.slope
            p = s
        }
        // update maxSlope
        p.maxSlope = max(maxSlopeOf(p.left), maxSlopeOf(p.right)); // dummy value
        var x: StatusEntry! = p.parent;
        while (x != nil) {
            x.maxSlope = max( x.slope, max(maxSlopeOf(x.left), maxSlopeOf(x.right)) );
            x = x.parent;
        }
        // Start fixup at replacement node, if it exists.
        var replacement: StatusEntry! = (p.left != nil ? p.left : p.right);
        
        if (replacement != nil) {
            // Here p has exactly one child. Otherwise p would point to its successor, which has no left child.
            // Link replacement to parent
            replacement.parent = p.parent;
            if (p.parent == nil) {
                root = replacement
            } else if (p === p.parent.left) {
                p.parent.left  = replacement
            }
            else {
                p.parent.right = replacement
            }
            // Null out links so they are OK to use by fixAfterDeletion.
            p.left = nil
            p.right = nil
            p.parent = nil
            
            // Fix replacement
            if (p.flag == FLAG_TRUE) {
                fixAfterDeletion(replacement)
            }
        } else if (p.parent == nil) { // return if we are the only node.
            root = nil
        } else { //  No children. Use self as phantom replacement and unlink.
            if (p.flag == FLAG_TRUE) {
                fixAfterDeletion(p)
            }
            if (p.parent != nil) {
                if (p === p.parent.left) {
                    p.parent.left = nil
                }
                else if (p === p.parent.right) {
                    p.parent.right = nil
                }
                p.parent = nil
            }
        }
    }
    
    /**
    * Searches the status structure for a point p
    * and returns the corresponding StatusEntry.
    * @param p HeightedPoint to be searched
    * @return StatusEntry
    */
    func getEntry(let p: ElevationPoint) -> StatusEntry! {
        let key: Double = reference.calcDistance(p)
        var t: StatusEntry! = root
        let nilvar: StatusEntry! = nil
        
        while (t != nil) {
            if (key < t.key) {
                t = t.left
            } else if (key > t.key) {
                t = t.right
            } else if (p.equalsPosition(t.value)) {
                return t // found it!
            } else {
                //search to the left and to the right
                if (t.left != nil && p.equalsPosition(t.left.value)) {
                    return t.left
                }
                if (t.right != nil && p.equalsPosition(t.right.value)) {
                    return t.right
                }
                return nilvar // assuming the searched point can only be in one of the children
            }
        }
        return nilvar
    }
    
    func getMinimum(let p: StatusEntry!) -> StatusEntry {
        let nilvar: StatusEntry! = nil
        if (p == nil) {
            return nilvar
        }
        var min: StatusEntry! = p
        while (min.left != nil) {
            min = min.left
        }
        return min
    }
    
    
    func parentOf(let p: StatusEntry!) -> StatusEntry! {
        return (p == nil ? nil: p.parent);
    }
    
    func maxSlopeOf(p: StatusEntry!) -> Double {
        let NEGATIVE_INFINITY: Double = -1.0 / 0.0
        return (p == nil ? NEGATIVE_INFINITY: p.maxSlope);
    }
    
    func flagOf(p: StatusEntry!) -> Bool {

        return (p == nil ? FLAG_TRUE : p.flag);
    }
    func setFlag(let p: StatusEntry!, c:Bool) {
        if p != nil {
            p.flag = c
        }
    }
    func parentOf(let p: StatusEntry!) -> StatusEntry {
        return (p == nil ? nil: p.parent)
    }
    func leftOf(let p: StatusEntry!) -> StatusEntry! {
         return (p == nil) ? nil: p.left
        
    }
    func rightOf(let p: StatusEntry!) -> StatusEntry! {
        return (p == nil) ? nil: p.right
    }
    func rotateLeft(let p: StatusEntry!) {
        if p != nil {
            let r: StatusEntry! = p.right
            
            if r != nil {
                 p.right = r.left
                if r.left != nil {
                    r.left.parent = p
                }
                r.parent = p.parent
            }

            if p.parent == nil {
                    root = r
            } else if p.parent.left === p {
                    p.parent.left = r
            } else {
                    p.parent.right = r
            }
            if r != nil {
                r.left = p
            }
            p.parent = r
    
            if r != nil {
                r.maxSlope = p.maxSlope
            }
            p.maxSlope = max( p.slope, max(maxSlopeOf(p.left), maxSlopeOf(p.right)) )
        }
    }
    
    func rotateRight(let p: StatusEntry!) {
        if p != nil {
            let l: StatusEntry! = p.left

            if l != nil {
                p.left = l.right
                if l.right != nil {
                    l.right.parent = p
                } else {

                }
            } else {
                p.left = nil
            }
            if (p.parent != nil) {
                if l != nil {
                    l.parent = p.parent
                } else {
                    
                }
            } else {
                if l != nil {
                    if l.parent != nil {
                        l.parent = nil
                    }
                }
            }

            if p.parent == nil {
                root = l
            } else if p.parent.right === p {
                p.parent.right = l
            } else {
                p.parent.right = l
            }
            if l != nil {
                l.right = p
            }
            //l.right = p
            p.parent = l
            
            //l.maxSlope = p.maxSlope
            if l != nil {
                l.maxSlope = p.maxSlope
            }
            p.maxSlope = max( p.slope, max(maxSlopeOf(p.left), maxSlopeOf(p.right)) )
        }
    }
    
    func fixAfterDeletion(var xx: StatusEntry!) {
        //var xx : StatusEntry! = x
        
        while (xx !== root && flagOf(xx) == FLAG_TRUE) {
            if (xx === leftOf(parentOf(xx))) {
                var sib: StatusEntry! = rightOf(parentOf(xx))
                
                if flagOf(sib) == FLAG_FALSE {
                    setFlag(sib, c: FLAG_TRUE)
                    setFlag(parentOf(xx), c: FLAG_FALSE)
                    rotateLeft(parentOf(xx))
                    sib = rightOf(parentOf(xx))
                }
                
                if (flagOf(leftOf(sib))  == FLAG_TRUE &&  flagOf(rightOf(sib)) == FLAG_TRUE) {
                    setFlag(sib, c: FLAG_FALSE)
                    xx = parentOf(xx)
                    
                } else {
                    if (flagOf(rightOf(sib)) == FLAG_TRUE) {
                        setFlag(leftOf(sib), c: FLAG_TRUE)
                        setFlag(sib, c: FLAG_FALSE)
                        rotateRight(sib)
                        sib = rightOf(parentOf(xx))
                    }
                    setFlag(sib, c: flagOf(parentOf(xx)))
                    setFlag(parentOf(xx), c: FLAG_TRUE)
                    setFlag(rightOf(sib), c: FLAG_TRUE)
                    rotateLeft(parentOf(xx))
                    xx = root
                }
            } else { // symmetric
                var sib: StatusEntry! = leftOf(parentOf(xx))
                
                if (flagOf(sib) == FLAG_FALSE) {
                    setFlag(sib, c: FLAG_TRUE)
                    setFlag(parentOf(xx), c: FLAG_FALSE)
                    rotateRight(parentOf(xx))
                    sib = leftOf(parentOf(xx))
                }
                
                if (flagOf(rightOf(sib)) == FLAG_TRUE &&
                    flagOf(leftOf(sib)) == FLAG_TRUE) {
                        setFlag(sib, c: FLAG_FALSE)
                        xx = parentOf(xx)
                } else {
                    if (flagOf(leftOf(sib)) == FLAG_TRUE) {
                        setFlag(rightOf(sib), c: FLAG_TRUE)
                        setFlag(sib, c: FLAG_FALSE)
                        rotateLeft(sib)
                        sib = leftOf(parentOf(xx))
                    }
                    setFlag(sib, c: flagOf(parentOf(xx)))
                    setFlag(parentOf(xx), c: FLAG_TRUE)
                    setFlag(leftOf(sib), c: FLAG_TRUE)
                    rotateRight(parentOf(xx))
                    xx = root
                }
            }
        }
        setFlag(xx, c: FLAG_TRUE)
    }
    
    func isVisible(let pt: ElevationPoint) -> Bool {
        let key: Double = reference.calcDistance(pt)
        var p: StatusEntry! = nil
        var x: StatusEntry! = root
        var maxSlope: Double = -1.0 / 0.0 //NEGATIVE_INFINITY
        let retValue: Bool
        
        while (x != nil && !pt.equalsPosition(x.value)) {
                p = x
                if (key < x.key) {
                    x = x.left
                } else {
                    x = x.right
                    let tmpSlope :Double = max(maxSlopeOf(p.left), p.slope)
                    maxSlope = max(maxSlope,tmpSlope)
                }
        }
       
        
        if (x == nil) {
            return false
        }
        maxSlope = max(maxSlope, maxSlopeOf(x.left))
        if maxSlope < x.slope {
            retValue = true
        } else {
            retValue = false
        }
        return retValue
    }
    

}