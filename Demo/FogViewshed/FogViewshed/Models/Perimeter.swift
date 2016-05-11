import Foundation


protocol Perimeter {
    
    func resetPerimeter()
    
    func hasAnotherPerimeterCell() -> Bool
    
    func getNextPerimeterCell() -> (x:Int,y:Int)
}