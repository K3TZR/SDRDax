//
//  TopButtonsView.swift
//  SDRDax
//
//  Created by Douglas Adams on 1/30/24.
//

import ComposableArchitecture
import SwiftUI

import SharedFeature

public struct TopButtonsView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
    
  var buttonText: String {
    switch store.connectionState {
    case .disconnected: "Start"
    case .connected: "Stop"
    default: "---"
    }
  }

  var buttonDisable: Bool {
    guard store.directEnabled || store.localEnabled || store.smartlinkEnabled else { return true }
    switch store.connectionState {
    case .disconnected: return false
    case .connected:  return false
    default: return true
    }
  }

  public var body: some View {
    
    HStack(spacing: 10) {
      // Connection initiation
      Button(buttonText) {
        store.send(.startStopButtonTapped)
      }
      .background(Color(.green).opacity(0.2))
      .frame(width: 60)
      .disabled(buttonDisable)
      
      // Connection types
      ControlGroup {
        Toggle(isOn: $store.directEnabled) {
          Text("Direct") }
        Toggle(isOn: $store.localEnabled) {
          Text("Local") }
        Toggle(isOn: $store.smartlinkEnabled) {
          Text("Smartlink") }
      }
      .frame(width: 170)
      .disabled(store.connectionState != .disconnected)
      
      Toggle("Default", isOn: $store.useDefaultEnabled)
        .disabled( store.connectionState != .disconnected )
        .toggleStyle(.button)
    }
  }
}

//#Preview {
//  Grid(alignment: .leading, horizontalSpacing: 20) {
//    TopButtonsView(store: Store(initialState: SDRDaxCore.State(daxPanelOptions: DaxPanelOptions(rawValue: 0))) {
//      SDRDaxCore()
//    })
//  }
//  .frame(width: 320)
//}
