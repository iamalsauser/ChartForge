import SwiftUI

struct WatchlistView: View {
    @StateObject private var watchlistVM = WatchlistViewModel()
    @StateObject private var assetListVM = AssetListViewModel()
    @State private var selectedAsset: CryptoAsset?
    
    var body: some View {
        NavigationStack {
            List {
                let assets = assetListVM.assets.filter { watchlistVM.isFavorited(symbol: $0.symbol) }
                if assets.isEmpty {
                    Text("Your watchlist is empty. Tap the star on any asset to add it here.")
                        .foregroundColor(.secondary)
                        .padding()
                        .accessibilityLabel("Your watchlist is empty. Tap the star on any asset to add it here.")
                } else {
                    ForEach(assets) { asset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(asset.symbol)
                                    .font(.headline)
                                    .accessibilityLabel(asset.symbol)
                                Text(asset.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .accessibilityLabel(asset.name)
                            }
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                watchlistVM.toggle(symbol: asset.symbol)
                            }) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .accessibilityLabel("Remove from watchlist")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedAsset = asset
                        }
                        .listRowBackground(Color(.systemBackground))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Watchlist")
            .navigationDestination(isPresented: Binding(
                get: { selectedAsset != nil },
                set: { if !$0 { selectedAsset = nil } }
            )) {
                if let asset = selectedAsset {
                    AssetDetailView(viewModel: AssetDetailViewModel(asset: asset))
                }
            }
        }
    }
}

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
    }
} 