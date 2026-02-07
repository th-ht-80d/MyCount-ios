//
//  CountdownStore.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import Combine
import Foundation

final class CountdownStore: ObservableObject {
    @Published private(set) var items: [CountdownItem] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        fileURL = (directory ?? FileManager.default.temporaryDirectory).appendingPathComponent("countdowns.json")
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        load()
    }

    func item(for id: UUID) -> CountdownItem? {
        items.first { $0.id == id }
    }

    func add(
        title: String,
        targetDate: Date,
        countMode: CountMode,
        imageId: String,
        customImageData: Data?
    ) {
        let now = Date()
        let newItem = CountdownItem(
            id: UUID(),
            title: title,
            targetDate: targetDate,
            createdAt: now,
            updatedAt: now,
            imageId: imageId,
            customImageData: customImageData,
            countMode: countMode
        )
        items.append(newItem)
        sortItems()
        save()
    }

    func update(
        id: UUID,
        title: String,
        targetDate: Date,
        countMode: CountMode,
        imageId: String,
        customImageData: Data?
    ) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var updated = items[index]
        updated.title = title
        updated.targetDate = targetDate
        updated.updatedAt = Date()
        updated.countMode = countMode
        updated.imageId = imageId
        updated.customImageData = customImageData
        items[index] = updated
        sortItems()
        save()
    }

    func delete(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        items.removeAll { ids.contains($0.id) }
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if items.indices.contains(index) {
                items.remove(at: index)
            }
        }
        save()
    }

    func rollOverExpiredCountdowns(referenceDate now: Date) {
        let calendar = Calendar.current
        var hasChanges = false

        for index in items.indices {
            guard items[index].countMode == .countdown else { continue }
            guard items[index].targetDate <= now else { continue }

            var nextTarget = items[index].targetDate
            while nextTarget <= now {
                if let shifted = calendar.date(byAdding: .year, value: 1, to: nextTarget) {
                    nextTarget = shifted
                } else {
                    nextTarget = nextTarget.addingTimeInterval(31_536_000)
                }
            }

            if nextTarget != items[index].targetDate {
                items[index].targetDate = nextTarget
                items[index].updatedAt = now
                hasChanges = true
            }
        }

        if hasChanges {
            sortItems()
            save()
        }
    }

    // MARK: - Private
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            items = []
            return
        }
        do {
            items = try decoder.decode([CountdownItem].self, from: data)
            sortItems()
        } catch {
            items = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }

    private func sortItems() {
        items.sort { $0.createdAt > $1.createdAt }
    }
}
