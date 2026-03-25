//
//  HexColoursTests.swift
//  studyAppTests
//

import Testing
import SwiftUI
@testable import studyApp

struct HexColoursTests {

    // MARK: - init?(hex:)

    @Test("8-char hex with partial alpha initialises correctly")
    func initHex8WithAlpha() {
        let hex = Color(hex: "#FF000080")?.toHex()
        #expect(hex == "#FF000080")
    }

    @Test("8-char fully opaque hex returns 6-char output")
    func initHex8FullyOpaque() {
        #expect(Color(hex: "#0000FFFF")?.toHex() == "#0000FF")
    }

    @Test("Hex parsing is case-insensitive")
    func initHexCaseInsensitive() {
        #expect(Color(hex: "#E06910")?.toHex() == Color(hex: "#e06910")?.toHex())
    }

    @Test("Hex with leading/trailing whitespace is accepted")
    func initHexTrimsWhitespace() {
        #expect(Color(hex: "  #FF0000  ")?.toHex() == "#FF0000")
    }

    @Test("Invalid hex strings return nil", arguments: ["", "#FFF", "#FF00FF0", "#ZZZZZZ"])
    func initHexInvalidInput(hex: String) {
        #expect(Color(hex: hex) == nil)
    }

    // MARK: - toHex()

    @Test("Zero opacity produces correct 8-char hex with 00 alpha")
    func toHexZeroOpacity() {
        #expect(Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 0.0).toHex() == "#FF000000")
    }

    @Test("Alpha byte is encoded correctly at 50% opacity")
    func toHexHalfOpacity() {
        // 128/255 ≈ 0x80
        #expect(Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 128.0 / 255.0).toHex() == "#0000FF80")
    }

    // MARK: - Round-trip

    @Test("6-char hex round-trips through init and toHex")
    func roundTrip6Char() {
        let original = "#E06910"
        let color = Color(hex: original)
        #expect(color?.toHex() == original)
    }

    @Test("8-char hex with partial alpha round-trips")
    func roundTrip8Char() {
        let original = "#E0691080"
        let color = Color(hex: original)
        let result = color?.toHex()
        #expect(result == original)
    }
}
