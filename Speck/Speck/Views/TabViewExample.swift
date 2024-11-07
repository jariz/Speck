//
//  TabViewExample.swift
//  Speck
//
//  Created by Jari on 22/10/2024.
//

import SwiftUI


struct TabViewExample: View {
    @State private var tabs: [TabItem] = [
        TabItem(title: "Tab 1"),
        TabItem(title: "Tab 2"),
        TabItem(title: "Tab 3")
    ]
    
    @State private var selectedTab: TabItem?
    
    var body: some View {
        VStack {
            // Tab Bar
            HStack {
                ForEach(tabs) { tab in
                    TabButton(tab: tab, selectedTab: $selectedTab, closeAction: closeTab)
                        .onDrag {
                            return NSItemProvider(object: tab.id.uuidString as NSString)
                        }
//                        .onDrop(of: [UTType.text], delegate: TabDropDelegate(item: tab, currentTabs: $tabs, selectedTab: $selectedTab))
                }
            }
            .padding()
            
            Divider()
            
            // Content of the selected tab
            if let selectedTab = selectedTab {
                Text("Content for \(selectedTab.title)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Select a tab")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            selectedTab = tabs.first
        }
    }
    
    private func closeTab(_ tab: TabItem) {
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
            // Optionally select another tab after closing
            if tabs.isEmpty {
                selectedTab = nil
            } else if selectedTab == tab {
                selectedTab = tabs.first
            }
        }
    }
}

struct TabButton: View {
    var tab: TabItem
    @Binding var selectedTab: TabItem?
    var closeAction: (TabItem) -> Void
    
    var body: some View {
        HStack {
            Text(tab.title)
            
            Button(action: {
                closeAction(tab)
            }) {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(BorderlessButtonStyle()) // Ensure the button works inside an HStack
        }
        .padding(8)
        .background(selectedTab == tab ? Color.accentColor : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            selectedTab = tab
        }
    }
}

struct TabDropDelegate: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
//        let fromIndex = currentTabs.firstIndex { $0.id == info.itemProviders(for: [UTType.text]).first?.loadObject(ofClass: NSString.self, com) }
//        let toIndex = currentTabs.firstIndex(of: item)
//        
//        if let fromIndex = fromIndex, let toIndex = toIndex, fromIndex != toIndex {
//            withAnimation {
//                let movedTab = currentTabs.remove(at: fromIndex)
//                currentTabs.insert(movedTab, at: toIndex)
//            }
//        }
        return false
    }
    
    let item: TabItem
    @Binding var currentTabs: [TabItem]
    @Binding var selectedTab: TabItem?

}


struct TabItem: Identifiable, Equatable {
    let id = UUID()       // Unique identifier for each tab
    var title: String     // Title of the tab
    var icon: String?     // Optional: SF Symbol icon for the tab
//    var content: AnyView  // Content displayed when the tab is selected
    
    // Optional: Add more properties as needed
    var isClosable: Bool = true  // Whether the tab can be closed or not
    
    // Equatable conformance to compare tabs
    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        return lhs.id == rhs.id
    }
}
