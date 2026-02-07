//
//  CountdownEditorView.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import PhotosUI
import SwiftUI
import UIKit

struct CountdownEditorView: View {
    @EnvironmentObject private var store: CountdownStore
    @Environment(\.dismiss) private var dismiss

    private let originalItem: CountdownItem?
    private let initialDate: Date
    private let initialCountMode: CountMode
    private let initialImageId: String
    private let initialCustomImageData: Data?

    @State private var title: String
    @State private var selectedDate: Date
    @State private var countMode: CountMode
    @State private var selectedImageId: String
    @State private var selectedCustomImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var titleError: String?
    @State private var showDiscardAlert = false
    @State private var showDeleteAlert = false

    init(item: CountdownItem?) {
        let normalizedDate = CountdownEditorView.normalizedDate(item?.targetDate ?? Date())
        let defaultImage = item?.imageId ?? CountdownImageSamples.default.id
        let defaultMode = item?.countMode ?? .countdown
        let defaultCustomImageData = item?.customImageData

        originalItem = item
        initialDate = normalizedDate
        initialCountMode = defaultMode
        initialImageId = defaultImage
        initialCustomImageData = defaultCustomImageData
        _title = State(initialValue: item?.title ?? "")
        _selectedDate = State(initialValue: normalizedDate)
        _countMode = State(initialValue: defaultMode)
        _selectedImageId = State(initialValue: defaultImage)
        _selectedCustomImageData = State(initialValue: defaultCustomImageData)
    }

    var body: some View {
        Form {
            titleSection
            dateSection
            countModeSection
            imageSection
            deleteSection
        }
        .navigationTitle(originalItem == nil ? "新規" : "編集")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    handleCancel()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    handleSave()
                }
            }
        }
        .alert("編集内容を破棄しますか？", isPresented: $showDiscardAlert) {
            Button("閉じる", role: .destructive) {
                dismiss()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("保存せずに閉じると変更は失われます。")
        }
        .alert("本当に削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                if let originalItem {
                    store.delete(ids: Set([originalItem.id]))
                }
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このカウントダウンは復元できません。")
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await loadImageData(from: newValue)
            }
        }
    }

    private var titleSection: some View {
        Section("タイトル") {
            TextField("タイトルを入力", text: $title)
                .textInputAutocapitalization(.words)
                .onChange(of: title) { _, _ in
                    titleError = nil
                }
            if let titleError {
                Text(titleError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var dateSection: some View {
        Section("日時") {
            DatePicker("日付", selection: dateBinding, displayedComponents: [.date])
                .disabled(!isDateTimeEditable)
            DatePicker("時間", selection: timeBinding, displayedComponents: [.hourAndMinute])
                .disabled(!isDateTimeEditable)
        }
    }

    private var countModeSection: some View {
        Section("カウント方法") {
            Picker("カウント方法", selection: $countMode) {
                ForEach(CountMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var imageSection: some View {
        Section("サンプル画像") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CountdownImageSamples.samples) { sample in
                        SampleImageCell(
                            sample: sample,
                            isSelected: sample.id == selectedImageId && selectedCustomImageData == nil
                        ) {
                            selectedImageId = sample.id
                            selectedCustomImageData = nil
                            selectedPhotoItem = nil
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("現在のプレビュー")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                currentPreviewImage
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentColor.opacity(0.5), lineWidth: 1.5)
                    )
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(
                    selectedCustomImageData == nil ? "画像をアップロード" : "画像を変更",
                    systemImage: "photo.badge.plus"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if selectedCustomImageData != nil {
                Button("アップロード画像を削除", role: .destructive) {
                    selectedCustomImageData = nil
                    selectedPhotoItem = nil
                }
            }
        }
    }

    @ViewBuilder
    private var currentPreviewImage: some View {
        if let customImageData = selectedCustomImageData, let image = UIImage(data: customImageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            let sample = CountdownImageSamples.find(id: selectedImageId)
            Image(sample.assetName)
                .resizable()
                .scaledToFill()
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        if originalItem != nil {
            Section {
                Button {
                    showDeleteAlert = true
                } label: {
                    Text("削除")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var isDateTimeEditable: Bool {
        countMode == .countdown
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newDate in
                let calendar = Calendar.current
                let time = calendar.dateComponents([.hour, .minute], from: selectedDate)
                selectedDate = calendar.date(
                    bySettingHour: time.hour ?? 0,
                    minute: time.minute ?? 0,
                    second: 0,
                    of: newDate
                ) ?? selectedDate
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newDate in
                let calendar = Calendar.current
                let date = calendar.startOfDay(for: selectedDate)
                let time = calendar.dateComponents([.hour, .minute], from: newDate)
                selectedDate = calendar.date(
                    bySettingHour: time.hour ?? 0,
                    minute: time.minute ?? 0,
                    second: 0,
                    of: date
                ) ?? selectedDate
            }
        )
    }

    private var hasChanges: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let dateChanged = abs(selectedDate.timeIntervalSince(initialDate)) > 1
        return trimmedTitle != (originalItem?.title ?? "") ||
            dateChanged ||
            countMode != initialCountMode ||
            selectedImageId != initialImageId ||
            selectedCustomImageData != initialCustomImageData
    }

    private func handleCancel() {
        if hasChanges {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func handleSave() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            titleError = "タイトルは必須です"
            return
        }
        if let originalItem {
            store.update(
                id: originalItem.id,
                title: trimmedTitle,
                targetDate: selectedDate,
                countMode: countMode,
                imageId: selectedImageId,
                customImageData: selectedCustomImageData
            )
        } else {
            store.add(
                title: trimmedTitle,
                targetDate: selectedDate,
                countMode: countMode,
                imageId: selectedImageId,
                customImageData: selectedCustomImageData
            )
        }
        dismiss()
    }

    private static func normalizedDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }

    @MainActor
    private func loadImageData(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let compressedData = Self.optimizedImageData(from: data) else {
            return
        }
        selectedCustomImageData = compressedData
    }

    private static func optimizedImageData(from rawData: Data) -> Data? {
        guard let image = UIImage(data: rawData) else { return nil }
        let maxPixel: CGFloat = 1_280
        let maxLength = max(image.size.width, image.size.height)
        let scale = min(1, maxPixel / maxLength)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}

private struct SampleImageCell: View {
    let sample: CountdownImageSample
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(sample.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                Text(sample.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CountdownEditorView(item: nil)
        .environmentObject(CountdownStore())
}
