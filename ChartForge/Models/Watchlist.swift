import Foundation

struct Watchlist: Codable {
    var symbols: Set<String>
    
    static let userDefaultsKey = "WatchlistSymbols"
    
    static func load() -> Watchlist {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Watchlist.self, from: data) {
            return decoded
        }
        return Watchlist(symbols: [])
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Watchlist.userDefaultsKey)
        }
    }
} 