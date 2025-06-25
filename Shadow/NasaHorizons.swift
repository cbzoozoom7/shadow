//
//  NasaHorizons.swift
//  Shadow
//
//  Created by Christopher Bowman on 6/11/25.
//

import Foundation
import OSLog
// https://ssd-api.jpl.nasa.gov/doc/horizons.html
struct NasaHorizons {
	func getMoonRange(t0: Date, tMin: TimeInterval, tMax: TimeInterval) async -> [Date:Double] {
		var moonRange: [Date:Double] = [:]
		let startTime = t0.addingTimeInterval(tMin)
		let endTime = t0.addingTimeInterval(tMax)
		var fmatter = DateFormatter()
		fmatter.locale = Locale(identifier: "en_US_POSIX")
		fmatter.dateFormat = "YYYY-MMM-d HH:mm:ss"
		var componentsUrl = URLComponents(string: "https://ssd.jpl.nasa.gov/api/horizons.api")!
		componentsUrl.queryItems = [
			URLQueryItem(name: "format", value: "json"),
			URLQueryItem(name: "COMMAND", value: "'301'"), // The moon
			URLQueryItem(name: "OBJ_DATA", value: "'NO'"),
			URLQueryItem(name: "EPHEM_TYPE", value: "'VECTORS'"),
			URLQueryItem(name: "EMAIL_ADDR", value: "cb@christopherbowman.link"),
			URLQueryItem(name: "START_TIME", value: "'" + fmatter.string(from: startTime) + "'"),
			URLQueryItem(name: "STOP_TIME", value: "'" + fmatter.string(from: endTime) + "'"),
			URLQueryItem(name: "STEP_SIZE", value: "'15 min'"),
			URLQueryItem(name: "CENTER", value: "'500@0'"), // The center of the Earth
		]
		guard let finalUrl = componentsUrl.url else {
			fatalError("Could not construct URL")
		}
		let logger = Logger()
		let task = URLSession.shared.dataTask(with: finalUrl) { data, _, _ in
			logger.info("Data: \(data!)")
			// TODO
			
		}
		return moonRange
	}

}
