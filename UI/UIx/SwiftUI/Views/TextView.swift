// Copied from https://gist.github.com/shaps80/8a3170160f80cfdc6e8179fa0f5e1621

import SwiftUI

@available(iOS 13.0, *)
public struct TextView: View {
    @Binding var text: String
    @Binding var editing: Bool
    private var font: UIFont = UIFont.preferredFont(forTextStyle: .body)

    public init(_ text: Binding<String>, editing: Binding<Bool>) {
        _text = text
        _editing = editing
    }

    public var body: some View {
        SwiftUITextView(text: $text,
                        editing: $editing,
                        font: font)
    }
}

@available(iOS 13.0, *)
extension TextView {
    func font(_ textStyle: UIFont.TextStyle) -> Self {
        font(UIFont.preferredFont(forTextStyle: textStyle))
    }

    func font(_ font: UIFont) -> Self {
        var view = self
        view.font = font
        return view
    }
}

@available(iOS 13.0, *)
private struct SwiftUITextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var editing: Bool
    let font: UIFont

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
        // move it to the next run loop to fix an iOS 13 issue
        DispatchQueue.main.async {
            if editing {
                textView.becomeFirstResponder()
            } else {
                textView.resignFirstResponder()
            }
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SwiftUITextView

        init(_ textView: SwiftUITextView) {
            parent = textView
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.editing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.editing = false
        }
    }
}

// swiftlint:disable line_length
@available(iOS 13.0, *)
struct TextView_Previews: PreviewProvider {
    @State static var editing: Bool = true

    static var previews: some View {
        VStack {
            TextView(.constant("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."),
                     editing: $editing)
                .font(UIFont.TextStyle.body)
                .border(Color.red, width: 1)
                .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}

// swiftlint:enable line_length
