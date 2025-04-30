//
//  Eclipeses Importer.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/28/25.
//

import Foundation
import MapKit
import RegexBuilder
func EclipesesImporter() async throws -> [Eclipse] {
    guard let filepath = Bundle.main.path(forResource: "filtered-eclipses", ofType: "csv") else {
        throw NSError(domain: "", code: 0, userInfo: nil)
    }
    let content = try String(contentsOfFile: filepath, encoding: .ascii)
    var lines = content.components(separatedBy: "\n")
    lines.removeFirst() // Discard header row
    var eclipeses: [Eclipse] = []
    for line in lines {
        var tokens = line.components(separatedBy: ",")
        for var token in tokens {
            if let quotedSection = token.firstMatch(of: /"(.*)"/) {
                token = String(quotedSection.1)
            }
        }
        var time = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy MM dd HH:mm:ss z"
            return dateFormatter.date(from: "\(tokens[0]) \(tokens[1]) \(tokens[2]) \(tokens[3]) UTC")!
        }()
        if let deltaT = Double(tokens[4]) {
            time.addTimeInterval(deltaT)
        }
        let luna = Int(tokens[5])!
        let saros = Int(tokens[6])!
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
                fatalError()
            }
        }()
        let gamma = Double(tokens[8])!
        let magnitude = Double(tokens[9])!
        // tokens[10] is latitude
        // tokens[11] is longitude
        let latitude = Double(tokens[12])! // tokens[12] is in decimal format unlike 10
        let longitude = Double(tokens[13])!
        let sunAltitude: Double?
        if case .partial = type {
            sunAltitude = nil
        } else {
            sunAltitude = Double(tokens[14])!
        }
        let sunAzimuth = Double(tokens[15])!
        let pathWidth: Double?
        let duration: Double?
        if case .partial = type {
            pathWidth = nil
            duration = nil
        } else {
            pathWidth = Double(tokens[16])!
            // tokens[17] is duration
            duration = Double(tokens[18])! // tokens[18] is in decimal format
        }
        let catalogNumber = Int(tokens[19])!
        // tokens[20] is canon plate number
        // tokens[21] is Julian date
        let t0 = Double(tokens[22])!
        let x = [Double(tokens[23])!, Double(tokens[24])!, Double(tokens[25])!, Double(tokens[26])!]
        let y = [Double(tokens[27])!, Double(tokens[28])!, Double(tokens[29])!, Double(tokens[30])!]
        let declination = [Double(tokens[31])!, Double(tokens[32])!, Double(tokens[33])!]
        let mu = [Double(tokens[34])!, Double(tokens[35])!, Double(tokens[36])!]
        let l1 = [Double(tokens[37])!, Double(tokens[38])!, Double(tokens[39])!]
        let l2 = [Double(tokens[40])!, Double(tokens[41])!, Double(tokens[42])!]
        let tanF1 = Double(tokens[43])!
        let tanF2 = Double(tokens[44])!
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
        eclipeses.append(newEclipse)
    }
    return []
}
