import Foundation

// based on the paper : http://www.cs.uu.nl/research/techreps/repo/CS-1996/1996-22.pdf
public struct KreveldActiveBinaryTree {
    static let FLAG_FALSE: Bool = false
    static let FLAG_TRUE: Bool = true
    private var root: VanKreveldStatusEntry?
    private var reference: VanKreveldCell
    
    init(reference: VanKreveldCell) {
        self.reference = reference
    }
    
    public mutating func insert (value: VanKreveldCell) {
        // ecludian distance in grid units
        let key : Double = sqrt(pow(Double(self.reference.x) - Double(value.x), 2) + pow(Double(self.reference.y) - Double(value.y), 2))
        
        let oppositeInMeters:Double = value.h - self.reference.h

        // find the slope of the line from the current cell to the observer
        let slopeMonotonicMeasure:Double = oppositeInMeters/key
        
        var y: VanKreveldStatusEntry? = nil
        var x: VanKreveldStatusEntry? = self.root
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
    
    private mutating func fixAfterInsertion(xx: VanKreveldStatusEntry?) {
        var xx = xx
        while xx != nil &&  xx !== self.root && xx!.parent !== nil && xx!.parent!.flag == KreveldActiveBinaryTree.FLAG_FALSE {
            let greatGreatLeft :VanKreveldStatusEntry? = self.leftOf(self.parentOf(self.parentOf(xx)))
            
            if (self.parentOf(xx) === greatGreatLeft) {
                let y:VanKreveldStatusEntry? = self.rightOf(self.parentOf(self.parentOf(xx)))
                if self.flagOf(y) == KreveldActiveBinaryTree.FLAG_FALSE {
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(y, c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBinaryTree.FLAG_FALSE)
                    xx = self.parentOf(self.parentOf(xx))
                } else {
                    if xx === self.rightOf(self.parentOf(xx)) {
                        xx = self.parentOf(xx)
                        self.rotateLeft(xx)
                    }
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBinaryTree.FLAG_FALSE)
                    self.rotateRight(self.parentOf(self.parentOf(xx)))
                }
            } else {
                let y:VanKreveldStatusEntry? = self.leftOf(self.parentOf(self.parentOf(xx)))
                if self.flagOf(y) == KreveldActiveBinaryTree.FLAG_FALSE {
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(y, c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBinaryTree.FLAG_FALSE)
                    xx = self.parentOf(self.parentOf(xx))
                } else {
                    if xx === self.leftOf(self.parentOf(xx)) {
                        xx = self.parentOf(xx)
                        self.rotateRight(xx)
                    }
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(self.parentOf(xx)), c: KreveldActiveBinaryTree.FLAG_FALSE)
                    self.rotateLeft(self.parentOf(self.parentOf(xx)))
                }
            }
        }
        if self.root != nil {
            self.root!.flag = KreveldActiveBinaryTree.FLAG_TRUE
        }
    }
    
    public mutating func delete (pt: VanKreveldCell) {
        
        // verify if all the 'nil' check necessary
        var p: VanKreveldStatusEntry? = self.getEntry(pt)
        if p == nil {
            return
        }
        // If strictly internal, copy successor's element to p and then make p
        // point to successor.
        // Because of (p.right != null) the successor of p is the minimum of p.right
        if p!.left != nil && p!.right != nil {
            let s:VanKreveldStatusEntry! = self.getMinimum(p!.right) // = successor(p)
            p!.key = s.key
            p!.value = s.value
            p!.slope = s.slope
            p = s
        }
        // update maxSlope
        p!.maxSlope = max(self.maxSlopeOf(p!.left), self.maxSlopeOf(p!.right)); // dummy value
        var x: VanKreveldStatusEntry? = p!.parent;
        while (x != nil) {
            x!.maxSlope = max( x!.slope, max(self.maxSlopeOf(x!.left), self.maxSlopeOf(x!.right)) );
            x = x!.parent;
        }
        // Start fixup at replacement node, if it exists.
        let replacement: VanKreveldStatusEntry? = (p!.left != nil ? p!.left : p!.right);
        
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
            if (p!.flag == KreveldActiveBinaryTree.FLAG_TRUE) {
                self.fixAfterDeletion(replacement)
            }
        } else if (p!.parent == nil) { // return if we are the only node.
            self.root = nil
        } else { //  No children. Use self as phantom replacement and unlink.
            if (p!.flag == KreveldActiveBinaryTree.FLAG_TRUE) {
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
    
//     Searches the status structure for a point p and returns the corresponding StatusEntry.
//     param p HeightedPoint to be searched
//     returns StatusEntry
    private func getEntry(let p: VanKreveldCell) -> VanKreveldStatusEntry? {
        let key: Double = sqrt(pow(Double(self.reference.x) - Double(p.x), 2) + pow(Double(self.reference.y) - Double(p.y), 2))
        var t: VanKreveldStatusEntry? = self.root
        
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
    
    private func getMinimum (let p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
        if (p == nil) {
            return nil
        }
        var min: VanKreveldStatusEntry? = p
        while (min!.left != nil) {
            min = min!.left
        }
        return min!
    }
    
    private func maxSlopeOf(p: VanKreveldStatusEntry?) -> Double {
        return (p == nil ? -Double.infinity: p!.maxSlope);
    }
    
    private func flagOf(p: VanKreveldStatusEntry?) -> Bool {
        
        return (p == nil ? KreveldActiveBinaryTree.FLAG_TRUE : p!.flag);
    }
    
    private func setFlag(let p: VanKreveldStatusEntry?, c:Bool) {
        if p != nil {
            p!.flag = c
        }
    }
    
    private func parentOf(let p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
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
    
    private func leftOf(let p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
        return (p == nil) ? nil: p!.left
        
    }
    
    private func rightOf(let p: VanKreveldStatusEntry?) -> VanKreveldStatusEntry? {
        return (p == nil) ? nil: p!.right
    }
    
    mutating  private func rotateLeft(let p: VanKreveldStatusEntry?) {
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
    
    private mutating func rotateRight(let p: VanKreveldStatusEntry?) {
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
    
    private mutating func fixAfterDeletion(xx: VanKreveldStatusEntry?) {
        var xx = xx
        while (xx !== self.root && self.flagOf(xx) == KreveldActiveBinaryTree.FLAG_TRUE) {
            if (xx === self.leftOf(self.parentOf(xx))) {
                var sib: VanKreveldStatusEntry? = self.rightOf(self.parentOf(xx))
                
                if self.flagOf(sib) == KreveldActiveBinaryTree.FLAG_FALSE {
                    self.setFlag(sib, c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_FALSE)
                    self.rotateLeft(self.parentOf(xx))
                    sib = self.rightOf(self.parentOf(xx))
                }
                
                if (self.flagOf(self.leftOf(sib))  == KreveldActiveBinaryTree.FLAG_TRUE &&  self.flagOf(self.rightOf(sib)) == KreveldActiveBinaryTree.FLAG_TRUE) {
                    self.setFlag(sib, c: KreveldActiveBinaryTree.FLAG_FALSE)
                    xx = self.parentOf(xx)
                    
                } else {
                    if (self.flagOf(self.rightOf(sib)) == KreveldActiveBinaryTree.FLAG_TRUE) {
                        self.setFlag(self.leftOf(sib), c: KreveldActiveBinaryTree.FLAG_TRUE)
                        self.setFlag(sib, c: KreveldActiveBinaryTree.FLAG_FALSE)
                        self.rotateRight(sib)
                        sib = self.rightOf(self.parentOf(xx))
                    }
                    self.setFlag(sib, c: self.flagOf(self.parentOf(xx)))
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.rightOf(sib), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.rotateLeft(self.parentOf(xx))
                    xx = self.root
                }
            } else { // symmetric
                var sib: VanKreveldStatusEntry? = self.leftOf(self.parentOf(xx))
                
                if (self.flagOf(sib) == KreveldActiveBinaryTree.FLAG_FALSE) {
                    self.setFlag(sib, c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_FALSE)
                    self.rotateRight(self.parentOf(xx))
                    sib = self.leftOf(self.parentOf(xx))
                }
                
                if (self.flagOf(self.rightOf(sib)) == KreveldActiveBinaryTree.FLAG_TRUE &&
                    self.flagOf(self.leftOf(sib)) == KreveldActiveBinaryTree.FLAG_TRUE) {
                        self.setFlag(sib, c: KreveldActiveBinaryTree.FLAG_FALSE)
                        xx = self.parentOf(xx)
                } else {
                    if (self.flagOf(self.leftOf(sib)) == KreveldActiveBinaryTree.FLAG_TRUE) {
                        self.setFlag(self.rightOf(sib), c: KreveldActiveBinaryTree.FLAG_TRUE)
                        self.setFlag(sib, c: KreveldActiveBinaryTree.FLAG_FALSE)
                        self.rotateLeft(sib)
                        sib = self.leftOf(self.parentOf(xx))
                    }
                    self.setFlag(sib, c: self.flagOf(self.parentOf(xx)))
                    self.setFlag(self.parentOf(xx), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.setFlag(self.leftOf(sib), c: KreveldActiveBinaryTree.FLAG_TRUE)
                    self.rotateRight(self.parentOf(xx))
                    xx = self.root
                }
            }
        }
        self.setFlag(xx, c: KreveldActiveBinaryTree.FLAG_TRUE)
    }
    
    // check the visibility of this cell to the observer
    public func isVisible(pt: VanKreveldCell) -> Bool {
        var isVisible: Bool = false
        
        let key: Double = sqrt(pow(Double(self.reference.x) - Double(pt.x), 2) + pow(Double(self.reference.y) - Double(pt.y), 2))
        var x: VanKreveldStatusEntry? = self.root
        
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
                maxSlope = max(maxSlope, self.maxSlopeOf(parent!.left))
            }
        }
        
        if maxSlope <= parent!.slope {
            isVisible = true
        }
        return isVisible
    }
}
