//
//  AnimateText.swift
//  AnimateText
//
//  Created by jasu on 2022/02/05.
//  Copyright (c) 2022 jasu All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
//  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftUI

/// A view that animates binding text. Passing the effect type as a generic.
public struct AnimateText<E: ATTextAnimateEffect>: View {
    
    /// Binding the text to be expressed.
    @Binding private var text: String
    
    var font: UIFont
    
    /// The type used to split text.
    var type: ATUnitType = .letters
    
    /// Custom user info for the effect.
    var userInfo: Any? = nil
    
    @State private var height: CGFloat = 0
    
    /// Split text into individual elements.
    @State private var elements: Array<String> = []
    
    /// A value used for animation processing. A value between 0 and 1.
    @State private var value: Double = 0
    
    /// Used to re-create the view.
    @State private var toggle: Bool = false
    
    /// The first text is exposed as the default text.
    @State private var isChanged: Bool = false
    
    /// The size of the Text view.
    @State private var size: CGSize = .zero
    
    /// initialize `AnimateText`
    ///
    /// - Parameters:
    ///   - text: Bind the text you want to express.
    ///   - font: The font to use on the text. This is also used to help split lines.
    ///   - type: The type used to split text. `ATUnitType`
    ///   - userInfo: Custom user info for the effect.
    public init(_ text: Binding<String>,
                font: UIFont,
                type: ATUnitType = .letters,
                userInfo: Any? = nil) {
        _text = text
        self.font = font
        self.type = type
        self.userInfo = userInfo
    }
    
    public var body: some View {
        ZStack(alignment: .leading) {
            if !isChanged {
                Text(text)
                    .takeSize($size)
            .multilineTextAlignment(.center)
            } else {
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(splitElements(containerWidth: geometry.size.width).enumerated()), id: \.offset) { lineIndex, lineElements in
                            HStack {
                                Spacer()
                                HStack(spacing: 0) {
                                    ForEach(Array(lineElements.enumerated()), id: \.offset) { elementIndex, element in
                                        let data = ATElementData(element: element,
                                                                 type: self.type,
                                                                 elementIndex: elementIndex,
                                                                 lineIndex: lineIndex,
                                                                 count: lineElements.count,
                                                                 value: value,
                                                                 size: size)
                                        if toggle {
                                            Text(element).modifier(E(data, userInfo))
                                        } else {
                                            Text(element).modifier(E(data, userInfo))
                                        }
                                    }
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                        withAnimation {
                            height = getHeight(size: geometry.size)
                        }
                    }
                    .onChange(of: geometry.size) { newSize in
                        withAnimation {
                            height = getHeight(size: newSize)
                        }
                    }
                    .onChange(of: text) { _ in
                        withAnimation {
                            height = getHeight(size: geometry.size)
                        }
                    }
                }
                .padding(.bottom, 40)
                .frame(height: height)
            }
        }
        .font(Font(font))
        .onChange(of: text) { _ in
            withAnimation {
                value = 0
                getText(text)
                toggle.toggle()
            }
            self.isChanged = true
            DispatchQueue.main.async {
                value = 1
            }
        }
    }
    
    private func getHeight(size: CGSize) -> CGFloat {
        text.size(withinRect: size.width, font: font).height
    }
    
    private func getText(_ text: String) {
        // Use our own line breaks based on text width, not provided ones.
        var text = text.replacingOccurrences(of: "\n", with: " ")
        
        switch type {
        case .letters:
            self.elements = text.map { String($0) }
        case .words:
            var elements = [String]()
            text.components(separatedBy: " ").forEach{
                elements.append($0)
                elements.append(" ")
            }
            elements.removeLast()
            self.elements = elements
        }
    }

func splitElements(containerWidth: CGFloat) -> [[String]] {
        var lines: [[String]] = [[]]
        var currentLineIndex = 0
        var remainingWidth: CGFloat = containerWidth
        var currentWord: String = ""
        var words: [String] = []
        
        // build words
        for (index, element) in elements.enumerated() {
            if element == " " {
                currentWord.append(element)
                words.append(currentWord)
                currentWord = ""
            } else {
                // Add the element to the current word
                currentWord.append(element)
                
                // Check if this is the last element
                if index == elements.count - 1 {
                    words.append(currentWord)
                }
            }
        }
        
        // build sentences, split words into elements
        for (index, word) in words.enumerated() {
            var letters: [String] = []
            for char in word {
                letters.append(String(char))
            }

            let wordWidth = word.getTextWidth(font: font)
            
            if index == 0 {
                lines[currentLineIndex].append(contentsOf: letters)
                remainingWidth -= wordWidth
            } else {
                if wordWidth > remainingWidth {
                    currentLineIndex += 1
                    lines.append(letters)
                    remainingWidth = containerWidth - wordWidth
                } else {
                    lines[currentLineIndex].append(contentsOf: letters)
                    remainingWidth -= wordWidth
                }
            }
        }
        return lines
    }
}

struct AnimateText_Previews: PreviewProvider {
    static var previews: some View {
        ATAnimateTextPreview<ATRandomTypoEffect>()
    }
}

extension String {
    func getTextWidth(font: UIFont) -> CGFloat {
        size(withinRect: .greatestFiniteMagnitude, font: font).width
    }
    
    func getTextHeight(font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (self as NSString).size(withAttributes: attributes)
        return size.width
    }
        
    func size(withinRect width: CGFloat, font: UIFont) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping // Ensure text wraps within bounds
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let boundingBox = self.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: NSStringDrawingContext())
        
        return CGSize(width: ceil(boundingBox.width), height: ceil(boundingBox.height)) // Use ceil to avoid fractional sizes
    }
}
