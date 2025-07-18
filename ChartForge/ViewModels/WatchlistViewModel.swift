import Foundation
import Combine

class WatchlistViewModel: ObservableObject {
    @Published private(set) var watchlist: Watchlist
    
    init() {
        self.watchlist = Watchlist.load()
    }
    
    func isFavorited(symbol: String) -> Bool {
        watchlist.symbols.contains(symbol)
    }
    
    func toggle(symbol: String) {
        if watchlist.symbols.contains(symbol) {
            watchlist.symbols.remove(symbol)
        } else {
            watchlist.symbols.insert(symbol)
        }
        watchlist.save()
        objectWillChange.send()
    }
} 