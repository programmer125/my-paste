import ClipboardCore
import SwiftUI

struct PopupView: View {
    @ObservedObject var viewModel: PopupViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(Color.black.opacity(0.12))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        row(item: item, selected: index == viewModel.selectedIndex)
                        if index < viewModel.items.count - 1 {
                            Divider()
                                .overlay(Color.black.opacity(0.12))
                                .padding(.leading, 78)
                        }
                    }
                }
            }
            .frame(height: 340)

            Divider()
                .overlay(Color.black.opacity(0.12))

            HStack(spacing: 12) {
                Label("上/下键选择", systemImage: "arrow.up.arrow.down")
                Label("回车粘贴", systemImage: "return")
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
    }

    private var header: some View {
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

            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.black.opacity(0.75))
                .padding(.trailing, 6)
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
}
