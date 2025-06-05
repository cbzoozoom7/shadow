//
//  ContentView.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/20/25.
//

import SwiftUI
import MapKit
enum ViewType {
    case total
    case annular
    case partial
    case none
}
struct CalcPoint: Identifiable {
    var id: ObjectIdentifier
    let location: CLLocationCoordinate2D
    let view: ViewType
}
struct ContentView: View {
    @StateObject var eclipses = EclipseModel()
    @State var camera: MapCameraPosition = .automatic // Placeholder value
    @State var mapPoints: [CalcPoint] = []
    var mapRegion: MapRegion = MapRegion()
	let calcQueue = DispatchQueue(label: "page.clist.shadow.calcQueue", attributes: .concurrent)
    var body: some View {
        if !eclipses.loaded {
            ProgressView()
                .task {
                    do {
                        try await eclipses.load()
                    } catch {
                        // fail silently. Show loading spinner forever
                    }
                }
        } else {
            ZStack {
                Map(position: $camera, bounds: nil, interactionModes: .all) {
                    ForEach(mapPoints) { point in
                        Annotation("", coordinate: point.location) {
                            let myMapCircle = Circle().opacity(0.5)
                            switch point.view {
                            case .total:
                                myMapCircle.foregroundStyle(.black)
                            case .partial:
                                myMapCircle.foregroundStyle(.yellow)
                            case .annular:
                                myMapCircle.foregroundStyle(.orange)
                            case .none:
                                myMapCircle.foregroundStyle(.white)
                            }
                        }
                    }
                    Annotation("", coordinate: eclipses.selectedEclipse.location) {
                        Circle()
                    }
                }
                .mapStyle(.hybrid)
                .onChange(of: camera) {
					mapRegion.region = camera.region
					calcQueue.async {
						eclipses.calculateEclipse(for: mapRegion.region)
					}
                }
                // TODO: Blur under status bar
            }
            .onAppear {
                let eclipseRegion = MKCoordinateRegion(center: eclipses.selectedEclipse.location,
													   span: .init(latitudeDelta: 15,
																   longitudeDelta: 15))
                camera = .region(eclipseRegion)
                mapRegion.region = eclipseRegion
            }
        }
    }
}

#Preview {
    ContentView()
}
