@testable import ClipboardMenu
import ClipboardCore
import Foundation

#if canImport(XCTest)
import XCTest

@MainActor
final class PopupViewModelTests: XCTestCase {
    func testMoveSelectionDownShouldRequestBottomScrollWhenLeavingVisibleWindow() {
        let viewModel = PopupViewModel()
        viewModel.loadForDisplay(makeItems(count: 6))
        viewModel.consumePendingScrollRequest()

        viewModel.moveSelectionDown()
        XCTAssertNil(viewModel.pendingScrollRequest)

        viewModel.moveSelectionDown()
        XCTAssertNil(viewModel.pendingScrollRequest)

        viewModel.moveSelectionDown()
        XCTAssertNil(viewModel.pendingScrollRequest)

        viewModel.moveSelectionDown()

        XCTAssertEqual(viewModel.selectedIndex, 4)
        XCTAssertEqual(
            viewModel.pendingScrollRequest,
            PopupViewModel.ScrollRequest(
                itemID: viewModel.items[4].id,
                alignment: .bottom
            )
        )
    }

    func testMoveSelectionUpShouldOnlyRequestTopScrollAfterLeavingVisibleWindow() {
        let viewModel = PopupViewModel()
        viewModel.loadForDisplay(makeItems(count: 6))
        viewModel.consumePendingScrollRequest()

        for _ in 0..<5 {
            viewModel.moveSelectionDown()
        }
        viewModel.consumePendingScrollRequest()

        viewModel.moveSelectionUp()
        XCTAssertNil(viewModel.pendingScrollRequest)

        viewModel.moveSelectionUp()
        XCTAssertNil(viewModel.pendingScrollRequest)

        viewModel.moveSelectionUp()
        XCTAssertNil(viewModel.pendingScrollRequest)

        viewModel.moveSelectionUp()

        XCTAssertEqual(viewModel.selectedIndex, 1)
        XCTAssertEqual(
            viewModel.pendingScrollRequest,
            PopupViewModel.ScrollRequest(
                itemID: viewModel.items[1].id,
                alignment: .top
            )
        )
    }

    func testUpdateSearchQueryShouldResetScrollWindow() {
        let viewModel = PopupViewModel()
        viewModel.loadForDisplay(makeItems(count: 6))
        viewModel.consumePendingScrollRequest()

        for _ in 0..<5 {
            viewModel.moveSelectionDown()
        }
        viewModel.consumePendingScrollRequest()

        let selectedItemID = viewModel.items[5].id
        let selectedText = viewModel.items[5].text

        viewModel.updateSearchQuery(selectedText)

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.selectedIndex, 0)
        XCTAssertEqual(
            viewModel.pendingScrollRequest,
            PopupViewModel.ScrollRequest(
                itemID: selectedItemID,
                alignment: .top
            )
        )
    }

    func testBeginEditingNoteShouldKeepSelectionAndSeedExistingNote() {
        let viewModel = PopupViewModel()
        let items = makeItems(count: 6, noteIndex: 2, note: "已有备注")
        viewModel.loadForDisplay(items)
        viewModel.consumePendingScrollRequest()

        let target = viewModel.items[2]
        viewModel.beginEditingNote(for: target.id)

        XCTAssertEqual(viewModel.selectedIndex, 2)
        XCTAssertEqual(viewModel.editingItemID, target.id)
        XCTAssertEqual(viewModel.editingNoteText, "已有备注")
    }

    func testPrepareForDismissalShouldClearEditingAndScrollState() {
        let viewModel = PopupViewModel()
        viewModel.loadForDisplay(makeItems(count: 6))

        let target = viewModel.items[1]
        viewModel.beginEditingNote(for: target.id)
        viewModel.prepareForDismissal()

        XCTAssertNil(viewModel.editingItemID)
        XCTAssertEqual(viewModel.editingNoteText, "")
        XCTAssertNil(viewModel.pendingScrollRequest)
    }

    private func makeItems(count: Int, noteIndex: Int? = nil, note: String? = nil) -> [ClipboardItem] {
        let baseDate = Date(timeIntervalSince1970: 1_000)
        return (0..<count).map { index in
            ClipboardItem(
                text: "item-\(index)",
                copiedAt: baseDate.addingTimeInterval(TimeInterval(count - index)),
                note: index == noteIndex ? note : nil
            )
        }
    }
}
#else
struct PopupViewModelTestsUnavailable {}
#endif
