//
//  SpinnerView.swift
//  SDRDax
//
//  Created by Douglas Adams on 2/22/24.
//

import ComposableArchitecture
import SwiftUI

import ListenerFeature

struct SpinnerView: View {
//  @Bindable var store: StoreOf<SpinnerFeature>
//  
//  public init(store: StoreOf<SpinnerFeature>) {
//    self.store = store
//  }

//  @Environment(\.dismiss) var dismiss
//  @Environment(ListenerModel.self) var listenerModel

  var body: some View {
    VStack {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
      Text("Waiting for the Station")
    }
//      .task {
//        while ListenerModel.shared.stations[id: store.selection] == nil {
//          print("Waiting for \(store.selection), stations = \(ListenerModel.shared.stations)")
//          sleep(1)
//        }
//        dismiss()
//      }
      .frame(width: 100, height: 100)
  }
}

#Preview {
  SpinnerView()
}
