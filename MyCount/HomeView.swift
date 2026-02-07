//
//  HomeView.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import Combine
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: CountdownStore
    @State private var selectedIds = Set<UUID>()
    @State private var isSelectionMode = false
    @State private var isEditorPresented = false
    @State private var isSettingsPresented = false
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                content(now: now)
                floatingActionButton
            }
            .navigationTitle("ホーム")
            .navigationDestination(isPresented: $isEditorPresented) {
                CountdownEditorView(item: nil)
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsPlaceholderView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !store.items.isEmpty {
                        Button(isSelectionMode ? "キャンセル" : "選択") {
                            toggleSelectionMode()
                        }
                    }
                }
            }
            .onAppear {
                store.rollOverExpiredCountdowns(referenceDate: now)
            }
            .onReceive(ticker) { current in
                now = current
                store.rollOverExpiredCountdowns(referenceDate: current)
            }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if store.items.isEmpty {
            VStack(spacing: 12) {
                Text("まだイベントがありません")
                    .font(.title2)
                Text("右下の＋ボタンから作成してください")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.items) { item in
                        if isSelectionMode {
                            CountdownCardView(
                                item: item,
                                now: now,
                                selectionMode: true,
                                selected: selectedIds.contains(item.id)
                            )
                            .onTapGesture {
                                toggleItemSelection(id: item.id)
                            }
                        } else {
                            NavigationLink(destination: CountdownDetailView(itemId: item.id)) {
                                CountdownCardView(
                                    item: item,
                                    now: now,
                                    selectionMode: false,
                                    selected: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }

    @ViewBuilder
    private var floatingActionButton: some View {
        if isSelectionMode {
            Button {
                deleteSelected()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text("削除")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundStyle(Color.white.opacity(selectedIds.isEmpty ? 0.75 : 1.0))
                .background(selectedIds.isEmpty ? Color(.systemGray4) : Color.accentColor)
                .clipShape(Capsule())
            }
            .disabled(selectedIds.isEmpty)
            .padding(.trailing, 20)
            .padding(.bottom, 36)
        } else {
            Button {
                isEditorPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.bottom, 50)
        }
    }

    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedIds.removeAll()
        }
    }

    private func toggleItemSelection(id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private func deleteSelected() {
        store.delete(ids: selectedIds)
        selectedIds.removeAll()
        isSelectionMode = false
    }
}

private struct CountdownCardView: View {
    let item: CountdownItem
    let now: Date
    let selectionMode: Bool
    let selected: Bool

    private var summary: CountdownSummary {
        CountdownTimeFormatter.summary(for: item, now: now)
    }

    var body: some View {
        HStack(spacing: 12) {
            if selectionMode {
                SelectionIndicator(selected: selected)
            }
            CountdownThumbnailView(item: item)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(CountdownTimeFormatter.dateWithDayText(item.targetDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
            }
            Spacer()
            CountdownSummaryView(summary: summary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CountdownSummaryView: View {
    let summary: CountdownSummary

    private var valueColor: Color {
        if summary.expired {
            return .secondary
        }
        return AppPalette.countdownAccent
    }

    private var countdownFont: Font {
        if summary.showDayUnit {
            return .system(size: 31, weight: .semibold)
        }
        let isHms = summary.countdownText.split(separator: ":").count == 3
        return isHms ? .system(size: 29, weight: .semibold) : .system(size: 32, weight: .semibold)
    }

    private var countdownWidth: CGFloat {
        if summary.showDayUnit {
            return 118
        }
        let isHms = summary.countdownText.split(separator: ":").count == 3
        return isHms ? 136 : 124
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(summary.headerText)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(summary.countdownText)
                    .font(countdownFont)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .allowsTightening(true)
                    .foregroundStyle(valueColor)
                if summary.showDayUnit {
                    Text("日")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: countdownWidth, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: countdownWidth + 16, alignment: .center)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CountdownThumbnailView: View {
    let item: CountdownItem

    var body: some View {
        if let data = item.customImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            let sample = CountdownImageSamples.find(id: item.imageId)
            Image(sample.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct SelectionIndicator: View {
    let selected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.7), lineWidth: 2)
                .frame(width: 30, height: 30)
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

private struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("設定画面は未実装です")
                    .font(.headline)
                Text("Android版に合わせて後続で追加できます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(CountdownStore())
}
