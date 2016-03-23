//
//  KreveldActiveBTree.swift
//  Viewshed
//
//  Created by Ram Subramaniam on 11/15/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

import Foundation
// based on the paper : http://www.cs.uu.nl/research/techreps/repo/CS-1996/1996-22.pdf
public struct KreveldActiveBTree {
    static let FLAG_FALSE: Bool = false;
    static let FLAG_TRUE: Bool = true;
    private var root: StatusEntry?
    private var reference: ElevationPoint?
    
    init(reference: ElevationPoint) {
        self.reference = reference
    }
    
    public mutating func insert (value: ElevationPoint) {
        let key : Double = self.reference!.calcDistance(value)
        let slope: Double = self.reference!.calcSlope(value);
        
        var y: StatusEntry? = nil
        var x: StatusEntry? = self.root
        while x !== nil {
            y = x
            y!.maxSlope = max(y!.maxSlope, slope)
            if (key < x!.key) {
                x = x!.left
            } else {
                x = x!.right
            }
        }
        
        let z: StatusEntry = StatusEntry(key: key, value: value, slope: slope, parent: y)
        if (y == nil) {
            self.root = z;
        } else {
            if (key < y!.key) {
                y!.left = z
            } else {
                y!.right = z
            }
        }
        self.fixAfterInsertion(z)
    }
    
    private mutating func fixAfterInsertion(xx: StatusEntry?) {
        var xx = xx
        while xx != nil &&  xx !== self.root && xx!.parent !== nil && xx!.parent!.flag == KreveldActiveBTree.FLAG_FALSE {
            let greatGreatLeft :StatusEntry? = self.leftOf(self.parentOf(self.parentOf(xx)))
            
            if (self.parentOf(xx) === greatGreatLeft) {
                let y:StatusEntry? = self.rightOf(self.parentOf(self.parentOf(xx)))
                if self.flagOf(y) == KreveldActiveBTree.FLAG_FALSE {
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(y, c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBTree.FLAG_FALSE)
                    xx = self.parentOf(self.parentOf(xx))
                } else {
                    if xx === self.rightOf(self.parentOf(xx)) {
                        xx = self.parentOf(xx)
                        self.rotateLeft(xx)
                    }
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBTree.FLAG_FALSE)
                    self.rotateRight(self.parentOf(self.parentOf(xx)))
                }
            } else {
                let y:StatusEntry? = self.leftOf(self.parentOf(self.parentOf(xx)))
                if self.flagOf(y) == KreveldActiveBTree.FLAG_FALSE {
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(y, c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBTree.FLAG_FALSE)
                    xx = self.parentOf(self.parentOf(xx))
                } else {
                    if xx === self.leftOf(self.parentOf(xx)) {
                        xx = self.parentOf(xx)
                        self.rotateRight(xx)
                    }
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBTree.FLAG_FALSE)
                    self.rotateLeft(self.parentOf(self.parentOf(xx)))
                }
            }
        }
        if self.root != nil {
            self.root!.flag = KreveldActiveBTree.FLAG_TRUE
        }
    }
    
    public mutating func delete (pt: ElevationPoint) {
        
        // verify if all the 'nil' check necessary
        var p: StatusEntry? = self.getEntry(pt)
        if p == nil {
            return
        }
        // If strictly internal, copy successor's element to p and then make p
        // point to successor.
        // Because of (p.right != null) the successor of p is the minimum of p.right
        if p!.left != nil && p!.right != nil {
            let s:StatusEntry! = self.getMinimum(p!.right) // = successor(p)
            p!.key = s.key
            p!.value = s.value
            p!.slope = s.slope
            p = s
        }
        // update maxSlope
        p!.maxSlope = max(self.maxSlopeOf(p!.left), self.maxSlopeOf(p!.right)); // dummy value
        var x: StatusEntry? = p!.parent;
        while (x != nil) {
            x!.maxSlope = max( x!.slope, max(self.maxSlopeOf(x!.left), self.maxSlopeOf(x!.right)) );
            x = x!.parent;
        }
        // Start fixup at replacement node, if it exists.
        let replacement: StatusEntry? = (p!.left != nil ? p!.left : p!.right);
        
        if (replacement != nil) {
            // Here p has exactly one child. Otherwise p would point to its successor, which has no left child.
            // Link replacement to parent
            replacement!.parent = p!.parent;
            if (p!.parent == nil) {
                self.root = replacement
            } else if (p === p!.parent!.left) {
                p!.parent!.left  = replacement
            }
            else {
                p!.parent!.right = replacement
            }
            // nil out links so they are OK to use by fixAfterDeletion.
            p!.left = nil
            p!.right = nil
            p!.parent = nil
            
            // Fix replacement
            if (p!.flag == KreveldActiveBTree.FLAG_TRUE) {
                self.fixAfterDeletion(replacement)
            }
        } else if (p!.parent == nil) { // return if we are the only node.
            self.root = nil
        } else { //  No children. Use self as phantom replacement and unlink.
            if (p!.flag == KreveldActiveBTree.FLAG_TRUE) {
                self.fixAfterDeletion(p)
            }
            if (p!.parent != nil) {
                if (p === p!.parent!.left) {
                    p!.parent!.left = nil
                }
                else if (p === p!.parent!.right) {
                    p!.parent!.right = nil
                }
                p!.parent = nil
            }
        }
    }
    
    // Searches the status structure for a point p and returns the corresponding StatusEntry.
    // param p HeightedPoint to be searched
    // returns StatusEntry
    private func getEntry(let p: ElevationPoint) -> StatusEntry? {
        let key: Double = self.reference!.calcDistance(p)
        var t: StatusEntry? = self.root
        
        while (t != nil) {
            if (key < t!.key) {
                t = t!.left
            } else if (key > t!.key) {
                t = t!.right
            } else if (p.equalsPosition(t!.value)) {
                return t // found it!
            } else {
                //search to the left and to the right
                if (t!.left != nil && p.equalsPosition(t!.left!.value)) {
                    return t!.left
                }
                if (t!.right != nil && p.equalsPosition(t!.right!.value)) {
                    return t!.right
                }
                return nil // assuming the searched point can only be in one of the children
            }
        }
        return nil
    }
    
    private func getMinimum (let p: StatusEntry?) -> StatusEntry? {
        if (p == nil) {
            return nil
        }
        var min: StatusEntry? = p
        while (min!.left != nil) {
            min = min!.left
        }
        return min!
    }
    
    private func maxSlopeOf(p: StatusEntry?) -> Double {
        let NEGATIVE_INFINITY: Double = -1.0 / 0.0
        return (p == nil ? NEGATIVE_INFINITY: p!.maxSlope);
    }
    
    private func flagOf(p: StatusEntry?) -> Bool {
        
        return (p == nil ? KreveldActiveBTree.FLAG_TRUE : p!.flag);
    }
    
    private func setFlag(let p: StatusEntry?, c:Bool) {
        if p != nil {
            p!.flag = c
        }
    }
    
    private func parentOf(let p: StatusEntry?) -> StatusEntry? {
        if p == nil {
            return nil
        } else {
            var tmp:StatusEntry? = nil
            if p!.parent !== nil {
                tmp = p!.parent
            } else {
                return nil
            }
            return tmp
        }
    }
    
    private func leftOf(let p: StatusEntry?) -> StatusEntry? {
        return (p == nil) ? nil: p!.left
        
    }
    
    private func rightOf(let p: StatusEntry?) -> StatusEntry? {
        return (p == nil) ? nil: p!.right
    }
    
    mutating  private func rotateLeft(let p: StatusEntry?) {
        if p != nil {
            let r: StatusEntry? = p!.right
            // verify if all the 'nil' check necessary
            if r != nil {
                p!.right = r!.left
                if r!.left != nil {
                    r!.left!.parent = p
                }
                r!.parent = p!.parent
            }
            // verify if all the 'nil' check necessary
            if p!.parent == nil {
                self.root = r
            } else if p!.parent!.left === p {
                p!.parent!.left = r
            } else {
                p!.parent!.right = r
            }
            if r != nil {
                r!.left = p
            }
            p!.parent = r
            
            if r != nil {
                r!.maxSlope = p!.maxSlope
            }
            p!.maxSlope = max( p!.slope, max(self.maxSlopeOf(p!.left), self.maxSlopeOf(p!.right)) )
        }
    }
    
    private mutating func rotateRight(let p: StatusEntry?) {
        if p != nil {
            let l: StatusEntry? = p!.left
            
            if l != nil {
                p!.left = l!.right
                if l!.right != nil {
                    l!.right!.parent = p
                } else {
                    
                }
            } else {
                p!.left = nil
            }
            if (p!.parent != nil) {
                if l != nil {
                    l!.parent = p!.parent
                } else {
                    
                }
            } else {
                if l != nil {
                    if l!.parent != nil {
                        l!.parent = nil
                    }
                }
            }
            if p!.parent == nil {
                self.root = l
            } else if p!.parent!.right === p {
                p!.parent!.right = l
            } else {
                p!.parent!.left = l
            }
            if l != nil {
                l!.right = p
            }
            l!.right = p
            p!.parent = l
            
            if l != nil {
                l!.maxSlope = p!.maxSlope
            }
            p!.maxSlope = max( p!.slope, max(self.maxSlopeOf(p!.left), self.maxSlopeOf(p!.right)) )
        }
    }
    
    private mutating func fixAfterDeletion(xx: StatusEntry?) {
        var xx = xx
        while (xx !== self.root && self.flagOf(xx) == KreveldActiveBTree.FLAG_TRUE) {
            if (xx === self.leftOf(self.parentOf(xx))) {
                var sib: StatusEntry? = self.rightOf(self.parentOf(xx))
                
                if self.flagOf(sib) == KreveldActiveBTree.FLAG_FALSE {
                    self.setFlag(sib, c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_FALSE)
                    self.rotateLeft(self.parentOf(xx))
                    sib = self.rightOf(self.parentOf(xx))
                }
                
                if (self.flagOf(self.leftOf(sib))  == KreveldActiveBTree.FLAG_TRUE &&  self.flagOf(self.rightOf(sib)) == KreveldActiveBTree.FLAG_TRUE) {
                    self.setFlag(sib, c: KreveldActiveBTree.FLAG_FALSE)
                    xx = self.parentOf(xx)
                    
                } else {
                    if (self.flagOf(self.rightOf(sib)) == KreveldActiveBTree.FLAG_TRUE) {
                        self.setFlag(self.leftOf(sib), c: KreveldActiveBTree.FLAG_TRUE)
                        self.setFlag(sib, c: KreveldActiveBTree.FLAG_FALSE)
                        self.rotateRight(sib)
                        sib = self.rightOf(self.parentOf(xx))
                    }
                    self.setFlag(sib, c: self.flagOf(self.parentOf(xx)))
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.rightOf(sib), c: KreveldActiveBTree.FLAG_TRUE)
                    self.rotateLeft(self.parentOf(xx))
                    xx = self.root
                }
            } else { // symmetric
                var sib: StatusEntry? = self.leftOf(self.parentOf(xx))
                
                if (self.flagOf(sib) == KreveldActiveBTree.FLAG_FALSE) {
                    self.setFlag(sib, c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_FALSE)
                    self.rotateRight(self.parentOf(xx))
                    sib = self.leftOf(self.parentOf(xx))
                }
                
                if (self.flagOf(self.rightOf(sib)) == KreveldActiveBTree.FLAG_TRUE &&
                    self.flagOf(self.leftOf(sib)) == KreveldActiveBTree.FLAG_TRUE) {
                        self.setFlag(sib, c: KreveldActiveBTree.FLAG_FALSE)
                        xx = self.parentOf(xx)
                } else {
                    if (self.flagOf(self.leftOf(sib)) == KreveldActiveBTree.FLAG_TRUE) {
                        self.setFlag(self.rightOf(sib), c: KreveldActiveBTree.FLAG_TRUE)
                        self.setFlag(sib, c: KreveldActiveBTree.FLAG_FALSE)
                        self.rotateLeft(sib)
                        sib = self.leftOf(self.parentOf(xx))
                    }
                    self.setFlag(sib, c: self.flagOf(self.parentOf(xx)))
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBTree.FLAG_TRUE)
                    self.setFlag(self.leftOf(sib), c: KreveldActiveBTree.FLAG_TRUE)
                    self.rotateRight(self.parentOf(xx))
                    xx = self.root
                }
            }
        }
        self.setFlag(xx, c: KreveldActiveBTree.FLAG_TRUE)
    }
    
    // check the visibility of this cell to the observer
    public func isVisible(let pt: ElevationPoint) -> Bool {
        let key: Double = self.reference!.calcDistance(pt)
        var p: StatusEntry? = nil
        var x: StatusEntry? = self.root
        var maxSlope: Double = -1.0 / 0.0 //NEGATIVE_INFINITY - TODO: find out if any constant in Swift
        var retValue: Bool = false
        
        while (x !== nil && !(pt.equalsPosition(x!.value))) {
            p = x
            if (key < x!.key) {
                x = x!.left
            } else {
                x = x!.right
                let tmpSlope :Double = max(self.maxSlopeOf(p!.left), p!.slope)
                maxSlope = max(maxSlope, tmpSlope)
            }
        }
        
        if (x === nil) {
            return retValue
        }
        maxSlope = max(maxSlope, self.maxSlopeOf(x!.left))
        // when the elevations are "0.0" the slope will be "0.0" at this point....
        // need to return true when the slopes are less than or equal..
        //if maxSlope < x.slope {
        if maxSlope <= x!.slope {
            retValue = true
        } else {
            retValue = false
        }
        return retValue
    }
}
