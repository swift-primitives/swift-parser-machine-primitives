import Machine_Value_Primitives
import Parser_Machine_Memoization_Primitives
import Tagged_Primitives_Test_Support
import Testing

@Suite
struct `Parser.Machine.Memoization.Table Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Parser.Machine.Memoization.Table Tests`.Unit {
    @Test
    func `new table is empty`() {
        let table = Parser.Machine.Memoization.Table<Int>()
        #expect(table.isEmpty)
        #expect(table.count == 0)
    }

    @Test
    func `new table with capacity is empty`() {
        let table = Parser.Machine.Memoization.Table<Int>(capacity: 100)
        #expect(table.isEmpty)
        #expect(table.count == 0)
    }

    @Test
    func `store and lookup returns entry`() {
        var table = Parser.Machine.Memoization.Table<Int>()
        let key = Parser.Machine.Memoization.Key<Int>(position: 0, node: 1)
        let entry = Parser.Machine.Memoization.Entry<Int>.failure

        table.store(entry, for: key)
        let result = table.lookup(key)
        #expect(result != nil)
    }

    @Test
    func `count reflects stored entries`() {
        var table = Parser.Machine.Memoization.Table<Int>()
        let key1 = Parser.Machine.Memoization.Key<Int>(position: 0, node: 1)
        let key2 = Parser.Machine.Memoization.Key<Int>(position: 1, node: 1)

        table.store(.failure, for: key1)
        table.store(.failure, for: key2)
        #expect(table.count == 2)
    }

    @Test
    func `clear removes all entries`() {
        var table = Parser.Machine.Memoization.Table<Int>()
        let key = Parser.Machine.Memoization.Key<Int>(position: 0, node: 1)
        table.store(.failure, for: key)
        #expect(!table.isEmpty)

        table.clear()
        #expect(table.isEmpty)
        #expect(table.count == 0)
    }
}

// MARK: - Edge Cases

extension `Parser.Machine.Memoization.Table Tests`.`Edge Case` {
    @Test
    func `lookup for missing key returns nil`() {
        let table = Parser.Machine.Memoization.Table<Int>()
        let key = Parser.Machine.Memoization.Key<Int>(position: 0, node: 1)
        #expect(table.lookup(key) == nil)
    }

    @Test
    func `store overwrites existing entry for same key`() {
        var table = Parser.Machine.Memoization.Table<Int>()
        let key = Parser.Machine.Memoization.Key<Int>(position: 0, node: 1)

        table.store(.failure, for: key)
        #expect(table.lookup(key)?.isFailure == true)

        let value = Parser.Machine.Value.make(42)
        table.store(.success(output: value, end: 1), for: key)
        #expect(table.lookup(key)?.isSuccess == true)
        #expect(table.count == 1)
    }

    @Test
    func `invalidate from position removes entries at or after`() {
        var table = Parser.Machine.Memoization.Table<Int>()
        let key0 = Parser.Machine.Memoization.Key<Int>(position: 0, node: 1)
        let key5 = Parser.Machine.Memoization.Key<Int>(position: 5, node: 1)
        let key10 = Parser.Machine.Memoization.Key<Int>(position: 10, node: 1)

        table.store(.failure, for: key0)
        table.store(.failure, for: key5)
        table.store(.failure, for: key10)
        #expect(table.count == 3)

        table.invalidate(from: 5)
        #expect(table.count == 1)
        #expect(table.lookup(key0) != nil)
        #expect(table.lookup(key5) == nil)
        #expect(table.lookup(key10) == nil)
    }

    @Test
    func `invalidate with edit removes overlapping entries`() {
        var table = Parser.Machine.Memoization.Table<Int>()
        let key0 = Parser.Machine.Memoization.Key<Int>(position: 0, node: 1)
        let key5 = Parser.Machine.Memoization.Key<Int>(position: 5, node: 1)
        let key15 = Parser.Machine.Memoization.Key<Int>(position: 15, node: 1)

        // Failure entries: kept only if position < edit.start
        table.store(.failure, for: key0)
        table.store(.failure, for: key5)
        table.store(.failure, for: key15)
        #expect(table.count == 3)

        let edit = Parser.Machine.Memoization.Edit<Int>(start: 5, oldEnd: 10, newEnd: 8)
        table.invalidate(edit)

        // key0 (position 0): kept (0 < 5)
        // key5 (position 5): removed (5 >= 5)
        // key15 (position 15): removed for failure (15 >= 5); would be kept for success if end <= 5
        #expect(table.lookup(key0) != nil)
        #expect(table.lookup(key5) == nil)
    }
}
