//
//  ContentView.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/20/25.
//

import SwiftUI
import MapKit
struct ContentView: View {
    @State var selectedEclipse: Eclipse? = nil
    @State var eclipsePickerShown: Bool = false
    // async let eclipses: [Eclipse]
    var body: some View {
        Map()
            .mapStyle(.hybrid)
            .sheet(isPresented: $eclipsePickerShown) {
                List {
                    
                }
            }
    }
}

#Preview {
    ContentView()
}
