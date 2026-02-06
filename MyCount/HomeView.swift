//
//  HomeView.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: CountdownStore
    @Environment(\.editMode) private var editMode
    @State private var selection = Set<UUID>()
    @State private var isEditorPresented = false

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                content(now: timeline.date)
            }
            .navigationTitle("ホーム")
            .navigationDestination(for: UUID.self) { id in
                CountdownDetailView(itemId: id)
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $isEditorPresented) {
                CountdownEditorView(item: nil)
            }
            .onChange(of: editMode?.wrappedValue.isEditing ?? false) { isEditing in
                if !isEditing {
                    selection.removeAll()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !store.items.isEmpty {
                EditButton()
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isEditorPresented = true
            } label: {
                Image(systemName: "plus")
            }
        }
        ToolbarItem(placement: .bottomBar) {
            if editMode?.wrappedValue.isEditing == true {
                Button("削除") {
                    store.delete(ids: selection)
                    selection.removeAll()
                }
                .disabled(selection.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if store.items.isEmpty {
            VStack(spacing: 12) {
                Text("まだイベントがありません")
                    .font(.title2)
                Text("右上の＋ボタンから作成してください")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        } else {
            List(selection: $selection) {
                ForEach(store.items) { item in
                    NavigationLink(value: item.id) {
                        CountdownCardView(item: item, now: now)
                    }
                }
                .onDelete(perform: store.delete)
            }
            .listStyle(.plain)
        }
    }
}

private struct CountdownCardView: View {
    let item: CountdownItem
    let now: Date

    private var summary: CountdownSummary {
        CountdownTimeFormatter.summary(for: item, now: now)
    }

    var body: some View {
        HStack(spacing: 12) {
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
        .padding(.vertical, 8)
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

#Preview {
    HomeView()
        .environmentObject(CountdownStore())
}
