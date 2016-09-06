//
//  ElevationScene.swift
//  FogViewshed
//

import Foundation
import SceneKit
import MapKit


class ElevationScene: SCNNode {
    
    // MARK: Variables

    var elevation:[[Int]]
    var vertexSource:SCNGeometrySource
    var maxScaledElevation:Float
    var image:UIImage?
    let cellSize:Float = 1.0
    
    // MARK: Initializer
    
    init(elevation: [[Int]], viewshedImage: UIImage?) {
        self.elevation = elevation
        self.vertexSource = SCNGeometrySource()
        self.maxScaledElevation = 1.0
        self.image = viewshedImage
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Process Functions
    
    func generateScene() {
        self.addChildNode(SCNNode(geometry: createGeometry()))
    }
    
    func drawVertices() {
        self.addChildNode(generateLineNode(vertexSource, vertexCount: vertexSource.vectorCount))
    }
    
    func addObserver(location: (Int, Int), altitude: Double) {
        self.addChildNode(generateObserverNode(location, altitude: altitude))
    }
    
    func addCamera() {
        self.addChildNode(generateCameraNode())
    }
    
    // MARK: Private Functions
    
    private func createGeometry() -> SCNGeometry {
        let geometry:SCNGeometry = calculateGeometry()
        addImageToGeometry(geometry)
        
        return geometry
    }
    
    private func calculateGeometry() -> SCNGeometry {
        let maxRows = elevation.count
        let maxColumns = elevation[0].count
        var vertices:[SCNVector3] = []
        var textures:[(x:Float, y:Float)] = []

        for row in 0..<(maxRows - 1) {
            for column in 0..<(maxColumns - 1) {
                let topLeftZ = getElevationAtLocation(row, column: column)
                let topRightZ = getElevationAtLocation(row, column: column + 1)
                let bottomLeftZ = getElevationAtLocation(row + 1, column: column)
                let bottomRightZ = getElevationAtLocation(row + 1, column: column + 1)

                let coordX = Float(column)
                let coordY = Float(row)
                
                let topLeft = SCNVector3Make(Float(coordX),
                                             Float(-coordY),
                                             Float(topLeftZ))
                
                let topRight = SCNVector3Make(Float(coordX) + cellSize,
                                              Float(-coordY),
                                              Float(topRightZ))
                
                let bottomLeft = SCNVector3Make(Float(coordX),
                                                Float(-coordY) - cellSize,
                                                Float(bottomLeftZ))
                
                let bottomRight = SCNVector3Make(Float(coordX) + cellSize,
                                                 Float(-coordY) - cellSize,
                                                 Float(bottomRightZ))
                
                vertices.append(topLeft)
                vertices.append(topRight)
                vertices.append(bottomRight)
                vertices.append(bottomLeft)
                
                let columnScale = Float(maxColumns) - 1
                let rowScale = Float(maxRows) - 1
                
                let topLeftTexture =  (x:Float(coordX / columnScale), y:Float(coordY / rowScale))
                let bottomLeftTexture =  (x:Float((coordX + 1) / columnScale), y:Float(coordY / rowScale))
                let topRightTexture =  (x:Float(coordX / columnScale), y:Float((coordY + 1) / rowScale))
                let bottomRightTexture = (x:Float((coordX + 1) / columnScale), y:Float((coordY + 1) / rowScale))
                
                textures.append(topLeftTexture)
                textures.append(bottomLeftTexture)
                textures.append(bottomRightTexture)
                textures.append(topRightTexture)
            }
        }
        
        var geometrySources:[SCNGeometrySource] = []
        
        //Add vertex
        vertexSource = SCNGeometrySource(vertices: vertices, count: vertices.count)
        geometrySources.append(vertexSource)

        //Add normal
        let normal = SCNVector3(0, 0, 1)
        var normals:[SCNVector3] = []
        for _ in 0..<vertexSource.vectorCount {
            normals.append(normal)
        }
        let normalSource:SCNGeometrySource = SCNGeometrySource(vertices: normals, count: normals.count)
        geometrySources.append(normalSource)
        
        //Add textures
        let textureData = NSData(bytes: textures, length: (sizeof((x:Float, y:Float)) * textures.count))
        let textureSource = SCNGeometrySource(data: textureData,
                                              semantic: SCNGeometrySourceSemanticTexcoord,
                                              vectorCount: textures.count,
                                              floatComponents: true,
                                              componentsPerVector: 2,
                                              bytesPerComponent: sizeof(Float),
                                              dataOffset: 0,
                                              dataStride: sizeof((x:Float, y:Float)))
        
        geometrySources.append(textureSource)
        
        //Create Indices
        var geometryData:[CInt] = []
        var geometryCount: CInt = 0
        while (geometryCount < CInt(vertexSource.vectorCount)) {
            geometryData.append(geometryCount)
            geometryData.append(geometryCount + 2)
            geometryData.append(geometryCount + 1)
            geometryData.append(geometryCount)
            geometryData.append(geometryCount + 3)
            geometryData.append(geometryCount + 2)
            geometryCount += 4
        }
        let element:SCNGeometryElement = SCNGeometryElement(indices: geometryData, primitiveType: .Triangles)
        
        //Create SCNGeometry
        let geometry:SCNGeometry = SCNGeometry(sources: geometrySources, elements: [element])
        
        return geometry
    }
    
    private func addImageToGeometry(geometry: SCNGeometry) -> SCNGeometry {
        let imageMaterial = SCNMaterial()
        if let viewshedImage = self.image {
            imageMaterial.diffuse.contents = viewshedImage
        } else {
            imageMaterial.diffuse.contents = UIColor.darkGrayColor()
        }
        imageMaterial.doubleSided = true
        geometry.materials = [imageMaterial]
        
        return geometry
    }
    
    private func generateObserverNode(location: (Int, Int), altitude: Double) -> SCNNode {
        let observerCapsule = SCNCapsule(capRadius: 0.125, height: 0.5)
        let capsuleSizeFactor:Float = 0.25
        let observerNode = SCNNode(geometry: observerCapsule)
        let row: Int = location.1
        let column: Int = location.0
        let observerY:Float = -Float(row)
        let observerX:Float = Float(column)
        let boundedElevation:Float = getElevationAtLocation(row - 1, column: column - 1, additionalAltitude: Float(altitude))
        let observerZ: Float = Float(boundedElevation) + capsuleSizeFactor
        observerNode.position = SCNVector3Make(observerX, observerY, observerZ)
        observerNode.eulerAngles = SCNVector3Make(Float(M_PI_2), 0, 0)
        
        return observerNode
    }
    
    private func generateLineNode(vertexSource: SCNGeometrySource, vertexCount: Int) -> SCNNode {
        var lineData:[CInt] = []
        var lineCount: CInt = 0
        while (lineCount < CInt(vertexCount)) {
            lineData.append(lineCount)
            lineData.append(lineCount + 1)
            lineData.append(lineCount + 1)
            lineData.append(lineCount + 2)
            lineData.append(lineCount + 2)
            lineData.append(lineCount + 3)
            lineData.append(lineCount + 3)
            lineData.append(lineCount)
            lineData.append(lineCount + 0)
            lineData.append(lineCount + 2)
            lineCount = lineCount + 4
        }
        
        let lineEle = SCNGeometryElement(indices: lineData, primitiveType: .Line)
        let lineGeo = SCNGeometry(sources: [vertexSource], elements: [lineEle])
        let whiteMaterial = SCNMaterial()
        if self.image != nil {
            whiteMaterial.diffuse.contents = UIColor.darkGrayColor()
        } else {
            whiteMaterial.diffuse.contents = UIColor.whiteColor()
        }
        lineGeo.materials = [whiteMaterial]

        return SCNNode(geometry: lineGeo)
    }
    
    private func generateCameraNode() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // Add an additional 20 cellSize units to set the camera above the scene
        let cameraFactor:Float = self.cellSize * 20
        let cameraZ = maxScaledElevation + cameraFactor
        let cameraX:Float = Float(elevation[0].count / 2)
        let cameraY:Float = -Float(elevation.count / 2)
        cameraNode.position = SCNVector3Make(cameraX, cameraY, cameraZ)
        
        return cameraNode
    }
    
    private func getElevationAtLocation(row: Int, column: Int, additionalAltitude:Float = 0.0) -> Float {
        let maxRows:Int = elevation.count - 1
        let actualRow:Int = maxRows - row
        let elevationValue: Float = boundElevation(elevation[actualRow][column])
        
        return elevationValue
    }
    
    // Bound elevation to remove data voids and unknown values
    private func boundElevation(unboundElevation:Int, altitude:Float = 0.0) -> Float {
        var boundedElevation:Float = Float(unboundElevation)

        // Remove data voids and invalid elevations
        if (unboundElevation < Elevation.MIN_BOUND) {
            boundedElevation = Float(Elevation.MIN_BOUND)
        } else if (unboundElevation > Elevation.MAX_BOUND) {
            boundedElevation = Float(Elevation.MAX_BOUND)
        }

        // Scale elevation by 99.7% to render in the Scene
        let scaleFactor:Float = 0.997
        let elevationRange:Float = Float(Elevation.MAX_BOUND - Elevation.MIN_BOUND)
        let sizeFactor:Float = elevationRange - elevationRange * scaleFactor
        
        boundedElevation = (boundedElevation + altitude) / sizeFactor
        
        //While checking each elevation, record the maxScaledElevation
        if (maxScaledElevation < boundedElevation) {
            maxScaledElevation = boundedElevation
        }
            
        return boundedElevation
    }
    
}