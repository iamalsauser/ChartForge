import Foundation

class CacheManager {
    static let shared = CacheManager()
    private let cache = NSCache<NSString, NSData>()
    
    private init() {}
    
    // Cache data for a key
    func setData(_ data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }
    
    // Retrieve cached data for a key
    func data(forKey key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    // Clear cache
    func clear() {
        cache.removeAllObjects()
    }
}
