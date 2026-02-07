//
//  CountdownEditorView.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import SwiftUI

struct CountdownEditorView: View {
    @EnvironmentObject private var store: CountdownStore
    @Environment(\.dismiss) private var dismiss

    private let originalItem: CountdownItem?
    private let initialDate: Date
    private let initialCountMode: CountMode
    private let initialImageId: String

    @State private var title: String
    @State private var selectedDate: Date
    @State private var countMode: CountMode
    @State private var selectedImageId: String
    @State private var titleError: String?
    @State private var showDiscardAlert = false
    @State private var showDeleteAlert = false

    init(item: CountdownItem?) {
        let normalizedDate = CountdownEditorView.normalizedDate(item?.targetDate ?? Date())
        let defaultImage = item?.imageId ?? CountdownImageSamples.default.id
        let defaultMode = item?.countMode ?? .countdown

        originalItem = item
        initialDate = normalizedDate
        initialCountMode = defaultMode
        initialImageId = defaultImage
        _title = State(initialValue: item?.title ?? "")
        _selectedDate = State(initialValue: normalizedDate)
        _countMode = State(initialValue: defaultMode)
        _selectedImageId = State(initialValue: defaultImage)
    }

    var body: some View {
        Form {
            Section("タイトル") {
                TextField("タイトルを入力", text: $title)
                    .textInputAutocapitalization(.words)
                    .onChange(of: title) { _ in
                        titleError = nil
                    }
                if let titleError {
                    Text(titleError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("日時") {
                DatePicker("日付", selection: dateBinding, displayedComponents: [.date])
                    .disabled(!isDateTimeEditable)
                DatePicker("時間", selection: timeBinding, displayedComponents: [.hourAndMinute])
                    .disabled(!isDateTimeEditable)
            }

            Section("カウント方法") {
                Picker("カウント方法", selection: $countMode) {
                    ForEach(CountMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("サンプル画像") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CountdownImageSamples.samples) { sample in
                            SampleImageCell(
                                sample: sample,
                                isSelected: sample.id == selectedImageId
                            ) {
                                selectedImageId = sample.id
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if originalItem != nil {
                Section {
                    Button("削除", role: .destructive) {
                        showDeleteAlert = true
                    }
                }
            }
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
            selectedImageId != initialImageId
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
                imageId: selectedImageId
            )
        } else {
            store.add(
                title: trimmedTitle,
                targetDate: selectedDate,
                countMode: countMode,
                imageId: selectedImageId
            )
        }
        dismiss()
    }

    private static func normalizedDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
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
