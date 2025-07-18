import SwiftUI

struct TradeLauncherView: View {
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var watchlistVM: WatchlistViewModel
    @EnvironmentObject var assetListVM: AssetListViewModel // <-- Use EnvironmentObject
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedAsset: CryptoAsset?
    @State private var showTradeForm = false
    @State private var showConfetti = false
    @State private var trendingOffset: CGFloat = 0
    @FocusState private var searchFocused: Bool
    
    var body: some View {
        ZStack {
            // Glassy, blurred background
            VisualEffectBlur(blurStyle: .systemMaterial)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Drag handle and close button
                HStack {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.trailing, 12)
                    }
                }
                .frame(height: 24)
                // Hero Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search asset...", text: $searchText)
                            .focused($searchFocused)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    if searchFocused {
                        Button("Cancel") { searchText = ""; searchFocused = false }
                            .padding(.trailing, 8)
                    }
                }
                .padding(.bottom, 4)
                // Trending Ticker
                if !assetListVM.assets.isEmpty {
                    InfiniteTickerView(assets: trendingAssets)
                        .frame(height: 36)
                        .padding(.bottom, 8)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Quick Actions
                        HStack(spacing: 16) {
                            quickActionButton(title: "Top Gainer", icon: "arrow.up.right", color: .green, asset: topGainer)
                            quickActionButton(title: "Top Loser", icon: "arrow.down.right", color: .red, asset: topLoser)
                            quickActionButton(title: "Random", icon: "shuffle", color: .blue, asset: randomAsset)
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                showConfetti = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    selectAsset(randomAsset)
                                }
                            }) {
                                Label("Surprise Me!", systemImage: "sparkles")
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.15))
                                    .cornerRadius(18)
                            }
                        }
                        .padding(.horizontal)
                        // Trending Now
                        if !trendingAssets.isEmpty {
                            let uniqueTrending = Dictionary(grouping: trendingAssets, by: { $0.id }).compactMap { $0.value.first }
                            SectionHeader(title: "Trending Now", icon: "flame.fill", color: .orange)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(uniqueTrending, id: \ .id) { asset in
                                        assetCard(asset: asset, highlight: true)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        // Recently Traded
                        let recent = recentlyTraded
                        if !recent.isEmpty {
                            let uniqueRecent = Dictionary(grouping: recent, by: { $0.id }).compactMap { $0.value.first }
                            SectionHeader(title: "Recently Traded", icon: "clock.arrow.circlepath", color: .blue)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 18) {
                                    ForEach(uniqueRecent, id: \ .id) { asset in
                                        assetCard(asset: asset, highlight: false)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        // Asset Grid
                        let filtered = filteredAssets
                        let uniqueFiltered = Dictionary(grouping: filtered, by: { $0.id }).compactMap { $0.value.first }
                        SectionHeader(title: "All Assets", icon: "chart.bar.xaxis", color: .accentColor)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 24)], spacing: 24) {
                            ForEach(uniqueFiltered, id: \ .id) { asset in
                                assetCard(asset: asset, highlight: false)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).opacity(0.7))
            .cornerRadius(24)
            .padding(.top, 8)
            .padding(.bottom, 0)
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $showTradeForm) {
                if let asset = selectedAsset {
                    TradeFormView(asset: asset)
                        .environmentObject(portfolioVM)
                }
            }
            .overlay(
                Group {
                    if showConfetti {
                        ConfettiView()
                            .transition(.scale)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showConfetti = false
                                }
                            }
                    }
                }
            )
            // Loading state
            if assetListVM.assets.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("Loading assets...")
                        .padding()
                    Spacer()
                }
                .background(Color(.systemBackground).opacity(0.8))
            }
        }
    }
    
    private func selectAsset(_ asset: CryptoAsset?) {
        guard let asset = asset else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selectedAsset = asset
        showTradeForm = true
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, asset: CryptoAsset?) -> some View {
        Button(action: { selectAsset(asset) }) {
            Label(title, systemImage: icon)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color.opacity(0.15))
                .cornerRadius(18)
        }
        .disabled(asset == nil)
    }
    
    private func assetCard(asset: CryptoAsset, highlight: Bool) -> some View {
        Button(action: { selectAsset(asset) }) {
            VStack(spacing: 8) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(highlight ? .orange : .accentColor)
                Text(asset.symbol.replacingOccurrences(of: "USDT", with: ""))
                    .font(.headline)
                Text("$\(asset.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let change = asset.change24h {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(change >= 0 ? .green : .red)
                        Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")%")
                            .foregroundColor(change >= 0 ? .green : .red)
                            .font(.caption)
                    }
                }
                if highlight {
                    Text("🔥 Trending")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
            }
            .padding()
            .background(highlight ? Color.orange.opacity(0.12) : Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.09), radius: 4, x: 0, y: 2)
            .scaleEffect(selectedAsset?.symbol == asset.symbol ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedAsset?.symbol == asset.symbol)
        }
        .buttonStyle(.plain)
    }
    
    private var filteredAssets: [CryptoAsset] {
        let assets = assetListVM.assets
        if searchText.isEmpty { return assets }
        return assets.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    private var trendingAssets: [CryptoAsset] {
        assetListVM.assets.sorted { abs($0.change24h ?? 0) > abs($1.change24h ?? 0) }.prefix(5).map { $0 }
    }
    private var recentlyTraded: [CryptoAsset] {
        let symbols = Array(Set(portfolioVM.orders.suffix(10).map { $0.symbol }))
        return symbols.compactMap { sym in assetListVM.assets.first(where: { $0.symbol == sym }) }
    }
    private var topGainer: CryptoAsset? {
        assetListVM.assets.max(by: { ($0.change24h ?? 0) < ($1.change24h ?? 0) })
    }
    private var topLoser: CryptoAsset? {
        assetListVM.assets.min(by: { ($0.change24h ?? 0) < ($1.change24h ?? 0) })
    }
    private var randomAsset: CryptoAsset? {
        assetListVM.assets.randomElement()
    }
}

// VisualEffectBlur for glassy background
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.title3.bold())
                .foregroundColor(color)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct InfiniteTickerView: View {
    let assets: [CryptoAsset]
    @State private var offset: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            let totalWidth = CGFloat(assets.count) * 120
            HStack(spacing: 32) {
                ForEach(Array((assets + assets).enumerated()), id: \ .offset) { idx, asset in
                    HStack(spacing: 8) {
                        Text(asset.symbol.replacingOccurrences(of: "USDT", with: ""))
                            .font(.caption.bold())
                        Text("$\(asset.price, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if let change = asset.change24h {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .foregroundColor(change >= 0 ? .green : .red)
                            Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")%")
                                .foregroundColor(change >= 0 ? .green : .red)
                                .font(.caption2)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemBackground).opacity(0.7))
                    .cornerRadius(10)
                }
            }
            .offset(x: offset)
            .onAppear {
                withAnimation(Animation.linear(duration: 18).repeatForever(autoreverses: false)) {
                    offset = -totalWidth / 2
                }
            }
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<20) { i in
                Circle()
                    .fill([Color.purple, .blue, .green, .yellow, .red, .orange].randomElement()!)
                    .frame(width: 8, height: 8)
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: animate ? geo.size.height : 0
                    )
                    .animation(
                        .easeIn(duration: Double.random(in: 0.8...1.2)),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
        .ignoresSafeArea()
    }
}

struct TradeLauncherView_Previews: PreviewProvider {
    static var previews: some View {
        TradeLauncherView()
            .environmentObject(PortfolioViewModel())
            .environmentObject(WatchlistViewModel())
    }
} 
