//
//  ChartForgeWidget.swift
//  ChartForgeWidget
//
//  Created by Parth Sinh on 18/07/25.
//

import WidgetKit
import SwiftUI

let appGroupID = "group.parth.ChartForge"
let widgetPriceKey = "widget_prices"
let widgetHistoryKey = "widget_history"

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), assetSymbol: .BTCUSDT, price: 0, lastUpdated: Date(), history: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (price, lastUpdated, history) = WidgetDataLoader.load(for: configuration.assetSymbol)
        return SimpleEntry(date: Date(), assetSymbol: configuration.assetSymbol, price: price, lastUpdated: lastUpdated, history: history)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let (price, lastUpdated, history) = WidgetDataLoader.load(for: configuration.assetSymbol)
        let entry = SimpleEntry(date: Date(), assetSymbol: configuration.assetSymbol, price: price, lastUpdated: lastUpdated, history: history)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        return timeline
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let assetSymbol: CryptoAssetSymbol
    let price: Double
    let lastUpdated: Date
    let history: [Double]
}

struct ChartForgeWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bitcoinsign.circle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.accentColor)
            Text(assetName(for: entry.assetSymbol))
                .font(.headline)
            Text(entry.assetSymbol.rawValue.replacingOccurrences(of: "USDT", with: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("$\(entry.price, specifier: "%.2f")")
                .font(.title2)
                .bold()
            SparklineView(prices: entry.history)
                .frame(height: 24)
                .padding(.vertical, 2)
            Text(entry.lastUpdated, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(radius: 2))
    }
    
    private func assetName(for symbol: CryptoAssetSymbol) -> String {
        switch symbol {
        case .BTCUSDT: return "Bitcoin"
        case .ETHUSDT: return "Ethereum"
        case .BNBUSDT: return "Binance Coin"
        case .SOLUSDT: return "Solana"
        case .XRPUSDT: return "XRP"
        case .ADAUSDT: return "Cardano"
        case .DOGEUSDT: return "Dogecoin"
        case .MATICUSDT: return "Polygon"
        case .DOTUSDT: return "Polkadot"
        case .AVAXUSDT: return "Avalanche"
        }
    }
}

struct SparklineView: View {
    let prices: [Double]
    var body: some View {
        GeometryReader { geo in
            if prices.count > 1, let min = prices.min(), let max = prices.max(), max > min {
                let points = prices.enumerated().map { (i, price) in
                    CGPoint(
                        x: geo.size.width * CGFloat(i) / CGFloat(prices.count - 1),
                        y: geo.size.height * CGFloat(1 - (price - min) / (max - min))
                    )
                }
                Path { path in
                    path.move(to: points.first ?? .zero)
                    for pt in points.dropFirst() { path.addLine(to: pt) }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            } else {
                Path { _ in }
            }
        }
    }
}

struct WidgetDataLoader {
    static func load(for symbol: CryptoAssetSymbol) -> (Double, Date, [Double]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else { return (0, Date(), []) }
        let priceDict = userDefaults.dictionary(forKey: widgetPriceKey) as? [String: [String: Any]]
        let historyDict = userDefaults.dictionary(forKey: widgetHistoryKey) as? [String: [Double]]
        let price = priceDict?[symbol.rawValue]? ["price"] as? Double ?? 0
        let lastUpdated = priceDict?[symbol.rawValue]? ["lastUpdated"] as? Double ?? Date().timeIntervalSince1970
        let history = historyDict?[symbol.rawValue] ?? []
        return (price, Date(timeIntervalSince1970: lastUpdated), history)
    }
}

struct ChartForgeWidget: Widget {
    let kind: String = "ChartForgeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ChartForgeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    ChartForgeWidget()
} timeline: {
    SimpleEntry(date: .now, assetSymbol: .BTCUSDT, price: 50000, lastUpdated: .now, history: [49900, 50000, 50100, 50050, 50080])
    SimpleEntry(date: .now, assetSymbol: .ETHUSDT, price: 3000, lastUpdated: .now, history: [2950, 2980, 3000, 2990, 3005])
}
