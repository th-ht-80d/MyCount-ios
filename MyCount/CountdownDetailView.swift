//
//  CountdownDetailView.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import SwiftUI

struct CountdownDetailView: View {
    @EnvironmentObject private var store: CountdownStore
    @State private var selectedTab = 0
    @State private var isEditorPresented = false

    let itemId: UUID

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            content(now: timeline.date)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if store.item(for: itemId) != nil {
                    Button("編集") {
                        isEditorPresented = true
                    }
                }
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            if let item = store.item(for: itemId) {
                CountdownEditorView(item: item)
            }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let item = store.item(for: itemId) {
            let detail = CountdownTimeFormatter.detail(for: item, now: now)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.title)
                        .font(.title)
                    Text("設定日時: \(detail.dateText) \(detail.timeText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $selectedTab) {
                        Text("日付").tag(0)
                        Text("時間").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if selectedTab == 0 {
                        DetailInfoBlock(
                            title: item.countMode == .countup ? "経過日数" : "残り日数",
                            value: detail.remainingForDateTab,
                            accent: item.countMode == .countup || !detail.expired
                        )
                        DetailInfoBlock(
                            title: "本日の日付が変わるまで",
                            value: detail.untilMidnight
                        )
                    } else {
                        DetailInfoBlock(
                            title: item.countMode == .countup ? "経過時間" : "残り時間",
                            value: detail.remainingForTimeTab,
                            accent: item.countMode == .countup || !detail.expired,
                            valueFont: .largeTitle
                        )
                    }
                }
                .padding(24)
            }
            .navigationTitle(item.title)
        } else {
            Text("データが存在しません")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct DetailInfoBlock: View {
    let title: String
    let value: String
    var accent: Bool = false
    var valueFont: Font = .title2

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(valueFont)
                .foregroundStyle(accent ? Color.accentColor : Color.primary)
        }
    }
}

#Preview {
    CountdownDetailView(itemId: UUID())
        .environmentObject(CountdownStore())
}
