import Parser_Machine_Memoization_Primitives
import Testing

@Suite("Parser.Machine.Memoization.Edit")
struct ParserMachineMemoizationEditTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension ParserMachineMemoizationEditTests.Unit {
    @Test
    func `init stores start, oldEnd, and newEnd`() {
        let edit = Parser.Machine.Memoization.Edit<Int>(start: 5, oldEnd: 10, newEnd: 8)
        #expect(edit.start == 5)
        #expect(edit.oldEnd == 10)
        #expect(edit.newEnd == 8)
    }

    @Test
    func `insert at position creates edit with same start and oldEnd`() {
        let insert = Parser.Machine.Memoization.Edit<Int>.insert(at: 10, length: 3)
        #expect(insert.start == 10)
        #expect(insert.oldEnd == 10)
        #expect(insert.newEnd == 13)
    }

    @Test
    func `delete from range creates edit with newEnd equal to start`() {
        let delete = Parser.Machine.Memoization.Edit<Int>.delete(from: 10, to: 15)
        #expect(delete.start == 10)
        #expect(delete.oldEnd == 15)
        #expect(delete.newEnd == 10)
    }
}

// MARK: - Edge Cases

extension ParserMachineMemoizationEditTests.`Edge Case` {
    @Test
    func `insert with zero length is a no-op edit`() {
        let edit = Parser.Machine.Memoization.Edit<Int>.insert(at: 5, length: 0)
        #expect(edit.start == 5)
        #expect(edit.oldEnd == 5)
        #expect(edit.newEnd == 5)
    }

    @Test
    func `delete from same position is a no-op edit`() {
        let edit = Parser.Machine.Memoization.Edit<Int>.delete(from: 5, to: 5)
        #expect(edit.start == 5)
        #expect(edit.oldEnd == 5)
        #expect(edit.newEnd == 5)
    }
}
