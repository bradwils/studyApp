import SwiftUI

extension Font {
	//Retrieve vertical point size current font, and then return a scaled font of size * factor all running through the accessability scaling pipeline [UIFontMetrics]
	//USAGE:
	//Text("myText")
	//	.font(.scaled(.body, by: 1.5))
	//RETURNS: .body * 1.5 & * relevant accessability scasle
	static func scaled(_ style: UIFont.TextStyle, by factor: CGFloat) -> Font {
		let baseSize = UIFont.preferredFont(forTextStyle: style).pointSize
		let scaledUIFont = UIFontMetrics(forTextStyle: style).scaledFont(
			for: UIFont.systemFont(ofSize: baseSize * factor)
		)
		return Font(scaledUIFont)
	}
}
