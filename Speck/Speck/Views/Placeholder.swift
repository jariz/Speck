//
//  Placeholder.swift
//  Speck
//
//  Created by Jari on 06/05/2023.
//

import SwiftUI

struct Placeholder: View {
    var body: some View {
        EmptyView().skeleton(with: true).shape(type: .rectangle)
    }
}

struct Placeholder_Previews: PreviewProvider {
    static var previews: some View {
        Placeholder()
    }
}
