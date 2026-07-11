import WidgetKit
import SwiftUI

// MARK: - App Group 공유 저장소 (앱이 home_widget 으로 저장한 값을 읽기만 함)

private let appGroupId = "group.kr.workon"

private func widgetString(_ key: String, _ fallback: String = "") -> String {
    let prefs = UserDefaults(suiteName: appGroupId)
    return prefs?.string(forKey: key) ?? fallback
}

// MARK: - Timeline Entry

struct WorkonEntry: TimelineEntry {
    let date: Date
    let loggedIn: Bool
    let brand: String
    let todayLabel: String
    let site: String
    let time: String
    let noSchedule: String
    let outstandingLabel: String
    let outstandingAmount: String
    let synced: String
    let loginPlease: String

    static func fromDefaults() -> WorkonEntry {
        let state = widgetString("workon_state", "out")
        return WorkonEntry(
            date: Date(),
            loggedIn: state == "in",
            brand: widgetString("workon_brand", "작업온"),
            todayLabel: widgetString("workon_today_label", "오늘 일정"),
            site: widgetString("workon_today_site", ""),
            time: widgetString("workon_today_time", ""),
            noSchedule: widgetString("workon_no_schedule", "오늘 일정 없음"),
            outstandingLabel: widgetString("workon_outstanding_label", "이번 달 미수금"),
            outstandingAmount: widgetString("workon_outstanding_amount", "0원"),
            synced: widgetString("workon_synced", ""),
            loginPlease: widgetString("workon_login_please", "로그인해 주세요")
        )
    }

    // 위젯 갤러리 미리보기용 샘플.
    static func sample() -> WorkonEntry {
        WorkonEntry(
            date: Date(),
            loggedIn: true,
            brand: "작업온",
            todayLabel: "오늘 일정",
            site: "대성건설 현장",
            time: "오전 8:00 ~ 오후 5:00",
            noSchedule: "오늘 일정 없음",
            outstandingLabel: "이번 달 미수금",
            outstandingAmount: "1,240,000원",
            synced: "오전 10:30 기준",
            loginPlease: "로그인해 주세요"
        )
    }
}

// MARK: - Timeline Provider (앱이 갱신을 트리거하므로 단일 엔트리 + .never)

struct WorkonProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkonEntry { .sample() }

    func getSnapshot(in context: Context, completion: @escaping (WorkonEntry) -> Void) {
        completion(context.isPreview ? .sample() : .fromDefaults())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkonEntry>) -> Void) {
        let timeline = Timeline(entries: [WorkonEntry.fromDefaults()], policy: .never)
        completion(timeline)
    }
}

// MARK: - 시안 토큰 색상 (라이트/다크)

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

private struct WorkonPalette {
    let scheme: ColorScheme
    var bg: Color { scheme == .dark ? Color(hex: 0x0F1522) : Color(hex: 0xF7F6F3) }
    var ink: Color { scheme == .dark ? Color(hex: 0xF1EFEA) : Color(hex: 0x1A2233) }
    var ink2: Color { scheme == .dark ? Color(hex: 0x9AA6B8) : Color(hex: 0x5A6474) }
    var orange: Color { Color(hex: 0xF4770C) }
    var receivable: Color { scheme == .dark ? Color(hex: 0xFB7A57) : Color(hex: 0xC2410C) }
    var border: Color { scheme == .dark ? Color(hex: 0x2A3446) : Color(hex: 0xE2DFD8) }
}

// MARK: - 배경(위젯 컨테이너) 호환 모디파이어

private struct WidgetBackground: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(color, for: .widget)
        } else {
            content.background(color)
        }
    }
}

private extension View {
    func workonBackground(_ color: Color) -> some View {
        modifier(WidgetBackground(color: color))
    }
}

// MARK: - Views

struct WorkonWidgetEntryView: View {
    var entry: WorkonEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme

    var body: some View {
        let p = WorkonPalette(scheme: scheme)
        Group {
            if !entry.loggedIn {
                loginView(p)
            } else if family == .systemMedium {
                mediumView(p)
            } else {
                smallView(p)
            }
        }
        .workonBackground(p.bg)
        .widgetURL(URL(string: "workon://home"))
    }

    // 2x2 — 미수금 중심
    private func smallView(_ p: WorkonPalette) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.brand)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(p.orange)
            Spacer(minLength: 0)
            Text(entry.outstandingLabel)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(p.ink2)
            Text(entry.outstandingAmount)
                .font(.system(size: 25, weight: .heavy))
                .foregroundColor(p.receivable)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.top, 2)
            if !entry.synced.isEmpty {
                Text(entry.synced)
                    .font(.system(size: 11))
                    .foregroundColor(p.ink2)
                    .lineLimit(1)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }

    // 4x2 — 오늘 일정 + 이번 달 미수금
    private func mediumView(_ p: WorkonPalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.brand)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(p.orange)
                Spacer()
                if !entry.synced.isEmpty {
                    Text(entry.synced)
                        .font(.system(size: 11))
                        .foregroundColor(p.ink2)
                        .lineLimit(1)
                }
            }
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.todayLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(p.ink2)
                    if entry.site.isEmpty {
                        Text(entry.noSchedule)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(p.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } else {
                        Text(entry.site)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(p.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(entry.time)
                            .font(.system(size: 13))
                            .foregroundColor(p.ink2)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(p.border)
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.outstandingLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(p.ink2)
                    Text(entry.outstandingAmount)
                        .font(.system(size: 21, weight: .heavy))
                        .foregroundColor(p.receivable)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(width: 122, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }

    private func loginView(_ p: WorkonPalette) -> some View {
        VStack(spacing: 8) {
            Text(entry.brand)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(p.orange)
            Text(entry.loginPlease)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(p.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
}

// MARK: - Widget

struct WorkonWidget: Widget {
    let kind: String = "WorkonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkonProvider()) { entry in
            WorkonWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("작업온")
        .description("오늘 일정과 이번 달 미수금을 홈 화면에서 바로 확인")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
