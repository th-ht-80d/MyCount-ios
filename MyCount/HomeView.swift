//
//  HomeView.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: CountdownStore
    @State private var selectedIds = Set<UUID>()
    @State private var isSelectionMode = false
    @State private var isEditorPresented = false
    @State private var isSettingsPresented = false

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                ZStack(alignment: .bottomTrailing) {
                    content(now: timeline.date)
                    floatingActionButton
                }
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
                .foregroundStyle(selectedIds.isEmpty ? Color.secondary : Color.white)
                .background(selectedIds.isEmpty ? Color(.systemGray5) : Color.accentColor)
                .clipShape(Capsule())
            }
            .disabled(selectedIds.isEmpty)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
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
            .padding(.bottom, 20)
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
                .frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(CountdownTimeFormatter.dateWithDayText(item.targetDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
        if summary.isCritical {
            return .orange
        }
        return .green
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(summary.headerText)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 4) {
                Text(summary.countdownText)
                    .font(summary.showDayUnit ? .title2 : .headline)
                    .foregroundStyle(valueColor)
                if summary.showDayUnit {
                    Text("日")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CountdownThumbnailView: View {
    let item: CountdownItem

    var body: some View {
        let sample = CountdownImageSamples.find(id: item.imageId)
        Image(sample.assetName)
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
