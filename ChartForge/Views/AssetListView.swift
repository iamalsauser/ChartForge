import SwiftUI

struct AssetListView: View {
    @StateObject private var viewModel = AssetListViewModel()
    @EnvironmentObject var watchlistVM: WatchlistViewModel
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @State private var selectedAsset: CryptoAsset?
    @State private var showTradeForm = false
    @State private var tradeAsset: CryptoAsset?
    @State private var previousPrices: [String: Double] = [:]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top assets horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topAssets, id: \.symbol) { asset in
                            TopAssetCardView(asset: asset, isSelected: selectedAsset?.symbol == asset.symbol, onSelect: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedAsset = asset
                            })
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                List {
                    Section(header: Text("All Crypto Assets").font(.headline)) {
                        if viewModel.assets.isEmpty {
                            ForEach(0..<5) { _ in
                                SkeletonLoaderView()
                                    .listRowBackground(Color(.systemGroupedBackground))
                            }
                        } else {
                            ForEach(sortedAssets) { asset in
                                AssetRowView(
                                    asset: asset,
                                    isSelected: selectedAsset?.symbol == asset.symbol,
                                    priceColor: priceColor(for: asset),
                                    icon: assetIcon(for: asset.symbol),
                                    isFavorited: watchlistVM.isFavorited(symbol: asset.symbol),
                                    onSelect: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedAsset = asset
                                    },
                                    onTrade: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        tradeAsset = asset
                                        showTradeForm = true
                                    },
                                    onToggleFavorite: {
                                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                        watchlistVM.toggle(symbol: asset.symbol)
                                    }
                                )
                                .listRowBackground(Color(.systemBackground))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Crypto Market")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        tradeAsset = nil
                        showTradeForm = true
                    }) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Trade")
                    }
                }
            }
            .sheet(isPresented: $showTradeForm) {
                if let asset = tradeAsset {
                    TradeFormView(asset: asset)
                } else {
                    TradeLauncherView()
                        .environmentObject(portfolioVM)
                        .environmentObject(watchlistVM)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedAsset != nil },
                set: { if !$0 { selectedAsset = nil } }
            )) {
                if let asset = selectedAsset {
                    AssetDetailView(viewModel: AssetDetailViewModel(asset: asset))
                }
            }
            .onChange(of: viewModel.assets) { newAssets, _ in
                for asset in newAssets {
                    previousPrices[asset.symbol] = asset.price
                }
            }
        }
    }
    
    private func priceColor(for asset: CryptoAsset) -> Color {
        if let previous = previousPrices[asset.symbol] {
            if asset.price > previous { return .green }
            if asset.price < previous { return .red }
        }
        return .primary
    }
    
    private func assetIcon(for symbol: String) -> Image {
        switch symbol.uppercased() {
        case "BTCUSDT": return Image(systemName: "bitcoinsign.circle.fill")
        case "ETHUSDT": return Image(systemName: "e.circle.fill")
        case "SOLUSDT": return Image(systemName: "s.circle.fill")
        case "ADAUSDT": return Image(systemName: "a.circle.fill")
        case "XRPUSDT": return Image(systemName: "x.circle.fill")
        case "DOGEUSDT": return Image(systemName: "d.circle.fill")
        case "BNBUSDT": return Image(systemName: "b.circle.fill")
        case "AVAXUSDT": return Image(systemName: "a.circle.fill")
        case "MATICUSDT": return Image(systemName: "m.circle.fill")
        case "DOTUSDT": return Image(systemName: "d.circle.fill")
        default: return Image(systemName: "questionmark.circle")
        }
    }
    
    // Helper: Sorted assets by market cap rank
    private var topAssetSymbols: [String] {
        ["BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT", "XRPUSDT", "ADAUSDT", "DOGEUSDT", "MATICUSDT", "DOTUSDT", "AVAXUSDT"]
    }
    private var topAssets: [CryptoAsset] {
        topAssetSymbols.compactMap { symbol in
            viewModel.assets.first(where: { $0.symbol == symbol })
        }
    }
    private var sortedAssets: [CryptoAsset] {
        viewModel.assets.sorted { a, b in
            (topAssetSymbols.firstIndex(of: a.symbol) ?? 99) < (topAssetSymbols.firstIndex(of: b.symbol) ?? 99)
        }
    }
}

private struct AssetRowView: View {
    let asset: CryptoAsset
    let isSelected: Bool
    let priceColor: Color
    let icon: Image
    let isFavorited: Bool
    let onSelect: () -> Void
    let onTrade: () -> Void
    let onToggleFavorite: () -> Void
    @State private var lastPrice: Double = 0
    @State private var priceDirection: Int = 0 // -1: down, 0: same, 1: up
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Button(action: {
                    onToggleFavorite()
                }) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .foregroundColor(isFavorited ? .yellow : .gray.opacity(0.5))
                        .accessibilityLabel(isFavorited ? "Remove from watchlist" : "Add to watchlist")
                }
                .buttonStyle(.plain)
                .padding(.trailing, 2)
                icon
                    .resizable()
                    .frame(width: 24, height: 24)
                    .cornerRadius(6)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.symbol)
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel(asset.symbol)
                    Text(asset.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(asset.name)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Text("$\(asset.price, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(priceColor)
                            .accessibilityLabel("Price: $\(asset.price, specifier: "%.2f")")
                        if priceDirection != 0 {
                            Image(systemName: priceDirection == 1 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2.bold())
                                .foregroundColor(priceDirection == 1 ? .green : .red)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: priceDirection)
                        }
                    }
                    Text(asset.lastUpdated, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .accessibilityLabel("Last updated: \(asset.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(
                isSelected ? Color.blue.opacity(0.08) : Color.clear
            )
        }
        .buttonStyle(.plain)
#if os(iOS)
        .swipeActions(edge: .trailing) {
            Button {
                onTrade()
            } label: {
                Label("Trade", systemImage: "arrow.left.arrow.right")
            }
            .tint(.blue)
        }
#endif
        .onAppear { lastPrice = asset.price }
        .onChange(of: asset.price) { newPrice in
            if newPrice > lastPrice {
                priceDirection = 1
            } else if newPrice < lastPrice {
                priceDirection = -1
            } else {
                priceDirection = 0
            }
            lastPrice = newPrice
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                priceDirection = 0
            }
        }
    }
}

private struct TopAssetCardView: View {
    let asset: CryptoAsset
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var lastPrice: Double = 0
    @State private var priceDirection: Int = 0 // -1: down, 0: same, 1: up
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.accentColor)
                Text(asset.symbol.replacingOccurrences(of: "USDT", with: ""))
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 3) {
                    Text("$\(asset.price, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if priceDirection != 0 {
                        Image(systemName: priceDirection == 1 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2.bold())
                            .foregroundColor(priceDirection == 1 ? .green : .red)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: priceDirection)
                    }
                }
            }
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .onAppear { lastPrice = asset.price }
        .onChange(of: asset.price) { newPrice in
            if newPrice > lastPrice {
                priceDirection = 1
            } else if newPrice < lastPrice {
                priceDirection = -1
            } else {
                priceDirection = 0
            }
            lastPrice = newPrice
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                priceDirection = 0
            }
        }
    }
}

struct AssetListView_Previews: PreviewProvider {
    static var previews: some View {
        AssetListView()
    }
}
