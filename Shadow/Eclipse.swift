//
//  Eclipse.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/23/25.
//

import Foundation
import MapKit
import OSLog
import _MapKit_SwiftUI

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
struct BesselianCalculation {
	let time: Date // TD
	let axisDeclination: Double // d
	let axisHourAngle: Double // µ
	let penumbralRadius: Double // L1
	let umbralRadius: Double // L2
}
// https://eclipse.gsfc.nasa.gov/SEcat5/SEcatkey.html
struct Eclipse: Identifiable {
    let time: Date // TD
	let deltaT: TimeInterval
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
	lazy var greatestEclipseElements = {
		return BesselianCalculation(time: self.time,
									axisDeclination: polynomialCalculation(for: self.axisDeclinationCoefficients),
									axisHourAngle: polynomialCalculation(for: self.axisHourAngleCoefficients),
									penumbralRadius: polynomialCalculation(for: self.penumbralRadiusCoefficients),
									umbralRadius: polynomialCalculation(for: self.umbralRadiusCoefficients))
	}()
	private func polynomialCalculation(for coefficients: [Double]) -> Double {
		var out: Double = 0
		let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self.time)
		let t = {
			var t = Double(components.hour!)
			t += (Double(components.minute!) / 60.0)
			t += (Double(components.second!) / 60.0 / 60.0)
			t -= self.t0
			return t
		}()
		for i in 0 ..< coefficients.count {
			out += coefficients[i] * pow(t, Double(i))
		}
		return out
	}
}
struct Point3D {
	let x: Double
	let y: Double
	let z: Double
}
extension MKCoordinateRegion {
	func halve() -> [Self] { // Split region in half along its longest dimension
		let portrait = self.span.latitudeDelta > self.span.longitudeDelta
		
		let newDimension = portrait ? self.span.latitudeDelta / 2 : self.span.longitudeDelta / 2
		
		let latitudeDelta = portrait ? newDimension : self.span.latitudeDelta
		let longitudeDelta = portrait ? self.span.longitudeDelta : newDimension
		let halfSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
		
		let centerLatitude = self.center.latitude
		let centerLongitude = self.center.longitude
		
		let quarter = newDimension / 2
		
		let regionHalves: [MKCoordinateRegion]
		if portrait {
			let newLatitudes = [centerLatitude - quarter, centerLatitude + quarter]
			regionHalves = newLatitudes.map { lat in
				let center = CLLocationCoordinate2D(latitude: lat, longitude: centerLongitude)
				return MKCoordinateRegion(center: center, span: halfSpan)
			}
		} else {
			let newLongitudes = [centerLongitude - quarter, centerLongitude + quarter]
			regionHalves = newLongitudes.map { lon in
				let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: lon)
				return MKCoordinateRegion(center: center, span: halfSpan)
			}
		}
		return regionHalves
	}
}
class EclipseCanon: ObservableObject {
    @Published var eclipses: [Eclipse]
    @Published var loaded: Bool
    var selection: Int
    var selectedEclipse: Eclipse {
        return eclipses[selection]
    }
//    static func getMapRegion() -> MKCoordinateRegion {
//        return MKCoordinateRegion(center: self.selectedEclipse.location, span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
//    }
    @MainActor
    init() {
        eclipses = []
        loaded = false
        selection = 0
    }
    func load() async throws {
        let logger = Logger()
        var loadedEclipses: [Eclipse] = []
        guard let nsData = NSDataAsset(name: "test-eclipse") else {
            return
        }
        guard let content = String(data: nsData.data, encoding: .ascii) else {
            return
        }
        
        var lines = content.components(separatedBy: "\n")
        logger.debug("lines: \(lines.count)")
        assert(lines.count > 0)
        
        lines.removeFirst() // Discard header row
        for line in lines {
            guard !line.isEmpty else { continue }
            var tokens = line.components(separatedBy: ",")
            logger.debug("tokens.count: \(tokens.count)")
            for i in tokens.indices {
                if let quotedSection = tokens[i].firstMatch(of: /"(.*)"/) {
                    tokens[i] = String(quotedSection.1)
                }
            }
            assert(tokens.count >= 44)
            
            var time = {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy MM dd HH:mm:ss z"
                let dateString = "\(tokens[0]) \(tokens[1]) \(tokens[2]) \(tokens[3]) UTC"
                logger.debug("dateString: \(dateString)")
                let date = dateFormatter.date(from: "\(tokens[0]) \(tokens[1]) \(tokens[2]) \(tokens[3]) UTC") ?? Date()
                logger.debug("time: \(date)")
                return date
            }()
            
            let deltaT = Double(tokens[4]) ?? 0
			logger.debug("tokens[4]: \(tokens[4])\t-> deltaT: \(deltaT)")
            
            let luna = Int(tokens[5]) ?? 0
            logger.debug("tokens[5]: \(tokens[5])\t-> luna: \(luna)")
            
            let saros = Int(tokens[6])!
            logger.debug("tokens[6]: \(tokens[6])\t-> saros: \(saros)")
            
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
            logger.debug("tokens[7]: \(tokens[7])\t-> type: \(String(describing: (type)))")
            
            let gamma = Double(tokens[8]) ?? 0
            logger.debug("tokens[8]: \(tokens[8])\t-> gamma: \(gamma)")
            
            let magnitude = Double(tokens[9]) ?? 0
            logger.debug("tokens[9]: \(tokens[9])\t-> magnitude: \(magnitude)")
            // tokens[10] is latitude
            // tokens[11] is longitude
            let latitude = Double(tokens[12])! // tokens[12] is in decimal format unlike 10
            logger.debug("tokens[12]: \(tokens[12])\t-> latitude: \(latitude)")
            
            let longitude = Double(tokens[13])!
            logger.debug("tokens[13]: \(tokens[13])\t-> longitude: \(longitude)")
            
            let sunAltitude: Double?
            if case .partial = type {
                sunAltitude = nil
            } else {
                sunAltitude = Double(tokens[14]) ?? 0
            }
            logger.debug("tokens[14]: \(tokens[14])\t-> sunAltitude: \(String(describing: sunAltitude))")
            
            let sunAzimuth = Double(tokens[15]) ?? 0
            logger.debug("tokens[15]: \(tokens[15])\t-> sunAzimuth: \(sunAzimuth)")
            
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
            logger.debug("tokens[16]: \(tokens[16])\t-> pathWidth: \(String(describing: pathWidth))")
            logger.debug("tokens[18]: \(tokens[18])\t-> duration: \(String(describing: duration))")
            
            let catalogNumber = Int(Double(tokens[19]) ?? 0)
            logger.debug("tokens[19]: \(tokens[19])\t-> catalogNumber: \(catalogNumber)")
            // tokens[20] is canon plate number
            // tokens[21] is Julian date
            let t0 = Double(tokens[22]) ?? 0
            logger.debug("tokens[22]: \(tokens[22])\t-> t0: \(t0)")
            
            var x: [Double] = []
            for token in tokens[23...26] {
                x.append(Double(token) ?? 0)
            }
            logger.debug("tokens[23..26]: \(tokens[23...26])\t-> x: \(x)")
            
            var y: [Double] = []
            for token in tokens[27...30] {
                y.append(Double(token) ?? 0)
            }
            logger.debug("tokens[27..30]: \(tokens[27...30])\t-> y: \(y)")
            
            var declination: [Double] = []
            for token in tokens[31...33] {
                declination.append(Double(token) ?? 0)
            }
            logger.debug("tokens[31..33]: \(tokens[31...33])\t-> declination: \(declination)")
            
            var mu: [Double] = []
            for token in tokens[34...36] {
                mu.append(Double(token) ?? 0)
            }
            logger.debug("tokens[34..36]: \(tokens[34...36])\t-> mu: \(mu)")
            
            var l1: [Double] = []
            for token in tokens[37...39] {
                l1.append(Double(token) ?? 0)
            }
            logger.debug("tokens[37..39]: \(tokens[37...39])\t-> l1: \(l1)")
            
            var l2: [Double] = []
            for token in tokens[40...42] {
                l2.append(Double(token) ?? 0)
            }
            logger.debug("tokens[40..42]: \(tokens[40...42])\t-> l2: \(l2)")
            
            let tanF1 = Double(tokens[43]) ?? 0
            logger.debug("tokens[43]: \(tokens[43])\t-> tanF1: \(tanF1)")
            
            let tanF2 = Double(tokens[44]) ?? 0
            logger.debug("tokens[44]: \(tokens[44])\t-> tanF2: \(tanF2)")
            
            let newEclipse = Eclipse(
                time: time,
				deltaT: deltaT,
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
            loadedEclipses.append(newEclipse)
        }
        let newEclipses = loadedEclipses // Swift 6 mode thing
        await MainActor.run {
            eclipses = newEclipses
            loaded = true
        }
    }
	func calculateEclipse(for region: MKCoordinateRegion?, visibleArea: MapRegion, queue: DispatchQueue) {
		// Do nothing if they're null
		guard let region = region else { return }
		guard let screen = visibleArea.region else { return }
		// Do nothing if the center of region is off-screen
		guard abs(region.center.latitude - screen.center.latitude) < screen.span.latitudeDelta / 2 else { return }
		guard abs(region.center.longitude - screen.center.longitude) < screen.span.longitudeDelta / 2 else { return }
		// Split the region in half and queue up a recersion over each
		let halves = region.halve()
		halves.forEach { half in
			queue.async { self.calculateEclipse(for: half, visibleArea: visibleArea, queue: queue) }
		}
		// Actual eclipse math
		let observer = region.center
		let e2 = 0.0066943799901413 // The square of the Earth's eccentricity
		let elements = self.eclipses[selection].greatestEclipseElements
		// The following 2 constants are the legs of a right triangle
		let geocentricDistanceEquatorialPlane = cos(observer.latitude) / sqrt(1 - e2 * pow(sin(observer.latitude), 2)) // ρcosϕ' Observer's distance from the center of the Earth in the equatorial plane
		let geocentricDistancePerpendicular = (sin(observer.latitude) * (1 - e2)) / sqrt(1 - e2 * pow(sin(observer.latitude), 2)) // ρsinϕ′ Observer's distance from the center of the Earth perpendicular to the equatorial plane
		let fundamentalPlaneCoords = Point3D(x: geocentricDistanceEquatorialPlane * sin(observer.longitude - elements.axisHourAngle), // ξ=ρcosϕ′sin(λ−μ)
											 y: geocentricDistancePerpendicular - <#z#> * cos(elements.axisDeclination) + geocentricDistanceEquatorialPlane * cos(observer.longitude - elements.axisHourAngle) * sin(elements.axisDeclination), // η=ρsinϕ′−zcosd+ρcosϕ′cos(λ−μ)sind
											 z: <#T##Double#>)
		
		
	}
}

let equatorialRadius = UnitLength(symbol: "ER", converter: UnitConverterLinear(coefficient: 6378137))
