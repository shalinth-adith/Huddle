//
//  ContentView.swift
//  Huddle
//
//  Created by shalinth adithyan on 19/11/25.
//

import SwiftUI
import FirebaseFirestore

  struct ContentView: View {
      @State private var testMessage = "Testing Firebase..."

      var body: some View {
          VStack(spacing: 20) {
              Image(systemName: "house.fill")
                  .imageScale(.large)
                  .foregroundStyle(.orange)
                  .font(.system(size: 60))

              Text("Huddle")
                  .font(.largeTitle)
                  .fontWeight(.bold)

              Text(testMessage)
                  .foregroundStyle(.secondary)

              Button("Test Firebase") {
                  testFirebase()
              }
              .buttonStyle(.borderedProminent)
          }
          .padding()
      }

      func testFirebase() {
          let db = Firestore.firestore()
          db.collection("test").addDocument(data: ["message": "Hello from Huddle!"]) { error in
              if let error = error {
                  testMessage = "Error: \(error.localizedDescription)"
              } else {
                  testMessage = "✅ Firebase connected!"
              }
          }
      }
  }

  #Preview {
      ContentView()
  }
