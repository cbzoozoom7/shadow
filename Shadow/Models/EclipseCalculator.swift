//
//  EclipseCalculator.swift
//  Shadow
//
//  Created by Christopher Bowman on 7/1/25.
//
import Foundation
import MapKit
import _MapKit_SwiftUI
struct EclipseCalculator {
	let eclipseCanon: EclipseCanon
	init(eclipseCanon: EclipseCanon) {
		self.eclipseCanon = eclipseCanon
	}
	func splitAndCalculate(region: MKCoordinateRegion?, visibleArea: MapRegion, eclipse: Eclipse) async -> AsyncStream<CalcPoint> {
		AsyncStream { continuation in
			// Do nothing if they're null
			guard let region = region else { return }
			guard let screen = visibleArea.region else { return }
			// Call the actual function
			Task {
				await self.splitAndCalculate(region: region, screen: screen, eclipse: eclipse, continuation: continuation)
			}
		}
	}
	private func splitAndCalculate(region: MKCoordinateRegion, screen: MKCoordinateRegion, eclipse: Eclipse, continuation: AsyncStream<CalcPoint>.Continuation) async {
		// Do nothing if the center of region is off-screen
		guard abs(region.center.latitude - screen.center.latitude) < screen.span.latitudeDelta / 2 else { return }
		guard abs(region.center.longitude - screen.center.longitude) < screen.span.longitudeDelta / 2 else { return }
		// Split the region in half and queue up a recersion over each
		let halves = region.halve()
		halves.forEach { half in
			Task.detached {
				await self.splitAndCalculate(region: half, screen: screen, eclipse: eclipse, continuation: continuation)
			}
		}
		Task.detached {
			await continuation.yield(self.calculate(observer: region.center, eclipse: eclipse))
		}
	}
	func calculate(observer: CLLocationCoordinate2D, eclipse: Eclipse) async -> CalcPoint {
		// Actual eclipse math
		let ephems = Ephemerides.shared
		async let moonRange = ephems.getMoonRange(for: self.eclipseCanon.selectedEclipse.time, eclipse: self.eclipseCanon.selectedEclipse)
		let equatorialRadius = UnitLength(symbol: "ER", converter: UnitConverterLinear(coefficient: 6378137))
		let e2 = 0.0066943799901413 // The square of the Earth's eccentricity
		let elements = self.eclipseCanon.eclipses[self.eclipseCanon.selection].greatestEclipseElements
		// The following 2 constants are the legs of a right triangle
		let geocentricDistanceEquatorialPlane = cos(observer.latitude) / sqrt(1 - e2 * pow(sin(observer.latitude), 2)) // ρcosϕ' Observer's distance from the center of the Earth in the equatorial plane
		let geocentricDistancePerpendicular = (sin(observer.latitude) * (1 - e2)) / sqrt(1 - e2 * pow(sin(observer.latitude), 2)) // ρsinϕ′ Observer's distance from the center of the Earth perpendicular to the equatorial plane
		let sinHorzontalParallax = await Measurement(value: 1.0, unit: equatorialRadius).value / moonRange.value
		let z = -(1.0 / sinHorzontalParallax)
		let fundamentalPlaneCoords = Point3D(x: geocentricDistanceEquatorialPlane * sin(observer.longitude - elements.axisHourAngle), // ξ=ρcosϕ′sin(λ−μ)
											 y: geocentricDistancePerpendicular - z * cos(elements.axisDeclination) + geocentricDistanceEquatorialPlane * cos(observer.longitude - elements.axisHourAngle) * sin(elements.axisDeclination), // η=ρsinϕ′−zcosd+ρcosϕ′cos(λ−μ)sind
											 z: <#T##Double#>)
		
		
	}
}
