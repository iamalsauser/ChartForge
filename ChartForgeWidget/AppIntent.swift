//
//  AppIntent.swift
//  ChartForgeWidget
//
//  Created by Parth Sinh on 18/07/25.
//

import WidgetKit
import AppIntents

enum CryptoAssetSymbol: String, AppEnum, CaseDisplayRepresentable, Codable {
    case BTCUSDT, ETHUSDT, BNBUSDT, SOLUSDT, XRPUSDT, ADAUSDT, DOGEUSDT, MATICUSDT, DOTUSDT, AVAXUSDT
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Crypto Asset"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .BTCUSDT: "Bitcoin (BTC)",
        .ETHUSDT: "Ethereum (ETH)",
        .BNBUSDT: "Binance Coin (BNB)",
        .SOLUSDT: "Solana (SOL)",
        .XRPUSDT: "XRP",
        .ADAUSDT: "Cardano (ADA)",
        .DOGEUSDT: "Dogecoin (DOGE)",
        .MATICUSDT: "Polygon (MATIC)",
        .DOTUSDT: "Polkadot (DOT)",
        .AVAXUSDT: "Avalanche (AVAX)"
    ]
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Crypto Asset" }
    static var description: IntentDescription { "Choose which crypto asset to display in the widget." }

    @Parameter(title: "Asset", default: .BTCUSDT)
    var assetSymbol: CryptoAssetSymbol
}
