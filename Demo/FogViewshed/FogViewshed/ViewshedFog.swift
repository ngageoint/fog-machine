import UIKit
import MapKit

public class ViewshedFog: NSObject {
    
    var elevation: [[Int]]
    var obsX: Int
    var obsY: Int
    var obsElevation: Int
    var viewRadius: Int
    var numberOfQuadrants: Int
    var whichQuadrant: Int
    
    
    init(elevation: [[Int]], observer: Observer, numberOfQuadrants: Int, whichQuadrant: Int) {
        self.elevation = elevation
        self.obsX = observer.xCoord
        self.obsY = observer.yCoord
        self.obsElevation = observer.elevation
        self.viewRadius = observer.getViewshedSrtm3Radius()
        self.numberOfQuadrants = numberOfQuadrants
        self.whichQuadrant = whichQuadrant
    }
    
    //Adopted from section 5.1 http://www.cs.rpi.edu/~cutler/publications/andrade_geoinformatica.pdf
    //        Given a terrain T represented by an n × n elevation matrix M, a point p on T , a radius
    //        of interest r, and a height h above the local terrain for the observer and target, this
    //        algorithm computes the viewshed of p within a distance r of p, as follows:
    public func viewshedParallel() -> [[Int]] {
        let rowMaxSize = self.elevation.count
        let columnMaxSize = self.elevation[0].count
        
        // Initialize results array as all un-viewable
        var viewshedMatrix = [[Int]](count:rowMaxSize, repeatedValue:[Int](count:columnMaxSize, repeatedValue:0))
        
        // 1. Let p’s coordinates be (xp, yp, zp). Then the observer O will be at (xp, yp, zp + h).
        
        // 2. Imagine a square in the plane z = 0 of side 2r × 2r centered on (xp, yp, 0).
        let perimeter:[(x:Int, y:Int)] = SquarePerimeter.getAnySizedPerimeter(obsX, inY: obsY, radius: viewRadius,
            numberOfQuadrants: numberOfQuadrants, whichQuadrant: whichQuadrant)
        
        viewshedMetrics.startForMetric(Metric.PERIMETER)
        // 3. Iterate through the cells c of the square’s perimeter. Each c has coordinates
        //  (xc, yc, 0), where the corresponding point on the terrain is (xc, yc, zc).
        for (x, y) in perimeter {
            // (a) For each c, run a straight line in M from (xp, yp, 0) to (xc, yc, 0).
            
            
            // (b) Find the points on that line, perhaps using Bresenham’s algorithm. In order
            //  from p to c, let them be q1 = p, q2, ··· qk−1, qk = c. A potential target Di at qi
            //  will have coordinates (xi, yi, zi + h).
            let bresResults:[(x:Int, y:Int)] = Bresenham.findLine(obsX, y1: obsY, x2: x, y2: y)
            
            //  (c) Let mi be the slope of the line from O to Di, that is,
            //   mi = ( zk − zi + p ) / sqrt( (xi − xp)2 + (yi − yp)^2 )
            
            // (d) Let µ be the greatest slope seen so far along this line. Initialize µ = −∞.
            var greatestSlope = -Double.infinity
            
            // e) Iterate along the line from p to c.
            for (x2, y2) in bresResults {
                // Skip values outside bounds
                if (x2 >= 0 && y2 >= 0) && (x2 < rowMaxSize && y2 < columnMaxSize) {
                    // i. For each point qi, compute mi.
                    let zk:Int = elevation[obsX][obsY]
                    let zi:Int = elevation[x2][y2]
                    
                    // angle = arctan(opposite/adjacent)
                    let opposite = ( zi - (zk + obsElevation) )
                    let adjacent = sqrt( pow(Double(x2 - obsX), 2) + pow(Double(y2 - obsY), 2) )
                    let angle:Double = (Double(opposite)/Double(adjacent)) // for the actual angle use atan()
                    
                    // ii. If mi < µ, then mark qi as hidden from O, that is, as not in the viewshed (which is simply a 2r × 2r bitmap).
                    // iii. Otherwise, mark qi as being in the viewshed, and update µ = mi.
                    if (angle < greatestSlope) {
                        //hidden
                        viewshedMatrix[x2][y2] = 0
                    } else {
                        greatestSlope = angle
                        //visible
                        viewshedMatrix[x2][y2] = 1
                    }
                }
                
            }
            
        }
        viewshedMetrics.stopForMetric(Metric.PERIMETER)
        viewshedMatrix[obsX][obsY] = -1 // mark observer cell as unique
        
        return viewshedMatrix
        
    }

    
    
}
