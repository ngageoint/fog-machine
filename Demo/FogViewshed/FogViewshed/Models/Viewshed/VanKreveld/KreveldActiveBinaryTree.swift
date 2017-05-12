import Foundation

// based on the paper: http://www.cs.uu.nl/research/techreps/repo/CS-1996/1996-22.pdf
public struct KreveldActiveBinaryTree {
    
    let FLAG_FALSE: Bool = false
    let FLAG_TRUE: Bool = true
    fileprivate var root: VanKreveldStatusEntry?
    fileprivate var reference: VanKreveldCell
    
    init(reference: VanKreveldCell) {
        self.reference = reference
    }
    
    public mutating func insert (_ value: VanKreveldCell) {
        // ecludian distance in grid units
        let key: Double = sqrt(pow(Double(reference.x) - Double(value.x), 2) + pow(Double(reference.y) - Double(value.y), 2))
        
        let oppositeInMeters: Double = value.h - reference.h

        // find the slope of the line from the current cell to the observer
        let slopeMonotonicMeasure: Double = oppositeInMeters/key
        
        var y: VanKreveldStatusEntry? = nil
        var x: VanKreveldStatusEntry? = root
        while x !== nil {
            y = x
            y!.maxSlope = max(y!.maxSlope, slopeMonotonicMeasure)
            if (key < x!.key) {
                x = x!.left
            } else {
                x = x!.right
            }
        }
        
        let z: VanKreveldStatusEntry = VanKreveldStatusEntry(key: key, value: value, slope: slopeMonotonicMeasure, parent: y)
        if (y == nil) {
            root = z
        } else {
            if (key < y!.key) {
                y!.left = z
            } else {
                y!.right = z
            }
        }
        fixAfterInsertion(z)
    }
    
    fileprivate mutating func fixAfterInsertion(_ xx: VanKreveldStatusEntry?) {
        var xx = xx
        while xx != nil &&  xx !== root && xx!.parent !== nil && xx!.parent!.flag == FLAG_FALSE {
            let greatGreatLeft: VanKreveldStatusEntry? = leftOf(parentOf(parentOf(xx)))
            
            if (parentOf(xx) === greatGreatLeft) {
                let y:VanKreveldStatusEntry? = rightOf(parentOf(parentOf(xx)))
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
                let y:VanKreveldStatusEntry? = leftOf(parentOf(parentOf(xx)))
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
        }
        if root != nil {
            root!.flag = FLAG_TRUE
        }
    }
    
    public mutating func delete (_ pt: VanKreveldCell) {
        
        // verify if all the 'nil' check necessary
        var p: VanKreveldStatusEntry? = getEntry(pt)
        if p == nil {
            return
        }
        // If strictly internal, copy successor's element to p and then make p
        // point to successor.
        // Because of (p.right != null) the successor of p is the minimum of p.right
        if p!.left != nil && p!.right != nil {
            let s:VanKreveldStatusEntry! = getMinimum(p!.right) // = successor(p)
            p!.key = s.key
            p!.value = s.value
            p!.slope = s.slope
            p = s
        }
        // update maxSlope
        p!.maxSlope = max(maxSlopeOf(p!.left), maxSlopeOf(p!.right)) // dummy value
        var x: VanKreveldStatusEntry? = p!.parent
        while (x != nil) {
            x!.maxSlope = max( x!.slope, max(maxSlopeOf(x!.left), maxSlopeOf(x!.right)) )
            x = x!.parent
        }
        // Start fixup at replacement node, if it exists.
        let replacement: VanKreveldStatusEntry? = (p!.left != nil ? p!.left : p!.right)
        
        if (replacement != nil) {
            // Here p has exactly one child. Otherwise p would point to its successor, which has no left child.
            // Link replacement to parent
            replacement!.parent = p!.parent
            if (p!.parent == nil) {
                root = replacement
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
            if (p!.flag == FLAG_TRUE) {
                fixAfterDeletion(replacement)
            }
        } else if (p!.parent == nil) { // return if we are the only node.
            root = nil
        } else { //  No children. Use self as phantom replacement and unlink.
            if (p!.flag == FLAG_TRUE) {
                fixAfterDeletion(p)
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
    
//     Searches the status structure for a point p and returns the corresponding StatusEntry.
//     param p HeightedPoint to be searched
//     returns StatusEntry
    fileprivate func getEntry(_ p: VanKreveldCell) -> VanKreveldStatusEntry? {
        let key: Double = sqrt(pow(Double(reference.x) - Double(p.x), 2) + pow(Double(reference.y) - Double(p.y), 2))
        var t: VanKreveldStatusEntry? = root
        
        while (t != nil) {
            if (key < t!.key) {
                t = t!.left
            } else if (key > t!.key) {
                t = t!.right
            } else if (p.x == t!.value.x && p.y == t!.value.y) {
                return t // found it!
            } else {
                //search to the left and to the right
                if (t!.left != nil && p.x == t!.left!.value.x && p.y == t!.left!.value.y) {
                    return t!.left
                }
                if (t!.right != nil && p.x == t!.right!.value.x && p.y == t!.right!.value.y) {
                    return t!.right
                }
                return nil // assuming the searched point can only be in one of the children
            }
        }
        return nil
    }
    
    fileprivate func getMinimum (_ p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
        if (p == nil) {
            return nil
        }
        var min: VanKreveldStatusEntry? = p
        while (min!.left != nil) {
            min = min!.left
        }
        return min!
    }
    
    fileprivate func maxSlopeOf(_ p: VanKreveldStatusEntry?) -> Double {
        return (p == nil ? -Double.infinity: p!.maxSlope)
    }
    
    fileprivate func flagOf(_ p: VanKreveldStatusEntry?) -> Bool {
        
        return (p == nil ? FLAG_TRUE : p!.flag)
    }
    
    fileprivate func setFlag(_ p: VanKreveldStatusEntry?, c:Bool) {
        if p != nil {
            p!.flag = c
        }
    }
    
    fileprivate func parentOf(_ p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
        if p == nil {
            return nil
        } else {
            var tmp:VanKreveldStatusEntry? = nil
            if p!.parent !== nil {
                tmp = p!.parent
            } else {
                return nil
            }
            return tmp
        }
    }
    
    fileprivate func leftOf(_ p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
        return (p == nil) ? nil: p!.left
        
    }
    
    fileprivate func rightOf(_ p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
        return (p == nil) ? nil: p!.right
    }
    
    mutating  fileprivate func rotateLeft(_ p: VanKreveldStatusEntry?) {
        if p != nil {
            let r: VanKreveldStatusEntry? = p!.right
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
                root = r
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
            p!.maxSlope = max( p!.slope, max(maxSlopeOf(p!.left), maxSlopeOf(p!.right)) )
        }
    }
    
    fileprivate mutating func rotateRight(_ p: VanKreveldStatusEntry?) {
        if p != nil {
            let l: VanKreveldStatusEntry? = p!.left
            
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
                root = l
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
            p!.maxSlope = max( p!.slope, max(maxSlopeOf(p!.left), maxSlopeOf(p!.right)) )
        }
    }
    
    fileprivate mutating func fixAfterDeletion(_ xx: VanKreveldStatusEntry?) {
        var xx = xx
        while (xx !== root && flagOf(xx) == FLAG_TRUE) {
            if (xx === leftOf(parentOf(xx))) {
                var sib: VanKreveldStatusEntry? = rightOf(parentOf(xx))
                
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
                var sib: VanKreveldStatusEntry? = leftOf(parentOf(xx))
                
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
    
    // check the visibility of this cell to the observer
    public func isVisible(_ pt: VanKreveldCell) -> Bool {
        var isVisible: Bool = false
        
        let key: Double = sqrt(pow(Double(reference.x) - Double(pt.x), 2) + pow(Double(reference.y) - Double(pt.y), 2))
        var x: VanKreveldStatusEntry? = root
        
        if (x === nil) {
            return isVisible
        }
        
        var maxSlope: Double = -Double.infinity
        // parent
        var parent: VanKreveldStatusEntry? = x
        
        while (x !== nil) {
            if (key < x!.key) {
                parent = x
                x = x!.left
            } else {
                parent = x
                x = x!.right
                maxSlope = max(maxSlope, maxSlopeOf(parent!.left))
            }
        }
        
        if maxSlope <= parent!.slope {
            isVisible = true
        }
        return isVisible
    }
}
