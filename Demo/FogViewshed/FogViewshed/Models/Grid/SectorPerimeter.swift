import Foundation

class SectorPerimeter: RectangularPerimeter {
    
    let sector: Sector
    var startIndex: Int
    var endIndex: Int
    var sectorSizeCount: Int
    var currentIndexCount: Int
    
    init(dataGrid: DataGrid, sector: Sector) {
        self.sector = sector
        self.startIndex = 0
        self.endIndex = 0
        self.sectorSizeCount = 0
        self.currentIndexCount = 0
        super.init(dataGrid: dataGrid)
        
        // remember that the sector angles are measured counter-clockwise, and the perimeter is given as clockwise from lower left
        
        // IMPORTANT: we can only assume that the start and end positions will intersect the edge of the boundingbox when the angle of the sector is <= 180 degrees.  example of non-intersection: startangle = 0 degrees, endangle = 315 degrees.  The nature of sectioning a cirlce equal parts does not allow for these tpyes of situations.  (The case where there is one device, where a sector is a circle, is taken care of by different means)
        let startXY: (Int, Int) = dataGrid.latLonToIndex(sector.getEndPosition())
        self.perimeterCellIndex = XYToIndex(startXY)
        self.startIndex = Int(perimeterCellIndex)
        
        let endXY: (Int, Int) = dataGrid.latLonToIndex(sector.getStartPosition())
        endIndex = XYToIndex(endXY)
        //endIndex = (endIndex+1)%perimeterSize
        
        self.sectorSizeCount = endIndex - startIndex
        if(self.startIndex > self.endIndex) {
            self.sectorSizeCount = (perimeterSize - startIndex) + endIndex
        }
        self.currentIndexCount = 0
    }
    
    override func hasAnotherPerimeterCell() -> Bool {
        return (currentIndexCount < sectorSizeCount)
    }
    
    override func getNextPerimeterCell() -> (x: Int, y: Int) {
        let cell: (Int, Int) = super.getNextPerimeterCell()
        perimeterCellIndex = perimeterCellIndex%perimeterSize
        self.currentIndexCount += 1
        return cell
    }
    
    override func resetPerimeter() {
        super.resetPerimeter()
        
        let startXY: (Int, Int) = dataGrid.latLonToIndex(sector.getEndPosition())
        self.perimeterCellIndex = XYToIndex(startXY)
        self.startIndex = Int(perimeterCellIndex)
        
        let endXY: (Int, Int) = dataGrid.latLonToIndex(sector.getStartPosition())
        endIndex = XYToIndex(endXY)
        
        self.sectorSizeCount = endIndex - startIndex
        if(self.startIndex > self.endIndex) {
            self.sectorSizeCount = (perimeterSize - startIndex) + endIndex
        }
        self.currentIndexCount = 0
    }
}
