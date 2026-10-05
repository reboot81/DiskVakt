import AppKit
import SwiftUI

struct RetroAppIcon: View {
    let size: CGFloat
    @State private var showsCredits = false

    var body: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .onTapGesture(count: 3) {
                NSSound.beep()
                showsCredits = true
            }
            .sheet(isPresented: $showsCredits) {
                RetroCreditsSheet(isPresented: $showsCredits)
            }
    }
}

private struct RetroCreditsSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RetroCreditsView()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(.body, design: .monospaced, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .padding(14)
            .help(String(localized: "Stäng"))
        }
        .frame(width: 520, height: 380)
        .background(.black)
        .onExitCommand { isPresented = false }
    }
}

private struct RetroCreditsView: View {
    @State private var startDate = Date.now

    private var credits: [(String, Color)] {
        [
            ("*** PROJECT DISKVAKT ***", .green),
            ("", .white),
            (String(localized: "UTVECKLAD AV"), .white),
            ("BO SAURAGE", .cyan),
            ("", .white),
            (String(localized: "DESIGN & UTVECKLING"), .white),
            ("SWIFT · SWIFTUI · APPKIT", .cyan),
            ("DISKAR · NOTISER · NTFY", .cyan),
            ("", .white),
            (String(localized: "DRIVS AV SWIFT"), .white),
            (String(localized: "& KAFFE"), .orange),
            ("", .white),
            (String(localized: "FILER INGÅR EJ"), .yellow),
            ("", .white),
            (String(localized: "— TACK FÖR ATT DU HÅLLER KOLL —"), .green)
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                let contentHeight: CGFloat = 560
                let travel = geometry.size.height + contentHeight
                let offset = geometry.size.height
                    - CGFloat((elapsed * 32).truncatingRemainder(dividingBy: travel))

                ZStack(alignment: .top) {
                    PixelStarfield()
                    VStack(spacing: 17) {
                        ForEach(Array(credits.enumerated()), id: \.offset) { _, credit in
                            Text(credit.0)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(credit.1)
                                .shadow(color: credit.1.opacity(0.7), radius: 3)
                                .frame(height: 18)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: offset)
                    Scanlines()
                        .allowsHitTesting(false)
                }
            }
        }
        .background(.black)
        .clipped()
        .onAppear { startDate = .now }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "DiskVakt retroeftertext"))
    }
}

private struct PixelStarfield: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<72 {
                let x = CGFloat((index * 83 + 17) % 503) / 503 * size.width
                let y = CGFloat((index * 47 + 29) % 367) / 367 * size.height
                let side: CGFloat = index.isMultiple(of: 7) ? 2 : 1
                let opacity = index.isMultiple(of: 5) ? 0.85 : 0.45
                context.fill(
                    Path(CGRect(x: x, y: y, width: side, height: side)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
    }
}

private struct Scanlines: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            for y in stride(from: CGFloat.zero, through: size.height, by: 4) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(.black.opacity(0.28)), lineWidth: 1)
        }
    }
}
