//
//  ChartForgeApp.swift
//  ChartForge
//
//  Created by Parth Sinh on 18/07/25.
//

import SwiftUI

@main
struct ChartForgeApp: App {
    @StateObject private var watchlistVM = WatchlistViewModel()
    @StateObject private var portfolioVM = PortfolioViewModel()
    @StateObject private var assetListVM = AssetListViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                AssetListView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Market")
                    }
                WatchlistView()
                    .tabItem {
                        Image(systemName: "star.fill")
                        Text("Watchlist")
                    }
                PortfolioView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Portfolio")
                    }
            }
            .environmentObject(watchlistVM)
            .environmentObject(portfolioVM)
            .environmentObject(assetListVM)
        }
    }
}
