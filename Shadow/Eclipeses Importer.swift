//
//  Eclipeses Importer.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/28/25.
//

import Foundation
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
        let nonNegativeDecimalPattern = Regex {
            ZeroOrMore(.digit)
            Optionally(".")
            ZeroOrMore(.digit)
        }
        let decimalPattern = Regex {
            Optionally("-")
            nonNegativeDecimalPattern
        }
        let csvPattern = Regex {
            Anchor.startOfLine
            Capture { // Year
                OneOrMore(.digit)
            }
            ","
            Capture { // Month
                OneOrMore(.digit)
            }
            ","
            Capture { // Day
                OneOrMore(.digit)
            }
            ",\""
            Capture { // Dynamical Time of Greatest Eclipse
                OneOrMore(.digit)
                ":"
                OneOrMore(.digit)
                ":"
                OneOrMore(.digit)
            }
            "\","
            Capture { // Delta T
                decimalPattern
            }
            ","
            Capture { // Luna
                OneOrMore(.digit)
            }
            ","
            Capture { // Saros
                OneOrMore(.digit)
            }
            ",\""
            Capture { // Eclipse Type
                ChoiceOf {
                    "P"
                    "A"
                    "T"
                    "H"
                }
                ChoiceOf {
                    "m"
                    "n"
                    "s"
                    "+"
                    "-"
                    "2"
                    "3"
                    "b"
                    "e"
                }
            }
            "\","
            Capture { // Gamma
                Optionally("-")
                ZeroOrMore(.digit)
                Optionally(".")
                ZeroOrMore(.digit)
            }
            ","
            Capture { // Magnitude
                ZeroOrMore(.digit)
                Optionally(".")
                ZeroOrMore(.digit)
            }
            ",\"" // Latitude
            ZeroOrMore(.digit)
            Optionally(".")
            ZeroOrMore(.digit)
            ChoiceOf {
                "N"
                "S"
            }
            "\",\"" // Longitude
            ZeroOrMore(.digit)
            Optionally(".")
            ZeroOrMore(.digit)
            ChoiceOf {
                "E"
                "W"
            }
            "\","
            Capture { // Decimal latitude
                Optionally("-")
                ZeroOrMore(.digit)
                Optionally(".")
                ZeroOrMore(.digit)
            }
            ","
            Capture { // Decimal longitude
                Optionally("-")
                ZeroOrMore(.digit)
                Optionally(".")
                ZeroOrMore(.digit)
            }
            ","
            Capture { // Sun altitude
                ZeroOrMore(.digit)
                Optionally(".")
                ZeroOrMore(.digit)
            }
            ","
            Capture { // Sun azimuth
                ZeroOrMore(.digit)
                Optionally(".")
                ZeroOrMore(.digit)
            }
            ","
            Capture { // Path width (km)
                ZeroOrMore(.digit)
                Optionally(".")
                ZeroOrMore(.digit)
            }
            ",\"" // Duration
            Repeat(.digit, count: 2)
            "m"
            Repeat(.digit, count: 2)
            "s\","
            Capture { // Decimal duration
                nonNegativeDecimalPattern
            }
            ","
            Capture { // Catalog number
                nonNegativeDecimalPattern
            }
            ","
            Capture { // Canon Plate number
                nonNegativeDecimalPattern
            }
            ","
            decimalPattern // Julian date
            ","
            Capture { // t0
                nonNegativeDecimalPattern
            }
            ","
            Capture { // x[0]
                decimalPattern
            }
            ","
            Capture { // x[1]
                decimalPattern
            }
            ","
            Capture { // x[2]
                decimalPattern
            }
            ","
            Capture { // x[3]
                decimalPattern
            }
            ","
            Capture { // y[0]
                decimalPattern
            }
            ","
            Capture { // y[1]
                decimalPattern
            }
            ","
            Capture { // y[2]
                decimalPattern
            }
            ","
            Capture { // y[3]
                decimalPattern
            }
            ","
            Capture { // d[0]
                decimalPattern
            }
            ","
            Capture { // d[1]
                decimalPattern
            }
            ","
            Capture { // d[2]
                decimalPattern
            }
            ","
            Capture { // µ[0]
                decimalPattern
            }
            ","
            Capture { // µ[1]
                decimalPattern
            }
            ","
            Capture { // µ[2]
                decimalPattern
            }
            ","
            Capture { // L1[0]
                nonNegativeDecimalPattern
            }
            ","
            Capture { // L1[1]
                nonNegativeDecimalPattern
            }
            ","
            Capture { // L1[2]
                nonNegativeDecimalPattern
            }
            ","
            Capture { // L2[0]
                nonNegativeDecimalPattern
            }
            ","
            Capture { // L2[1]
                nonNegativeDecimalPattern
            }
            ","
            Capture { // L2[2]
                nonNegativeDecimalPattern
            }
            ","
            Capture { // tan(f1)
                decimalPattern
            }
            ","
            Capture { // tan(f2)
                decimalPattern
            }
        }
        if let match = line.firstMatch(of: csvPattern) {
            let (year, month) = match.output
        }
    }
    return []
}
