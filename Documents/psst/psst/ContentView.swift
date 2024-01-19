//
//  ContentView.swift
//  psst
//
//  Created by Matthew Brown on 1/16/24.
//

import SwiftUI

var messageList = [uiMessage(isUser: false, message: "yo"), uiMessage(isUser: true, message: "hello")]

struct uiMessage: Identifiable{
    let id = UUID()
    let isUser: Bool
    let message: String
}

struct ContentView: View {
    var body: some View {
        VStack {
            ForEach(messageList) {
                item in
                
                Text(item.message).fontWeight(.medium).foregroundColor(Color.white).padding().background(RoundedRectangle(cornerRadius: 25).fill(item.isUser == true ? Color.gray : Color.blue)).frame(maxWidth: .infinity, alignment: item.isUser == true ? .leading : .trailing)
            }
        }.padding()
        Spacer()
        HStack {
            Spacer()
            Text("This is at the bottom").padding().background(RoundedRectangle(cornerRadius: 10).fill(Color.green)) // Example content in HStack
    .foregroundColor(.white)
                        
                        Spacer()
                    }    }
}

#Preview {
    ContentView()
}
