//
//  RoundedButton.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//

import SwiftUI

struct RoundedButton: View {
    
    var width: CGFloat
    var height: CGFloat
    var text: String
    
    var completion: () -> ()
    
    var body: some View {
        Button {
            completion()
        } label: {
            ZStack {
                Rectangle()
                    .frame(width: width, height: height)
                    .cornerRadius(28)
                    .foregroundStyle(.softBlue)
                    .shadow(color: .white, radius: 1)
                    .shadow(color: .white, radius: 1)
                    .shadow(color: .blue, radius: 5)
                Text(text)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    RoundedButton(width: 200, height: 60, text: "Add Product"){}
        .preferredColorScheme(.dark)
}
