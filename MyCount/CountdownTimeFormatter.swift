//
//  CountdownTimeFormatter.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import Foundation

struct CountdownSummary {
    let headerText: String
    let countdownText: String
    let showDayUnit: Bool
    let isCritical: Bool
    let expired: Bool
}

struct CountdownDetailInfo {
    let dateText: String
    let timeText: String
    let remainingForDateTab: String
    let remainingForTimeTab: String
    let untilMidnight: String
    let expired: Bool
}

enum CountdownTimeFormatter {
    private static let calendar = Calendar.current
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    private static let dateWithDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日 (E)"
        return formatter
    }()
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func dateText(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func dateWithDayText(_ date: Date) -> String {
        dateWithDayFormatter.string(from: date)
    }

    static func timeText(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func summary(for item: CountdownItem, now: Date) -> CountdownSummary {
        let isCountUp = item.countMode == .countup
        let diff = item.targetDate.timeIntervalSince(now)
        let expired = isCountUp ? false : diff <= 0
        let isCritical = !isCountUp && diff > 0 && diff < 86_400
        let headerText = isCountUp ? "あれから" : "残り"
        let showDayUnit = isCountUp || !isCritical
        let countdownText: String

        if isCountUp {
            let elapsed = max(0, now.timeIntervalSince(item.targetDate))
            countdownText = String(Int(elapsed / 86_400))
        } else if expired {
            countdownText = "0"
        } else if isCritical {
            if diff < 3_600 {
                countdownText = formatDurationMs(diff)
            } else {
                countdownText = formatDurationHms(diff)
            }
        } else {
            countdownText = String(Int(diff / 86_400))
        }

        return CountdownSummary(
            headerText: headerText,
            countdownText: countdownText,
            showDayUnit: showDayUnit,
            isCritical: isCritical,
            expired: expired
        )
    }

    static func detail(for item: CountdownItem, now: Date) -> CountdownDetailInfo {
        let isCountUp = item.countMode == .countup
        let diff = item.targetDate.timeIntervalSince(now)
        let expired = isCountUp ? false : diff <= 0
        let isCritical = !isCountUp && diff > 0 && diff < 86_400

        let dateTabText: String
        if isCountUp {
            let elapsed = max(0, now.timeIntervalSince(item.targetDate))
            dateTabText = "\(Int(elapsed / 86_400))日"
        } else if expired {
            dateTabText = "終了"
        } else if isCritical {
            dateTabText = formatDurationHms(diff)
        } else {
            dateTabText = "\(Int(diff / 86_400))日"
        }

        let timeTabText: String
        if isCountUp {
            let elapsed = max(0, now.timeIntervalSince(item.targetDate))
            timeTabText = formatTotalHoursDuration(elapsed)
        } else if expired {
            timeTabText = "0:00:00"
        } else {
            timeTabText = formatTotalHoursDuration(diff)
        }

        return CountdownDetailInfo(
            dateText: dateText(item.targetDate),
            timeText: timeText(item.targetDate),
            remainingForDateTab: dateTabText,
            remainingForTimeTab: timeTabText,
            untilMidnight: timeUntilMidnight(from: now),
            expired: expired
        )
    }

    static func timeUntilMidnight(from now: Date) -> String {
        let startOfDay = calendar.startOfDay(for: now)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return formatDurationHms(0)
        }
        let diff = max(0, nextDay.timeIntervalSince(now))
        return formatDurationHms(diff)
    }

    static func formatDurationHms(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func formatDurationMs(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func formatTotalHoursDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}
