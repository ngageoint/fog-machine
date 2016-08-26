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
    var increment:Float
    var vertexSource:SCNGeometrySource
    var maxScaledElevation:Float
    
    // MARK: Initializer
    
    init(elevation: [[Int]], increment: Float) {
        self.elevation = []
        self.increment = increment
        self.vertexSource = SCNGeometrySource()
        self.maxScaledElevation = 1.0
        super.init()
        self.elevation = rotateElevationXAxis(elevation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Process Functions
    
    func generateScene() {
        self.addChildNode(SCNNode(geometry: calculateGeometry()))
    }
    
    func drawVertices() {
        self.addChildNode(generateLineNode(vertexSource, vertexCount: vertexSource.vectorCount))
    }
    
    func addObserver(altitude: Double) {
        self.addChildNode(generateObserverNode(altitude))
    }
    
    func addCamera() {
        self.addChildNode(generateCameraNode())
    }
    
    // MARK: Private Functions
    
    private func rotateElevationXAxis(inElevation:[[Int]]) -> [[Int]] {
        var outElevation:[[Int]] = []
        var rows = inElevation.count - 1
        while (rows >= 0) {
            outElevation.append(inElevation[rows])
            rows = rows - 1
        }
        return outElevation
    }
    
    private func calculateGeometry() -> SCNGeometry {
        let maxRows = elevation.count
        let maxColumns = elevation[0].count
        var vertices:[SCNVector3] = []
        var textures:[(x:Float, y:Float)] = []

        for row in 0..<(maxRows - 1) {
            for column in 0..<(maxColumns - 1) {
                
                let topLeftZ = Float(boundElevation(elevation[row][column]))
                let topRightZ = Float(boundElevation(elevation[row][column + 1]))
                let bottomLeftZ = Float(boundElevation(elevation[row + 1][column]))
                let bottomRightZ = Float(boundElevation(elevation[row + 1][column + 1]))

                let coordX = Float(column)
                let coordY = Float(row)
                
                let topLeft = SCNVector3Make(Float(coordX),
                                             Float(-coordY),
                                             Float(topLeftZ))
                
                let topRight = SCNVector3Make(Float(coordX)+Float(increment),
                                              Float(-coordY),
                                              Float(topRightZ))
                
                let bottomLeft = SCNVector3Make(Float(coordX),
                                                Float(-coordY)-Float(increment),
                                                Float(bottomLeftZ))
                
                let bottomRight = SCNVector3Make(Float(coordX)+Float(increment),
                                                 Float(-coordY)-Float(increment),
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
        
        // Create Indices
        var geometryData:[CInt] = []
        var geometryCount: CInt = 0
        while (geometryCount < CInt(vertexSource.vectorCount)) {
            geometryData.append(geometryCount)
            geometryData.append(geometryCount+2)
            geometryData.append(geometryCount+1)
            geometryData.append(geometryCount)
            geometryData.append(geometryCount+3)
            geometryData.append(geometryCount+2)
            geometryCount += 4
        }
        let element:SCNGeometryElement = SCNGeometryElement(indices: geometryData, primitiveType: .Triangles)
        
        //Create SCNGeometry
        let geometry:SCNGeometry = SCNGeometry(sources: geometrySources, elements: [element])
        
        //Add some color
        let colorMaterial = SCNMaterial()
        colorMaterial.diffuse.contents = UIColor.greenColor()
        colorMaterial.doubleSided = true
        geometry.materials = [colorMaterial]

        return geometry
    }
    
    func generateObserverNode(altitude: Double) -> SCNNode {
        let observerCapsule = SCNCapsule(capRadius: 0.125, height: 0.5)
        let capsuleSizeFactor:Float = 0.25
        let observerNode = SCNNode(geometry: observerCapsule)
        let column: Int = elevation[0].count / 2
        let row: Int = elevation.count / 2
        let observerY:Float = -Float(row + 1)
        let observerX:Float = Float(column - 1)
        let boundedElevation:Float = boundElevation(elevation[row - 1][column - 1], altitude: Float(altitude))
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
            lineData.append(lineCount+1)
            lineData.append(lineCount+1)
            lineData.append(lineCount+2)
            lineData.append(lineCount+2)
            lineData.append(lineCount+3)
            lineData.append(lineCount+3)
            lineData.append(lineCount)
            lineData.append(lineCount+0)
            lineData.append(lineCount+2)
            lineCount = lineCount + 4
        }
        
        let lineEle = SCNGeometryElement(indices: lineData, primitiveType: .Line)
        let lineGeo = SCNGeometry(sources: [vertexSource], elements: [lineEle])
        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor.darkGrayColor()
        lineGeo.materials = [whiteMaterial]

        return SCNNode(geometry: lineGeo)
    }
    
    private func generateCameraNode() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        let cameraFactor = 20
        let cameraZ = Float(Int(maxScaledElevation) + cameraFactor)
        let cameraX:Float = Float(elevation.count / 2)
        let cameraY:Float = -Float(elevation[0].count / 2)
        cameraNode.position = SCNVector3Make(cameraX, cameraY, cameraZ)
        
        return cameraNode
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

        // Resolution of each increment
        let sizeFactor:Float = 30.0
        
        boundedElevation = (boundedElevation + altitude) / sizeFactor
        
        //While checking each elevation, record the maxScaledElevation
        if (maxScaledElevation < boundedElevation) {
            maxScaledElevation = boundedElevation
        }
            
        return boundedElevation
    }
    
}