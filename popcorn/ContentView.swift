//
//  ContentView.swift
//  popcorn
//
//  Created by Enzo on 1/11/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewStore.container)
}
