//
//  Eclipse.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/23/25.
//

import Foundation
import MapKit
import SwiftData
import OSLog

enum HybridType {
    case startEndAnnular
    case startTotal
    case endTotal
}
enum EclipseType {
    case total
    case partial
    case annular
    case hybrid(HybridType)
}
struct Ray3D {
    let azimuth: Double
    let altitude: Double?
}
// Below, axis means the shadow cone axis
// https://eclipse.gsfc.nasa.gov/SEcat5/SEcatkey.html
struct Eclipse: Identifiable {
    let time: Date // TD + ∆t
    let luna: Int
    let saros: Int
    let type: EclipseType
    let gamma: Double // Distance from axis to center of Earth
    let magnitude: Double
    let location: CLLocationCoordinate2D
    let sunPosition: Ray3D
    let pathWidth: Double? // Kilometers
    let duration: TimeInterval?
    let id: Int
    var eclipseCanonPlateNumber: Int { // Can be used to generate a URL to retrive a diagram of the eclipse from NASA
        return ((id - 1) / 20) + 1
    }
    let t0: Double
    let xCoefficients: [Double]
    let yCoefficients: [Double]
    let axisDeclinationCoefficients: [Double] // d
    let axisHourAngleCoefficients: [Double] // µ
    let penumbralRadiusCoefficients: [Double] // L1
    let umbralRadiusCoefficients: [Double] // L2
            // f1 & f2 are measured with respect to lunar shadow
    let tanPenumbralAxisAngle: Double // tan(f1)
    let tanUmbralAxisAngle: Double // tan(f2)
}
class EclipseModel: ObservableObject {
    @Published var eclipses: [Int:Eclipse]
    @Published var loading: Bool
    init() {
        eclipses = [:]
        loading = true
        let _ = Task {
            do {
                try await self.load()
            } catch {
                
            }
            loading = false
        }
    }
    func load() async throws {
        let logger = Logger()
//        guard let filepath = Bundle.main.path(forResource: "test-eclipse", ofType: "csv") else {
//            return
//        }
//        let content = try String(contentsOfFile: filepath, encoding: .ascii)
        
        guard let nsData = NSDataAsset(name: "test-eclipse") else {
            return
        }
        guard let content = String(data: nsData.data, encoding: .ascii) else {
            return
        }
        
        var lines = content.components(separatedBy: "\n")
        logger.notice("lines: \(lines.count)")
        assert(lines.count > 0)
        
        lines.removeFirst() // Discard header row
        for line in lines {
            guard !line.isEmpty else { continue }
            let tokens = line.components(separatedBy: ",")
            logger.notice("tokens.count: \(tokens.count)")
            for var token in tokens {
                if let quotedSection = token.firstMatch(of: /"(.*)"/) {
                    token = String(quotedSection.1)
                }
            }
            logger.notice("tokens.count: \(tokens.count)")
            assert(tokens.count > 40)
            
            var time = {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy MM dd HH:mm:ss z"
                let dateString = "\(tokens[0]) \(tokens[1]) \(tokens[2]) \(tokens[3]) UTC"
                logger.notice("dateString: \(dateString)")
                let date = dateFormatter.date(from: "\(tokens[0]) \(tokens[1]) \(tokens[2]) \(tokens[3]) UTC") ?? Date()
                logger.notice("time: \(date)")
                return date
            }()
            
            if let deltaT = Double(tokens[4]) {
                logger.notice("tokens[4]: \(tokens[4])\t-> deltaT: \(deltaT)")
                time.addTimeInterval(deltaT)
                logger.notice("time: \(time)")
            } else {
                logger.notice("tokens[4]: \(tokens[4])\tfailed to parse as Double")
            }
            
            let luna = Int(tokens[5]) ?? 0
            logger.notice("tokens[5]: \(tokens[5])\t-> luna: \(luna)")
            
            let saros = Int(tokens[6])!
            logger.notice("tokens[6]: \(tokens[6])\t-> saros: \(saros)")
            
            let type: EclipseType = {
                switch tokens[7].first {
                case "P":
                    return .partial
                case "A":
                    return .annular
                case "T":
                    return .total
                case "H":
                    let hybridType: HybridType
                    let index = tokens[7].index(tokens[7].startIndex, offsetBy: 1)
                    
                    switch tokens[7][index] {
                    case "2":
                        hybridType = .startTotal
                    case "3":
                        hybridType = .endTotal
                    default:
                        hybridType = .startEndAnnular
                    }
                    return .hybrid(hybridType)
                default:
                    logger.error("Failed to parse eclipse type")
                    return .partial
                }
            }()
            logger.notice("tokens[7]: \(tokens[7])\t-> type: \(String(describing: (type)))")
            
            let gamma = Double(tokens[8]) ?? 0
            logger.notice("tokens[8]: \(tokens[8])\t-> gamma: \(gamma)")
            
            let magnitude = Double(tokens[9]) ?? 0
            logger.notice("tokens[9]: \(tokens[9])\t-> magnitude: \(magnitude)")
            // tokens[10] is latitude
            // tokens[11] is longitude
            let latitude = Double(tokens[12])! // tokens[12] is in decimal format unlike 10
            logger.notice("tokens[12]: \(tokens[12])\t-> latitude: \(latitude)")
            
            let longitude = Double(tokens[13])!
            logger.notice("tokens[13]: \(tokens[13])\t-> longitude: \(longitude)")
            
            let sunAltitude: Double?
            if case .partial = type {
                sunAltitude = nil
            } else {
                sunAltitude = Double(tokens[14]) ?? 0
            }
            logger.notice("tokens[14]: \(tokens[14])\t-> sunAltitude: \(String(describing: sunAltitude))")
            
            let sunAzimuth = Double(tokens[15]) ?? 0
            logger.notice("tokens[15]: \(tokens[15])\t-> sunAzimuth: \(sunAzimuth)")
            
            let pathWidth: Double?
            let duration: Double?
            if case .partial = type {
                pathWidth = nil
                duration = nil
            } else {
                pathWidth = Double(tokens[16]) ?? 0
                // tokens[17] is duration
                duration = Double(tokens[18]) ?? 0 // tokens[18] is in decimal format
            }
            logger.notice("tokens[16]: \(tokens[16])\t-> pathWidth: \(String(describing: pathWidth))")
            logger.notice("tokens[18]: \(tokens[18])\t-> duration: \(String(describing: duration))")
            
            let catalogNumber = Int(tokens[19]) ?? 0
            logger.notice("tokens[19]: \(tokens[19])\t-> catalogNumber: \(catalogNumber)")
            // tokens[20] is canon plate number
            // tokens[21] is Julian date
            let t0 = Double(tokens[22]) ?? 0
            logger.notice("tokens[22]: \(tokens[22])\t-> t0: \(t0)")
            
            var x: [Double] = []
            for token in tokens[23...26] {
                x.append(Double(token) ?? 0)
            }
            logger.notice("tokens[23..26]: \(tokens[23...26])\t-> x: \(x)")
            
            var y: [Double] = []
            for token in tokens[27...30] {
                y.append(Double(token) ?? 0)
            }
            logger.notice("tokens[27..30]: \(tokens[27...30])\t-> y: \(y)")
            
            var declination: [Double] = []
            for token in tokens[31...33] {
                declination.append(Double(token) ?? 0)
            }
            logger.notice("tokens[31..33]: \(tokens[31...33])\t-> declination: \(declination)")
            
            var mu: [Double] = []
            for token in tokens[34...36] {
                mu.append(Double(token) ?? 0)
            }
            logger.notice("tokens[34..36]: \(tokens[34...36])\t-> mu: \(mu)")
            
            var l1: [Double] = []
            for token in tokens[37...39] {
                l1.append(Double(token) ?? 0)
            }
            logger.notice("tokens[37..39]: \(tokens[37...39])\t-> l1: \(l1)")
            
            var l2: [Double] = []
            for token in tokens[40...42] {
                l2.append(Double(token) ?? 0)
            }
            logger.notice("tokens[40..42]: \(tokens[40...42])\t-> l2: \(l2)")
            
            let tanF1 = Double(tokens[43]) ?? 0
            logger.notice("tokens[43]: \(tokens[43])\t-> tanF1: \(tanF1)")
            
            let tanF2 = Double(tokens[44]) ?? 0
            logger.notice("tokens[44]: \(tokens[44])\t-> tanF2: \(tanF2)")
            
            let newEclipse = Eclipse(
                time: time,
                luna: luna,
                saros: saros,
                type: type,
                gamma: gamma,
                magnitude: magnitude,
                location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                sunPosition: Ray3D(azimuth: sunAzimuth, altitude: sunAltitude),
                pathWidth: pathWidth,
                duration: duration,
                id: catalogNumber,
                t0: t0,
                xCoefficients: x,
                yCoefficients: y,
                axisDeclinationCoefficients: declination,
                axisHourAngleCoefficients: mu,
                penumbralRadiusCoefficients: l1,
                umbralRadiusCoefficients: l2,
                tanPenumbralAxisAngle: tanF1,
                tanUmbralAxisAngle: tanF2
                )
            eclipses[catalogNumber] = newEclipse
        }
    }
}
let equatorialRadiusx = UnitLength(symbol: "ER", converter: UnitConverterLinear(coefficient: 6378137))
