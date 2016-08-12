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
    
    // MARK: Initializer
    
    init(upperLeftCoordinate: CLLocationCoordinate2D, elevation: [[Int]], increment: Float) {
        self.upperLeftCoordinate = upperLeftCoordinate
        self.elevation = elevation
        self.increment = increment
        self.vertexSource = SCNGeometrySource()
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
    
    // MARK: Private Functions
    
    private func calculateGeometry() -> SCNGeometry {
        let maxRows = elevation.count
        let maxColumns = elevation[0].count
        var verticies:[SCNVector3] = []
        //var textures:[(x:Float, y:Float)] = []
        
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
                
                verticies.append(lowerLeftVector)
                verticies.append(upperLeftVector)
                verticies.append(upperRightVector)
                verticies.append(lowerRightVector)

                //For Textures
                
                //TODO: Texture stuff here
                
            }
        }
        
        var geometrySources:[SCNGeometrySource] = []
        
        //Add vertex
        vertexSource = SCNGeometrySource(vertices: verticies, count: verticies.count)
        geometrySources.append(vertexSource)

        //TODO: Add normal
//        let normal = SCNVector3(0, 0, 1)
//        var normals:[SCNVector3] = []
//        for _ in 0..<vertexSource.vectorCount {
//            normals.append(normal)
//        }
//        let normalSource:SCNGeometrySource = SCNGeometrySource(vertices: normals, count: normals.count)
        //geometrySources.append(normalSource)
        

        //TODO: Add textures
//        let textureData = NSData(bytes: textures, length: (sizeof((x:Float, y:Float)) * textures.count))
//        let textureSource = SCNGeometrySource(data: textureData,
//                                              semantic: SCNGeometrySourceSemanticTexcoord,
//                                              vectorCount: textures.count,
//                                              floatComponents: true,
//                                              componentsPerVector: 2,
//                                              bytesPerComponent: sizeof(Float),
//                                              dataOffset: 0,
//                                              dataStride: sizeof((x:Float, y:Float)))
        //geometrySources.append(textureSource)
        
        
        // Create Indices
        var geometryData:[CInt] = []
        var geometryCount: CInt = 0
        while (geometryCount < CInt(vertexSource.vectorCount)) {
            geometryData.append(geometryCount)
            geometryData.append(geometryCount+2)
            geometryData.append(geometryCount+3)
            geometryData.append(geometryCount)
            geometryData.append(geometryCount+1)
            geometryData.append(geometryCount+2)
            geometryCount += 4
        }
        let element:SCNGeometryElement = SCNGeometryElement(indices: geometryData, primitiveType: .Triangles)
        
        
        //Create final SCNGeometry
        let geometry:SCNGeometry = SCNGeometry(sources: geometrySources, elements: [element])
        
        
        //Add some color
        let greenMaterial = SCNMaterial()
        greenMaterial.diffuse.contents = UIColor.greenColor()
        geometry.materials = [greenMaterial]

        return geometry
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
            lineData.append(lineCount)
            lineData.append(lineCount+3)
            lineData.append(lineCount)
            lineData.append(lineCount+2)
            lineCount = lineCount + 4
        }
        
        let lineEle = SCNGeometryElement(indices: lineData, primitiveType: .Line)
        let lineGeo = SCNGeometry(sources: [vertexSource], elements: [lineEle])
        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor.blackColor()
        lineGeo.materials = [whiteMaterial]

        return SCNNode(geometry: lineGeo)
    }
    
    private func boundElevation(elevation:Int) -> Int {
        var boundedElevation:Int = elevation
        
        if (elevation < Elevation.MIN_BOUND) {
            boundedElevation = Elevation.MIN_BOUND
        } else if (elevation > Elevation.MAX_BOUND) {
            boundedElevation = Elevation.MAX_BOUND
        }
        
        return boundedElevation
    }
    
}