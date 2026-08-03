//
//  ContentView.swift
//  XcodeClean Pro
//
//  Created by Malva on 03/08/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .environmentObject(XcodeScanner())
        .environmentObject(XcodeCleaner())
        .environmentObject(SchedulerManager())
}
