import SwiftUI

enum StrandTheme {
    static let paper = Color(red: 0.953, green: 0.933, blue: 0.902)
    static let card = Color(red: 0.984, green: 0.973, blue: 0.953)
    static let ink = Color(red: 0.110, green: 0.098, blue: 0.082)
    static let copper = Color(red: 0.769, green: 0.384, blue: 0.176)
    static let teal = Color(red: 0.165, green: 0.420, blue: 0.373)
    static let line = Color(red: 0.886, green: 0.851, blue: 0.800)
}

struct StrandCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StrandTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(StrandTheme.line, lineWidth: 1)
            )
    }
}

struct ChoiceButton: View {
    let title: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(prominent ? StrandTheme.copper : StrandTheme.teal)
    }
}
