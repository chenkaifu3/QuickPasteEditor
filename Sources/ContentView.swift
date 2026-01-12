import SwiftUI
import AppKit
import Vision

struct ContentView: View {
    @State private var text: String = ""
    @State private var fontSize: CGFloat = 14
    @State private var wordCount: Int = 0
    @State private var lineCount: Int = 0
    @State private var history: [ClipboardEntry] = []
    @State private var selectedHistoryIDs: Set<ClipboardEntry.ID> = []
    @State private var focusedHistoryID: ClipboardEntry.ID?
    @State private var lastChangeCount: Int = NSPasteboard.general.changeCount
    @State private var suppressNextCapture: Bool = false
    @State private var previewHeight: CGFloat = 220
    @State private var previewDragStart: CGFloat?

    private let maxHistoryCount = 200
    private let monitorTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    private let historyFileName = "clipboard-history.json"

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                ToolbarButton(action: copyToClipboard) {
                    Label("复制文本框", systemImage: "doc.on.doc")
                }
                .help("复制文本框内容到剪贴板")

                ToolbarButton(action: copySelectedToClipboard) {
                    Label("复制选中记录", systemImage: "doc.on.doc.fill")
                }
                .help("将选中历史记录写回剪贴板（含富文本/图片）")

                ToolbarButton(action: deleteSelectedHistory) {
                    Label("删除记录", systemImage: "trash")
                }
                .help("删除选中的历史记录")

                ToolbarButton(action: clearHistory) {
                    Label("清空历史", systemImage: "trash.slash")
                }
                .help("清空所有历史记录")

                Spacer()

                // 字体大小调整
                HStack(spacing: 4) {
                    Button(action: { fontSize = max(10, fontSize - 1) }) {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .buttonStyle(.borderless)

                    Text("\(Int(fontSize))")
                        .frame(width: 30)
                        .multilineTextAlignment(.center)

                    Button(action: { fontSize = min(36, fontSize + 1) }) {
                        Image(systemName: "textformat.size.larger")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)

                // 统计信息
                Text("字数: \(wordCount) 行数: \(lineCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            HStack(spacing: 0) {
                List(history, selection: $selectedHistoryIDs) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.previewTitle)
                            .lineLimit(2)
                        Text(entry.timestampText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .tag(entry.id)
                }
                .frame(minWidth: 220, maxWidth: 280)
                .onDeleteCommand(perform: deleteSelectedHistory)

                Divider()

                VStack(spacing: 0) {
                    if let entry = selectedHistoryEntry {
                        previewView(for: entry)
                            .padding(8)
                            .frame(height: previewHeight)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if previewDragStart == nil {
                                            previewDragStart = previewHeight
                                        }
                                        let start = previewDragStart ?? previewHeight
                                        let proposed = start + value.translation.height
                                        previewHeight = min(max(proposed, 120), 420)
                                    }
                                    .onEnded { _ in
                                        previewDragStart = nil
                                    }
                            )
                    }

                    TextEditor(text: $text)
                        .font(.system(size: fontSize))
                        .padding(4)
                        .onChange(of: text) { updateCounts() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            lastChangeCount = NSPasteboard.general.changeCount
            loadHistory()
            updateCounts()
            captureClipboardIfNeeded(force: history.isEmpty)
        }
        .onReceive(monitorTimer) { _ in
            captureClipboardIfNeeded(force: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .suppressNextClipboardCapture)) { _ in
            suppressNextCapture = true
        }
        .onChange(of: selectedHistoryIDs) {
            if selectedHistoryIDs.isEmpty {
                focusedHistoryID = nil
                return
            }
            if selectedHistoryIDs.count == 1 {
                focusedHistoryID = selectedHistoryIDs.first
            } else if let focusedHistoryID, selectedHistoryIDs.contains(focusedHistoryID) {
                return
            } else {
                focusedHistoryID = selectedHistoryIDs.first
            }
        }
        .onChange(of: focusedHistoryID) {
            applySelectedHistoryToEditor()
        }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        suppressNextCapture = true
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }

    private func clearText() {
        text = ""
        updateCounts()
    }

    private func deleteSelectedHistory() {
        guard !selectedHistoryIDs.isEmpty else { return }
        history.removeAll { selectedHistoryIDs.contains($0.id) }
        if history.isEmpty {
            selectedHistoryIDs.removeAll()
            focusedHistoryID = nil
        } else {
            selectedHistoryIDs = Set([history.first?.id].compactMap { $0 })
        }
        saveHistory()
    }

    private func clearHistory() {
        history.removeAll()
        selectedHistoryIDs.removeAll()
        focusedHistoryID = nil
        saveHistory()
    }

    private func copySelectedToClipboard() {
        guard let selected = selectedHistoryEntry else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let item = NSPasteboardItem()
        var hasContent = false

        if let imageData = selected.imageData, let imageTypeRaw = selected.imageTypeRaw {
            item.setData(imageData, forType: NSPasteboard.PasteboardType(imageTypeRaw))
            hasContent = true
        }
        if let rtfData = selected.rtfData, let rtfTypeRaw = selected.rtfTypeRaw {
            item.setData(rtfData, forType: NSPasteboard.PasteboardType(rtfTypeRaw))
            hasContent = true
        }
        if let plainText = selected.text {
            item.setString(plainText, forType: .string)
            hasContent = true
        }
        if hasContent {
            suppressNextCapture = true
            pasteboard.writeObjects([item])
            lastChangeCount = pasteboard.changeCount
        }
    }

    private func applySelectedHistoryToEditor() {
        guard let selected = selectedHistoryEntry else { return }
        if let plainText = selected.text,
           !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text = plainText
            updateCounts()
            return
        }
        if let rtfData = selected.rtfData, let converted = rtfDataToPlainText(rtfData) {
            text = converted
            updateCounts()
            return
        }
        // 如果是图片，尝试 OCR 提取文字
        if let imageData = selected.imageData {
            text = "正在识别文字..."
            updateCounts()
            performOCR(on: imageData) { recognizedText in
                DispatchQueue.main.async {
                    if let recognizedText, !recognizedText.isEmpty {
                        text = recognizedText
                    } else {
                        text = ""
                    }
                    updateCounts()
                }
            }
            return
        }
        text = ""
        updateCounts()
    }

    private func performOCR(on imageData: Data, completion: @escaping (String?) -> Void) {
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            let fullText = recognizedStrings.joined(separator: "\n")
            completion(fullText)
        }
        
        // 配置识别参数
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(nil)
            }
        }
    }

    private func captureClipboardIfNeeded(force: Bool) {
        let pasteboard = NSPasteboard.general
        if suppressNextCapture {
            suppressNextCapture = false
            lastChangeCount = pasteboard.changeCount
            return
        }
        if !force && pasteboard.changeCount == lastChangeCount {
            return
        }
        lastChangeCount = pasteboard.changeCount

        guard let snapshot = ClipboardSnapshot.fromPasteboard(pasteboard) else { return }
        insertSnapshot(snapshot)
    }

    private func insertSnapshot(_ snapshot: ClipboardSnapshot) {
        if let existingIndex = history.firstIndex(where: { $0.signature == snapshot.signature }) {
            history.remove(at: existingIndex)
        }
        history.insert(snapshot.toEntry(), at: 0)
        if history.count > maxHistoryCount {
            history.removeLast(history.count - maxHistoryCount)
        }
        if selectedHistoryIDs.isEmpty {
            selectedHistoryIDs = Set([history.first?.id].compactMap { $0 })
            focusedHistoryID = selectedHistoryIDs.first
        }
        saveHistory()
    }

    private var selectedHistoryEntry: ClipboardEntry? {
        guard let focusedHistoryID else { return nil }
        return history.first { $0.id == focusedHistoryID }
    }

    private func updateCounts() {
        // 计算字数（非空格字符序列）
        let words = text.split { $0.isWhitespace || $0.isNewline }
        wordCount = words.count

        // 计算行数
        lineCount = text.isEmpty ? 0 : text.split(separator: "\n").count
    }

    /// 主存储位置：~/Library/Application Support/QuickPasteEditor/clipboard-history.json
    private func primaryHistoryURL() -> URL {
        let manager = FileManager.default
        let appSupport = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("QuickPasteEditor", isDirectory: true)
            .appendingPathComponent(historyFileName)
    }

    /// 旧版本可能使用的候选位置（仅用于迁移）
    private func legacyHistoryCandidates() -> [URL] {
        var candidates: [URL] = []
        let manager = FileManager.default
        if let appSupport = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let bundleID = Bundle.main.bundleIdentifier ?? "QuickPasteEditor"
            if bundleID != "QuickPasteEditor" {
                candidates.append(appSupport.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent(historyFileName))
            }
        }
        candidates.append(manager.homeDirectoryForCurrentUser
            .appendingPathComponent(".quickpasteeditor", isDirectory: true)
            .appendingPathComponent(historyFileName))
        return candidates
    }

    private func loadHistory() {
        let decoder = JSONDecoder()
        let primaryURL = primaryHistoryURL()
        
        // 优先从主位置加载
        if let data = try? Data(contentsOf: primaryURL),
           let decoded = try? decoder.decode([ClipboardEntry].self, from: data) {
            history = decoded
            selectedHistoryIDs = Set([history.first?.id].compactMap { $0 })
            focusedHistoryID = selectedHistoryIDs.first
            // 确保删除所有旧位置的文件（防止回退）
            cleanupLegacyFiles()
            return
        }
        
        // 主位置不存在时，尝试从旧位置迁移（只迁移一次）
        var latestEntries: [ClipboardEntry]?
        var latestDate = Date.distantPast
        for url in legacyHistoryCandidates() {
            guard let data = try? Data(contentsOf: url) else { continue }
            guard let decoded = try? decoder.decode([ClipboardEntry].self, from: data) else { continue }
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let modifiedAt = (attributes?[.modificationDate] as? Date) ?? Date.distantPast
            if modifiedAt >= latestDate {
                latestDate = modifiedAt
                latestEntries = decoded
            }
        }
        
        if let latestEntries {
            history = latestEntries
            selectedHistoryIDs = Set([history.first?.id].compactMap { $0 })
            focusedHistoryID = selectedHistoryIDs.first
            // 迁移到主位置
            saveHistory()
            // 删除所有旧位置的文件
            cleanupLegacyFiles()
        }
    }
    
    /// 删除所有旧位置的历史文件，防止回退加载
    private func cleanupLegacyFiles() {
        let manager = FileManager.default
        for url in legacyHistoryCandidates() {
            try? manager.removeItem(at: url)
            // 尝试删除空目录
            let folder = url.deletingLastPathComponent()
            try? manager.removeItem(at: folder)
        }
    }

    private func saveHistory() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(history) else { return }
        let url = primaryHistoryURL()
        let folder = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}

struct ToolbarButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    @State private var isClicked: Bool = false

    var body: some View {
        Button(action: {
            // 简洁的点击反馈
            isClicked = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isClicked = false
            }
            action()
        }, label: label)
            .buttonStyle(.borderless)
            .opacity(isClicked ? 0.5 : 1.0)
            .scaleEffect(isClicked ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isClicked)
    }
}

extension Notification.Name {
    static let suppressNextClipboardCapture = Notification.Name("SuppressNextClipboardCapture")
}

private struct ClipboardSnapshot {
    let text: String?
    let rtfData: Data?
    let rtfTypeRaw: String?
    let imageData: Data?
    let imageTypeRaw: String?
    let signature: Int

    static func fromPasteboard(_ pasteboard: NSPasteboard) -> ClipboardSnapshot? {
        guard let item = pasteboard.pasteboardItems?.first else { return nil }

        let legacyFileType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if item.types.contains(.fileURL) || item.types.contains(legacyFileType) {
            return nil
        }

        let plainText = pasteboard.string(forType: .string)
        var rtfData: Data?
        var rtfTypeRaw: String?
        if let data = item.data(forType: .rtf) {
            rtfData = data
            rtfTypeRaw = NSPasteboard.PasteboardType.rtf.rawValue
        } else if let data = item.data(forType: .rtfd) {
            rtfData = data
            rtfTypeRaw = NSPasteboard.PasteboardType.rtfd.rawValue
        }

        var imageData: Data?
        var imageTypeRaw: String?
        if let data = item.data(forType: .tiff) {
            imageData = data
            imageTypeRaw = NSPasteboard.PasteboardType.tiff.rawValue
        } else if let data = item.data(forType: .png) {
            imageData = data
            imageTypeRaw = NSPasteboard.PasteboardType.png.rawValue
        }

        if plainText == nil && rtfData == nil && imageData == nil {
            return nil
        }

        var hasher = Hasher()
        hasher.combine(plainText)
        hasher.combine(rtfData)
        hasher.combine(imageData)
        let signature = hasher.finalize()

        return ClipboardSnapshot(
            text: plainText,
            rtfData: rtfData,
            rtfTypeRaw: rtfTypeRaw,
            imageData: imageData,
            imageTypeRaw: imageTypeRaw,
            signature: signature
        )
    }

    func toEntry() -> ClipboardEntry {
        ClipboardEntry(
            id: UUID(),
            date: Date(),
            signature: signature,
            text: text ?? rtfData.flatMap { rtfDataToPlainText($0) },
            rtfData: rtfData,
            rtfTypeRaw: rtfTypeRaw,
            imageData: imageData,
            imageTypeRaw: imageTypeRaw
        )
    }
}

private struct ClipboardEntry: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let signature: Int
    let text: String?
    let rtfData: Data?
    let rtfTypeRaw: String?
    let imageData: Data?
    let imageTypeRaw: String?

    var previewTitle: String {
        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        if imageData != nil {
            return "图片"
        }
        if rtfData != nil {
            return "富文本"
        }
        return "未知内容"
    }

    var timestampText: String {
        ClipboardEntry.timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

private func rtfDataToPlainText(_ data: Data) -> String? {
    rtfDataToAttributedString(data)?.string
}

private func rtfDataToAttributedString(_ data: Data) -> NSAttributedString? {
    let rtfOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.rtf
    ]
    if let attributed = try? NSAttributedString(data: data, options: rtfOptions, documentAttributes: nil) {
        return attributed
    }

    let rtfdOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.rtfd
    ]
    return try? NSAttributedString(data: data, options: rtfdOptions, documentAttributes: nil)
}

private extension ContentView {
    @ViewBuilder
    func previewView(for entry: ClipboardEntry) -> some View {
        if let imageData = entry.imageData, let image = NSImage(data: imageData) {
            GeometryReader { proxy in
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        } else if let rtfData = entry.rtfData, let attributed = rtfDataToAttributedString(rtfData) {
            ScrollView {
                Text(AttributedString(attributed))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if let plainText = entry.text, !plainText.isEmpty {
            ScrollView {
                Text(plainText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            EmptyView()
        }
    }
}
