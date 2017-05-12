import UIKit

/**
 
 Bresenham's line algorithm is an algorithm that determines the points of an n-dimensional raster that should be selected in order to form a close approximation to a straight line between two points.
 
 see https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
 
 */
open class BresenhamsLineAlgoritm: NSObject {
    
    /**
     
     see http://rosettacode.org/wiki/Bitmap/Bresenham's_line_algorithm#Java
     
     */
    open static func findLine(x1 x1arg: Int, y1 y1arg: Int, x2: Int, y2: Int) -> [(x: Int, y: Int)] {
        
        var x1 = x1arg
        var y1 = y1arg
        
        var line: [(x: Int, y: Int)] = []
        
        // delta of exact value and rounded value of the dependant variable
        var d = 0
        
        let dy = abs(y2 - y1)
        let dx = abs(x2 - x1)
        
        let dy2 = (dy << 1) // slope scaling factors to avoid floating point
        let dx2 = (dx << 1)
        
        let ix = x1 < x2 ? 1 : -1 // increment direction
        let iy = y1 < y2 ? 1 : -1
        
        if (dy <= dx) {
            while true {
                line.append((x1, y1))
                if (x1 == x2) {
                    break
                }
                x1 += ix
                d += dy2
                if (d > dx) {
                    y1 += iy
                    d -= dx2
                }
            }
        } else {
            while true {
                line.append((x1, y1))
                if (y1 == y2) {
                    break
                }
                y1 += iy
                d += dx2
                if (d > dy) {
                    x1 += ix
                    d -= dy2
                }
            }
        }
        return line
    }
}
