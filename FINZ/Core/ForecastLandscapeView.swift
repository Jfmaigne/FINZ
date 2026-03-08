import SwiftUI
import CoreData

public struct ForecastLandscapeView: View {
    let series: [(date: Date, balance: Decimal)]
    var onClose: () -> Void
    let forceLandscape: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showTooltip: Bool = false
    @State private var tooltipIndex: Int? = nil

    public init(series: [(date: Date, balance: Decimal)], forceLandscape: Bool = false, onClose: @escaping () -> Void) {
        self.series = series
        self.onClose = onClose
        self.forceLandscape = forceLandscape
    }

    public var body: some View {
        GeometryReader { geo in
            let rect = geo.frame(in: .local)
            ZStack(alignment: .topLeading) {
                Color.white.ignoresSafeArea()
                VStack {
                    HStack {
                        Spacer()
                        Text("Evolution du solde sur le mois de \(currentMonthName())")
                            .font(.title3.bold())
                            .foregroundStyle(finzColor)
                            .padding(.top, 16)
                        Spacer()
                    }
                    Spacer()
                }
                chart(in: rect)
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .bold))
                        .padding(12)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                        .foregroundStyle(.primary)
                        .padding(.top, 20)
                        .padding(.leading, 20)
                }
                .accessibilityLabel("Fermer")
            }
            .onAppear { if forceLandscape { lockLandscape() } }
            .onDisappear { if forceLandscape { unlockPortrait() } }
        }
        .preferredColorScheme(.light)
    }

    private func chart(in rect: CGRect) -> some View {
        let padding: CGFloat = 48
        let plotRect = CGRect(x: padding, y: 24, width: rect.width - padding - 16, height: rect.height - 60)
        return ZStack(alignment: .topLeading) {
            // Axes grid
            if let mm = minMax() {
                // Y grid and labels
                let ticks = yTicks(min: mm.lo, max: mm.hi, count: 6)
                ForEach(Array(ticks.enumerated()), id: \.offset) { _, t in
                    let y = yFor(value: t, lo: mm.lo, hi: mm.hi, rect: plotRect)
                    Path { p in
                        p.move(to: CGPoint(x: plotRect.minX, y: y))
                        p.addLine(to: CGPoint(x: plotRect.maxX, y: y))
                    }
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    Text(currency(t))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: plotRect.minX - 32, y: y)
                        .frame(width: 60, alignment: .trailing)
                }
                // Zero line if visible
                if mm.lo <= 0 && mm.hi >= 0 {
                    let y0 = yFor(value: 0, lo: mm.lo, hi: mm.hi, rect: plotRect)
                    Path { p in
                        p.move(to: CGPoint(x: plotRect.minX, y: y0))
                        p.addLine(to: CGPoint(x: plotRect.maxX, y: y0))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5,4]))
                    .foregroundStyle(Color.black.opacity(0.4))
                }
            }

            // X grid and labels (days)
            if series.count > 1 {
                let step = max(1, series.count / 8)
                ForEach(Array(series.enumerated()), id: \.offset) { idx, point in
                    if idx % step == 0 || idx == series.count - 1 || idx == 0 {
                        let x = xFor(index: idx, count: series.count, rect: plotRect)
                        Path { p in
                            p.move(to: CGPoint(x: x, y: plotRect.minY))
                            p.addLine(to: CGPoint(x: x, y: plotRect.maxY))
                        }
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        let day = Calendar.current.component(.day, from: point.date)
                        Text("\(day)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .position(x: x, y: plotRect.maxY + 10)
                    }
                }
            }

            // Polyline + markers
            if let mm = minMax(), series.count > 1 {
                Path { p in
                    for (i, item) in series.enumerated() {
                        let x = xFor(index: i, count: series.count, rect: plotRect)
                        let y = yFor(value: (item.balance as NSDecimalNumber).doubleValue, lo: mm.lo, hi: mm.hi, rect: plotRect)
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(LinearGradient(colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                ForEach(Array(series.enumerated()), id: \.offset) { i, item in
                    let x = xFor(index: i, count: series.count, rect: plotRect)
                    let y = yFor(value: (item.balance as NSDecimalNumber).doubleValue, lo: mm.lo, hi: mm.hi, rect: plotRect)
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 4, height: 4)
                        .position(x: x, y: y)
                }
            }
            
            // Tooltip overlay (crosshair, marker, bubble)
            Group {
                if let idx = tooltipIndex, let mm = minMax(), series.indices.contains(idx) {
                    let x = xFor(index: idx, count: series.count, rect: plotRect)
                    let y = yFor(value: (series[idx].balance as NSDecimalNumber).doubleValue, lo: mm.lo, hi: mm.hi, rect: plotRect)
                    // Vertical guide line
                    Path { p in
                        p.move(to: CGPoint(x: x, y: plotRect.minY))
                        p.addLine(to: CGPoint(x: x, y: plotRect.maxY))
                    }
                    .stroke(finzColor.opacity(0.25), lineWidth: 1)
                    // Highlight marker
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .background(Circle().fill(finzColor))
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)
                    // Bubble with date and value
                    let bubbleWidth: CGFloat = 140
                    let clampedX = min(max(plotRect.minX + bubbleWidth/2 + 8, x), plotRect.maxX - bubbleWidth/2 - 8)
                    let clampedY = max(plotRect.minY + 24, y - 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayString(series[idx].date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(currency((series[idx].balance as NSDecimalNumber).doubleValue))
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(8)
                    .frame(width: bubbleWidth)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(finzColor.opacity(0.2), lineWidth: 1)
                    )
                    .position(x: clampedX, y: clampedY)
                }
            }
        }
        .overlay(
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = value.location.x
                            guard series.count > 1, plotRect.width > 0, x >= plotRect.minX, x <= plotRect.maxX else { return }
                            let t = (x - plotRect.minX) / plotRect.width
                            let idx = Int(round(t * CGFloat(series.count - 1)))
                            tooltipIndex = max(0, min(series.count - 1, idx))
                        }
                        .onEnded { _ in
                            // Keep tooltip visible after gesture ends; comment next line to persist
                            // tooltipIndex = nil
                        }
                )
        )
    }

    // MARK: - Scaling helpers
    private func minMax() -> (lo: Double, hi: Double)? {
        guard !series.isEmpty else { return nil }
        let vals = series.map { ($0.balance as NSDecimalNumber).doubleValue }
        guard var lo = vals.min(), var hi = vals.max() else { return nil }
        if lo == hi { lo -= 1; hi += 1 }
        // Pad 10%
        let pad = max(1.0, (hi - lo) * 0.1)
        lo -= pad; hi += pad
        // Ensure zero visible if between
        if lo > 0 { lo = min(0, lo) }
        if hi < 0 { hi = max(0, hi) }
        return (lo, hi)
    }

    private func xFor(index: Int, count: Int, rect: CGRect) -> CGFloat {
        guard count > 1 else { return rect.minX }
        let t = CGFloat(index) / CGFloat(count - 1)
        return rect.minX + t * rect.width
    }

    private func yFor(value: Double, lo: Double, hi: Double, rect: CGRect) -> CGFloat {
        let clamped = max(lo, min(value, hi))
        let t = (clamped - lo) / (hi - lo)
        return rect.maxY - CGFloat(t) * rect.height
    }

    private func yTicks(min: Double, max: Double, count: Int) -> [Double] {
        guard count >= 2 else { return [min, max] }
        let span = max - min
        let rawStep = span / Double(count - 1)
        let mag = pow(10.0, floor(log10(rawStep)))
        let norm = rawStep / mag
        let step: Double
        if norm < 1.5 { step = 1 * mag }
        else if norm < 3 { step = 2 * mag }
        else if norm < 7 { step = 5 * mag }
        else { step = 10 * mag }
        let start = floor(min / step) * step
        let end = ceil(max / step) * step
        var ticks: [Double] = []
        var v = start
        while v <= end + step * 0.5 { ticks.append(v); v += step }
        return ticks
    }

    private func currency(_ value: Double) -> String {
        let n = NSNumber(value: abs(value))
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = Locale.current.currency?.identifier ?? "EUR"
        f.maximumFractionDigits = 0
        let s = f.string(from: n) ?? "\(abs(value).safeInt) €"
        return value < 0 ? "-\(s)" : s
    }

    private var finzColor: Color { Color(red: 0.52, green: 0.21, blue: 0.93) }

    private func currentMonthName() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "LLLL"
        return df.string(from: Date())
    }
    
    private func dayString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "d MMM"
        return df.string(from: date)
    }

    // MARK: - Orientation handling
    private func lockLandscape() {
        if let app = UIApplication.shared.delegate as? AppDelegate {
            app.orientationLock = [.landscapeLeft, .landscapeRight]
        }
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    private func unlockPortrait() {
        if let app = UIApplication.shared.delegate as? AppDelegate {
            app.orientationLock = .allButUpsideDown
        }
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    private func close() {
        unlockPortrait()
        onClose()
        dismiss()
    }
}

#Preview {
    let cal = Calendar.current
    let now = Date()
    let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
    let days = (0..<30).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    var balance: Decimal = 500
    let series = days.map { d -> (Date, Decimal) in
        let delta = Decimal(Int.random(in: -80...120))
        balance += delta
        return (d, balance)
    }
    return ForecastLandscapeView(series: series) { }
}
