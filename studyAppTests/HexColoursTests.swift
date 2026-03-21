//
//  HexColoursTests.swift
//  studyAppTests
//

import Testing
import SwiftUI
@testable import studyApp

struct HexColoursTests {

    // MARK: - Color(hex:) – valid inputs

    @Test("6-char hex (no alpha) initialises with full opacity")
    func initHex6Char() {
        let color = Color(hex: "#FF0000")
        #expect(color != nil)
        #expect(color?.toHex() == "#FF0000")
    }

    @Test("8-char hex with partial alpha initialises correctly")
    func initHex8WithAlpha() {
        let color = Color(hex: "#FF000080")
        #expect(color != nil)
        #expect(color?.toHex() == "#FF000080")
    }

    @Test("8-char fully opaque hex (alpha FF) returns 6-char output from toHex")
    func initHex8FullyOpaque() {
        #expect(Color(hex: "#0000FFFF")?.toHex() == "#0000FF")
    }

    @Test("Hex parsing is case-insensitive")
    func initHexCaseInsensitive() {
        #expect(Color(hex: "#E06910")?.toHex() == Color(hex: "#e06910")?.toHex())
    }

    @Test("Hex with leading and trailing whitespace is accepted")
    func initHexTrimsWhitespace() {
        #expect(Color(hex: "  #FF0000  ")?.toHex() == "#FF0000")
    }

    // MARK: - Color(hex:) – invalid inputs

    @Test("Invalid hex strings return nil", arguments: ["", "#FFF", "#FF00FF0", "#ZZZZZZ"])
    func initHexInvalidInput(hex: String) {
        #expect(Color(hex: hex) == nil)
    }

    // MARK: - toHex()

    @Test("Fully opaque color encodes as 6-char hex")
    func toHexFullyOpaque() {
        let color = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(color.toHex() == "#FF0000")
    }

    @Test("Zero-opacity color encodes as 8-char hex with 00 alpha")
    func toHexZeroOpacity() {
        let color = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(color.toHex() == "#FF000000")
    }

    @Test("50% opacity encodes alpha byte as 80 hex")
    func toHexHalfOpacity() {
        // 128/255 ≈ 0x80
        let color = Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 128.0 / 255.0)
        #expect(color.toHex() == "#0000FF80")
    }

    // MARK: - Round-trip

    @Test("6-char hex round-trips through init and toHex")
    func roundTrip6Char() {
        let original = "#E06910"
        #expect(Color(hex: original)?.toHex() == original)
    }

    @Test("8-char hex with partial alpha round-trips")
    func roundTrip8Char() {
        let original = "#E0691080"
        #expect(Color(hex: original)?.toHex() == original)
    }
}
