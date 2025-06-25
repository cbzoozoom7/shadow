//
//  Ephemerides.swift
//  Shadow
//
//  Created by Christopher Bowman on 6/24/25.
//
import Foundation
class Ephemerides { // Singleton
	private init () {}
	static let shared = Ephemerides()
	
	private var moonRange: [Date: Double] = [:]
	/// Gets the cached distance to the moon at the specified time, if available. If not, it will make a web request to accquire this data in bulk.
	/// - Parameters:
	/// 	- date: The date for which to get the data.
	/// 	- eclipse: The Eclipse that this lookup is for. The t0, tMin, and tMax values are used in case of a web request.
	func getMoonRange(for date: Date, eclipse: Eclipse) async -> Double {
		var range: Double? = nil
		let roundedDate = date.roundedToNearest15Minutes
		range = moonRange[roundedDate]
		if range == nil {
			let horizons = NasaHorizons()
			await moonRange.merge(horizons.getMoonRange(t0: eclipse.t0, tMin: eclipse.tMin, tMax: eclipse.tMax))
				{(_, new) in new}
			range = moonRange[roundedDate]
		}
		return range!
	}
}
extension Date {
	var roundedToNearest15Minutes: Date {
		let cal = Calendar.current
		var components = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
		let minute = components.minute ?? 0
		let second = components.second ?? 0
		components.second = 0
		if (minute < 7) || ((minute == 7) && (second < 30)) {
			components.minute = 0
		} else if (minute < 22) || ((minute == 22) && (second < 30)) {
			components.minute = 15
		} else if (minute < 37) || ((minute == 37) && (second < 30)) {
			components.minute = 30
		} else if (minute < 52) || ((minute == 52) && (second < 30)) {
			components.minute = 45
		} else {
			components.minute = 60 // Overflow is handled when converted back to a Date
		}
		return cal.date(from: components)!
	}
}
