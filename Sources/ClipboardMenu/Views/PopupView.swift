import ClipboardCore
import SwiftUI

struct PopupView: View {
    @ObservedObject var viewModel: PopupViewModel
    let onSaveNote: (UUID, String?) -> Void

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case search
        case note(UUID)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(Color.black.opacity(0.12))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            row(item: item, selected: index == viewModel.selectedIndex)
                                .id(item.id)
                            if index < viewModel.items.count - 1 {
                                Divider()
                                    .overlay(Color.black.opacity(0.12))
                                    .padding(.leading, 78)
                            }
                        }
                    }
                }
                .onAppear {
                    processPendingScroll(using: proxy)
                }
                .onChange(of: viewModel.pendingScrollRequest) { _, _ in
                    processPendingScroll(using: proxy)
                }
            }
            .frame(height: 340)

            Divider()
                .overlay(Color.black.opacity(0.12))

            HStack(spacing: 12) {
                Label("上/下键选择", systemImage: "arrow.up.arrow.down")
                Label("回车复制", systemImage: "return")
                Label("双击编辑备注", systemImage: "square.and.pencil")
                Label("Esc关闭", systemImage: "escape")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.black.opacity(0.62))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 760)
        .background(
            ZStack {
                Color(red: 0.83, green: 0.84, blue: 0.86).opacity(0.95)
                LinearGradient(
                    colors: [Color.white.opacity(0.2), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onChange(of: focusedField) { _, newValue in
            viewModel.setSearchFieldFocused(newValue == .search)
        }
        .onChange(of: viewModel.editingItemID) { _, newValue in
            guard let newValue else {
                if case .note = focusedField {
                    focusedField = nil
                }
                return
            }

            DispatchQueue.main.async {
                focusedField = .note(newValue)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(red: 0.35, green: 0.56, blue: 0.78))
                    Text("CL")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Clipboard History")
                        .font(.system(size: 24, weight: .bold))
                    Text("共 \(viewModel.items.count) 条 · 按光标位置呼出")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.6))
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.62))

                TextField(
                    "搜索备注优先，其次搜索复制内容",
                    text: Binding(
                        get: { viewModel.searchQuery },
                        set: { viewModel.updateSearchQuery($0) }
                    )
                )
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .focused($focusedField, equals: .search)
                .onSubmit {
                    submitSearch()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func row(item: ClipboardItem, selected: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                Image(systemName: "doc.text")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.14, green: 0.53, blue: 0.77))
            }
            .frame(width: 42, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(primaryLine(for: item.text))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.9))
                    .lineLimit(1)

                Text(metadata(for: item))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.68))
                    .lineLimit(1)

                if viewModel.editingItemID == item.id {
                    TextField("输入备注，回车保存（最多 \(ClipboardItem.maxNoteLength) 字）", text: $viewModel.editingNoteText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.black.opacity(0.14), lineWidth: 1)
                                )
                        )
                        .focused($focusedField, equals: .note(item.id))
                        .onSubmit {
                            saveEditingNote()
                        }
                } else {
                    Text(noteLine(for: item))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            item.note == nil
                                ? Color.black.opacity(0.48)
                                : Color.black.opacity(0.78)
                        )
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            selected
                ? Color(red: 0.71, green: 0.75, blue: 0.79).opacity(0.65)
                : Color.clear
        )
        .contentShape(Rectangle())
        .gesture(rowTapGesture(for: item))
    }

    private func primaryLine(for text: String) -> String {
        let compact = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return compact.isEmpty ? "空文本" : compact
    }

    private func metadata(for item: ClipboardItem) -> String {
        let characters = item.text.count
        let timestamp = item.copiedAt.formatted(
            .dateTime
                .year()
                .month(.twoDigits)
                .day(.twoDigits)
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
        return "\(characters) 字符 · 纯文本 · 修改于 \(timestamp)"
    }

    private func noteLine(for item: ClipboardItem) -> String {
        guard let note = item.note else { return "双击添加备注" }
        return "备注：\(note)"
    }

    private func saveEditingNote() {
        guard let commit = viewModel.commitEditingNote() else { return }
        onSaveNote(commit.itemID, commit.note)
        focusedField = nil
    }

    private func submitSearch() {
        viewModel.submitSearch()
        focusedField = nil
    }

    private func rowTapGesture(for item: ClipboardItem) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                viewModel.beginEditingNote(for: item.id)
            }
            .exclusively(
                before: TapGesture()
                    .onEnded {
                        viewModel.selectItem(item.id)
                    }
            )
    }

    private func processPendingScroll(using proxy: ScrollViewProxy) {
        guard let request = viewModel.pendingScrollRequest else { return }

        let anchor: UnitPoint = switch request.alignment {
        case .top:
            .top
        case .bottom:
            .bottom
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            proxy.scrollTo(request.itemID, anchor: anchor)
        }
        viewModel.consumePendingScrollRequest()
    }
}
