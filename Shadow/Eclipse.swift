//
//  Eclipse.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/23/25.
//

import Foundation
import MapKit

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
let equatorialRadiusx = UnitLength(symbol: "ER", converter: UnitConverterLinear(coefficient: 6378137))
