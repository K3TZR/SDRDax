//
//  SettingsView.swift
//  SDRDax
//
//  Created by Douglas Adams on 3/19/24.
//

import ComposableArchitecture
import SwiftUI

struct SDRDaxSettingsView: View {
  @Bindable var store: StoreOf<SDRDaxSettingsCore>

  var body: some View {
    VStack(alignment: .leading) {
      Picker(selection: $store.smartlinkEnabled, label: Text("Connection")) {
        Text("Local").tag(false)
        Text("Smartlink").tag(true)
      }
      .pickerStyle(.radioGroup)
      .horizontalRadioGroupLayout()

      Picker(selection: $store.autoStartEnabled, label: Text("Mode")) {
        Text("Auto").tag(true)
        Text("Manual").tag(false)
      }
      .pickerStyle(.radioGroup)
      .horizontalRadioGroupLayout()

      VStack(alignment: .leading) {
        Toggle("Enable TX", isOn: $store.txEnabled)
        Toggle("Enable MIC", isOn: $store.micEnabled)
        Toggle("Enable RX", isOn: $store.rxEnabled)
        Toggle("Enable IQ", isOn: $store.iqEnabled)
      }.frame(width: 300)
    }
  }
}

#Preview {
  SDRDaxSettingsView(store: Store(initialState: SDRDaxSettingsCore.State(iqEnabled: Shared(true),
                                                                         micEnabled: Shared(true),
                                                                         rxEnabled: Shared(true),
                                                                         txEnabled: Shared(true), 
                                                                         autoStartEnabled: Shared(false),
                                                                         smartlinkEnabled: Shared(true))) {
    SDRDaxSettingsCore()
  })
}
