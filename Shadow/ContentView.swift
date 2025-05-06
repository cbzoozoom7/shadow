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
    @StateObject var eclipses = EclipseModel()
    var body: some View {
        ZStack {
            Map()
                .mapStyle(.hybrid)
                .disabled(eclipses.loading)
            Color.gray
                .ignoresSafeArea()
                .opacity(eclipses.loading ? 0.8 : 0)
                .disabled(!eclipses.loading)
            ProgressView()
                .disabled(!eclipses.loading)
                .opacity(eclipses.loading ? 1 : 0)
            Text(String(describing: eclipses.eclipses))
                .background()
        }
    }
}

#Preview {
    ContentView()
}
