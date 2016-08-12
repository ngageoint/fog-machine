//
//  ElevationScene.swift
//  FogViewshed
//

import Foundation
import SceneKit
import MapKit


class ElevationScene: SCNNode {
    
    // MARK: Variables
    
    var upperLeftCoordinate:CLLocationCoordinate2D
    var elevation:[[Int]]
    var increment:Float
    var vertexSource:SCNGeometrySource
    var maxElevation:Int
    
    // MARK: Initializer
    
    init(upperLeftCoordinate: CLLocationCoordinate2D, elevation: [[Int]], increment: Float) {
        self.upperLeftCoordinate = upperLeftCoordinate
        self.elevation = elevation
        self.increment = increment
        self.vertexSource = SCNGeometrySource()
        self.maxElevation = 0
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Process Functions
    
    func generateScene() {
        self.addChildNode(SCNNode(geometry: calculateGeometry()))
    }
    
    func drawVerticies() {
        self.addChildNode(generateLineNode(vertexSource, vertexCount: vertexSource.vectorCount))
    }
    
    func addObserver(altitude: Double) {
        self.addChildNode(generateObserverNode(Int(altitude)))
    }
    
    func getCameraElevation() -> Int {
        let cameraFactor = 20
        return maxElevation + cameraFactor
    }
    
    // MARK: Private Functions
    
    private func calculateGeometry() -> SCNGeometry {
        let maxRows = elevation.count
        let maxColumns = elevation[0].count
        var verticies:[SCNVector3] = []
        var textures:[(x:Float, y:Float)] = []
        
        for row in 0..<maxRows - 1 {
            for column in 0..<maxColumns - 1 {
                //For vertices
                let upperLeftVector: SCNVector3 = SCNVector3Make(
                    Float(upperLeftCoordinate.longitude) + (Float(column) * increment),
                    Float(upperLeftCoordinate.latitude) - (Float(row) * increment),
                    Float(boundElevation(elevation[row][column])))
                
                let upperRightVector: SCNVector3 = SCNVector3Make(
                    Float(upperLeftCoordinate.longitude) + (Float(column + 1) * increment),
                    Float(upperLeftCoordinate.latitude) - (Float(row) * increment),
                    Float(boundElevation(elevation[row][column + 1])))
                
                let lowerLeftVector: SCNVector3 = SCNVector3Make(
                    Float(upperLeftCoordinate.longitude) + (Float(column) * increment),
                    Float(upperLeftCoordinate.latitude) - (Float(row + 1) * increment),
                    Float(boundElevation(elevation[row + 1][column])))

                let lowerRightVector: SCNVector3 = SCNVector3Make(
                    Float(upperLeftCoordinate.longitude) + (Float(column + 1) * increment),
                    Float(upperLeftCoordinate.latitude) - (Float(row + 1) * increment),
                    Float(boundElevation(elevation[row + 1][column + 1])))
                
                verticies.append(upperLeftVector)
                verticies.append(upperRightVector)
                verticies.append(lowerLeftVector)
                verticies.append(lowerRightVector)

                //For Textures
                textures.append((x:Float(column), y:Float(row)))
                textures.append((x:Float(column + 1), y:Float(row)))
                textures.append((x:Float(column), y:Float(row + 1)))
                textures.append((x:Float(column + 1), y:Float(row + 1)))
                
            }
        }
        
        var geometrySources:[SCNGeometrySource] = []
        
        //Add vertex
        vertexSource = SCNGeometrySource(vertices: verticies, count: verticies.count)
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
            geometryData.append(geometryCount+3)
            geometryData.append(geometryCount)
            geometryData.append(geometryCount+3)
            geometryData.append(geometryCount+1)
            geometryCount += 4
        }
        let element:SCNGeometryElement = SCNGeometryElement(indices: geometryData, primitiveType: .Triangles)
        
        //Create final SCNGeometry
        let geometry:SCNGeometry = SCNGeometry(sources: geometrySources, elements: [element])
        
        //Add some color
        let colorMaterial = SCNMaterial()
        colorMaterial.diffuse.contents = UIColor.greenColor()
        geometry.materials = [colorMaterial]

        return geometry
    }
    
    
    func generateObserverNode(altitude: Int) -> SCNNode {
        let observerCapsule = SCNCapsule(capRadius: 0.5, height: 2.0)
        let observerNode = SCNNode(geometry: observerCapsule)
        
        let incrementXFactor: Int = elevation[0].count / 2
        let incrementYFactor: Int = elevation.count / 2
        let observerX = Float(upperLeftCoordinate.longitude) + Float(incrementXFactor)
        let observerY = Float(upperLeftCoordinate.latitude) - Float(incrementYFactor)
        //TODO: Verify elevation location of observer is accurate
        let observerZ: Float = Float(elevation[incrementXFactor][incrementYFactor] + altitude)
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
            lineData.append(lineCount+3)
            lineData.append(lineCount+3)
            lineData.append(lineCount+2)
            lineData.append(lineCount+2)
            lineData.append(lineCount)
            lineData.append(lineCount+1)
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
    
    // Bound elevation to remove data voids and unknown values
    private func boundElevation(elevation:Int) -> Int {
        var boundedElevation:Int = elevation
        
        if (elevation < Elevation.MIN_BOUND) {
            boundedElevation = Elevation.MIN_BOUND
        } else if (elevation > Elevation.MAX_BOUND) {
            boundedElevation = Elevation.MAX_BOUND
        }
        
        //While checking each elevation, record the maxElevation
        if (maxElevation < boundedElevation) {
            maxElevation = boundedElevation
        }
        
        return boundedElevation
    }
    
}