//
//  CustomEffect.swift
//  AnimateTextExample
//
//  Created by jasu on 2022/02/07.
//  Copyright (c) 2022 jasu All rights reserved.
//

import SwiftUI
import AnimateText

struct CustomEffect: ATTextAnimateEffect {
    
    var data: ATElementData
    var userInfo: Any?
    
    var color: Color = .red
    
    public init(_ data: ATElementData, _ userInfo: Any?) {
        self.data = data
        self.userInfo = userInfo
        if let info = userInfo as? [String: Any] {
            color = info["color"] as! Color
        }
    }
    
    var customSpringAnimation1: Animation {
        .spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0.9)
    }
    
    var customSpringAnimation2: Animation {
        .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.9)
    }
    
    let elementDelay: TimeInterval = 0.1
    
    let lineDelay: TimeInterval = 2.0
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(data.value)
            content
                .foregroundColor(color)
                .opacity(data.invValue)
                .overlay(
                    Rectangle().fill(Color.clear)
                        .border(Color.accentColor.opacity(0.5), width: 1)
                )
        }
        .animation(customSpringAnimation1.delay(Double(data.elementIndex) * elementDelay + Double(data.lineIndex) * lineDelay),
        value: data.value)
        .scaleEffect(data.scale, anchor: .bottom)
        .rotationEffect(Angle(degrees: -360 * data.invValue))
        .animation(customSpringAnimation2.delay(Double(data.elementIndex) * elementDelay + Double(data.lineIndex) * lineDelay), value: data.value)
    }
}

struct CustomEffect_Previews: PreviewProvider {
    static var previews: some View {
        ATAnimateTextPreview<CustomEffect>()
    }
}
