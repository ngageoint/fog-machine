import Foundation

class RectangularPerimeter: Perimeter {

    let dataGrid: DataGrid
    let rowSize: Int
    let columnSize: Int
    var perimeterSize: Int
    var perimeterCellIndex: Int
    
    init(dataGrid: DataGrid) {
        self.dataGrid = dataGrid
        self.rowSize = dataGrid.data[0].count
        self.columnSize = dataGrid.data.count
        
        self.perimeterCellIndex = 0
        self.perimeterSize = 1
        
        if(rowSize == 1 && columnSize == 1) {
            perimeterSize = 1
        } else if(rowSize == 1) {
            perimeterSize = columnSize
        } else if(columnSize == 1) {
            perimeterSize = rowSize
        } else {
            perimeterSize = 2 * (rowSize + columnSize - 2)
        }
    }

    func resetPerimeter() {
        self.perimeterCellIndex = 0
    }
    
    func hasAnotherPerimeterCell() -> Bool {
        return (perimeterCellIndex < perimeterSize)
    }

    func getNextPerimeterCell() -> (x: Int, y: Int) {
        var cell: (Int, Int) = (0, 0)
        if(hasAnotherPerimeterCell()) {
            var i: Int = Int(perimeterCellIndex)
            
            if(i >= 0 && i < columnSize - 1) {
                cell = (0, i)
            } else {
                i = i - (columnSize - 1)
                if(i >= 0 && i < rowSize - 1) {
                    cell = (i, columnSize - 1)
                } else {
                    i = i - (rowSize - 1)
                    if(i >= 0 && i < columnSize - 1) {
                        cell = (rowSize - 1, columnSize - 1 - i)
                    } else {
                        i = i - (columnSize - 1)
                        if(i >= 0 && i < rowSize - 1) {
                            cell = (rowSize - 1 - i, 0)
                        } else {
                            i = i - (rowSize - 1)
                            NSLog("Error: Index \(perimeterCellIndex) is out of bounds")
                        }
                    }
                }
            }
        }
        perimeterCellIndex += 1
        return cell
    }
    
    func XYToIndex(_ xy: (Int, Int)) -> Int {
        // for the left side and top side, the index is (the row index + the column index)
        var index: Int = xy.0 + xy.1
        
        // make sure this is a non-degenerate case
        if(rowSize > 1 && columnSize > 1) {
            // if the index is on the bottom side or the right side, we need to account for the indexes already seen by the left and right side
            if(((xy.1 == 0) && (xy.0 > 0)) || ((xy.0 == rowSize - 1) && (xy.1 < columnSize - 1))) {
                index = perimeterSize - (xy.0 + xy.1)
            }
        }
        return index
    }

//    private func getPerimeterCells() -> [(x:Int,y:Int)] {
//        // Perimeter goes clockwise from the lower left coordinate
//        var perimeter:[(x:Int, y:Int)] = []
//        
//        let rowSize:Int =  dataGrid.data.count
//        let columnSize:Int = dataGrid.data[0].count
//        
//        var perimeterSize:Int
//        
//        if(rowSize == 1 && columnSize == 1) {
//            perimeterSize = 1
//        } else if(rowSize == 1) {
//            perimeterSize = columnSize
//        } else if(columnSize == 1) {
//            perimeterSize = rowSize
//        } else {
//            perimeterSize = 2*(rowSize + columnSize - 2)
//        }
//        
//        if(perimeterSize == 1) {
//            perimeter.append((0,0))
//        } else {
//            // lower left to top left
//            var i:Int = 0
//            while(i <= columnSize - 1) {
//                perimeter.append((0, i))
//                i = i + 1
//            }
//            
//            // top left to top right (excludes corners)
//            i = 1
//            while(i <= rowSize - 2) {
//                perimeter.append((i, columnSize - 1))
//                i = i + 1
//            }
//            
//            // top right to lower right
//            i = columnSize - 1
//            while(i >= 0) {
//                perimeter.append((rowSize - 1, i))
//                i = i - 1
//            }
//            
//            // lower right to lower left (excludes corners)
//            i = rowSize - 2
//            while(i >= 1) {
//                perimeter.append((i, 0))
//                i = i - 1
//            }
//        }
//        
//        if(perimeterSize != perimeter.count) {
//            NSLog("Perimeter was the wrong size! Expected: \(perimeterSize), received: \(perimeter.count)")
//        }
//        
//        return perimeter
//    }
}
