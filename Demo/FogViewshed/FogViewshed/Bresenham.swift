import UIKit

class Bresenham: NSObject {

    
    private static func reverseResults(matrix: [(x:Int,y:Int)]) -> [(x:Int,y:Int)] {
        var results:[(x:Int,y:Int)] = []
        for (x,y) in matrix.reverse() {
            results.append((x, y))
        }
        return results
    }

    
    //Adopted from http://rosettacode.org/wiki/Bitmap/Bresenham's_line_algorithm#Java
    internal static func findLine(x1: Int, y1: Int, x2: Int, y2: Int) -> [(x:Int,y:Int)] {
        // To substitude for the removal of var in parameters
        var x1 = x1
        var y1 = y1
        
        var results:[(x:Int,y:Int)] = []
        let obsX = x1
        let obsY = y1
        
        // delta of exact value and rounded value of the dependant variable
        var d = 0;
        
        let dy = abs(y2 - y1);
        let dx = abs(x2 - x1);
        
        let dy2 = (dy << 1); // slope scaling factors to avoid floating
        let dx2 = (dx << 1); // point
        
        let ix = x1 < x2 ? 1 : -1; // increment direction
        let iy = y1 < y2 ? 1 : -1;
        
        if (dy <= dx) {
            while true {
                if (x1 != obsX || y1 != obsY) { // skip the observer point
                    results.append((x1, y1))
                }
                if (x1 == x2) {
                    break;
                }
                x1 += ix;
                d += dy2;
                if (d > dx) {
                    y1 += iy;
                    d -= dx2;
                }
            }
        } else {
            while true {
                if (x1 != obsX || y1 != obsY) { // skip the observer point
                    results.append((x1, y1))
               }
                if (y1 == y2) {
                    break;
                }
                y1 += iy;
                d += dx2;
                if (d > dy) {
                    x1 += ix;
                    d -= dy2;
                }
            }
        }
        
        return results
    }
    
    
}
