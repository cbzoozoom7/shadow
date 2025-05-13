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
                    Marker("", coordinate: eclipses.selectedEclipse.location)
                }
                    .mapStyle(.hybrid)
                    .edgesIgnoringSafeArea(.top)
                // TODO: Blur status bar
            }
            .onAppear {
                let mapRegion = MKCoordinateRegion(center: eclipses.selectedEclipse.location, span: .init(latitudeDelta: 15, longitudeDelta: 15))
                camera = .region(mapRegion)
            }
        }
        
    }
}

#Preview {
    ContentView()
}
