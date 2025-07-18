//
//  ChartForgeWidgetBundle.swift
//  ChartForgeWidget
//
//  Created by Parth Sinh on 18/07/25.
//

import WidgetKit
import SwiftUI

@main
struct ChartForgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChartForgeWidget()
        ChartForgeWidgetControl()
        ChartForgeWidgetLiveActivity()
    }
}
