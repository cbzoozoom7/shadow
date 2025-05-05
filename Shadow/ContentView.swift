//
//  ContentView.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/20/25.
//

import SwiftUI
import MapKit
enum loadingState {
    case loading
    case ready
}
struct ContentView: View {
    @State var selectedEclipse: Eclipse? = nil
    @State var eclipsePickerShown: Bool = true
    @StateObject var eclipses = EclipseModel()
    var body: some View {
        Map()
            .mapStyle(.hybrid)
    }
}

#Preview {
    ContentView()
}
