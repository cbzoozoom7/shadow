//
//  ContentView.swift
//  Shadow
//
//  Created by Christopher Bowman on 4/20/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    var body: some View {
        Map()
            .mapStyle(.hybrid)
            .sheet(isPresented: true) {
                List
            }
    }
}

#Preview {
    ContentView()
}
