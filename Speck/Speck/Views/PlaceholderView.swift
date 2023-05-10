//
//  Placeholder.swift
//  Speck
//
//  Created by Jari on 06/05/2023.
//

import SwiftUI

struct PlaceholderView: View {
    var body: some View {
        EmptyView()
            .skeleton(with: true)
            .shape(type: .rectangle)
            .appearance(type: .gradient(color: .white, background: .gray, angle: 180))
    }
}

struct Placeholder_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderView()
    }
}
