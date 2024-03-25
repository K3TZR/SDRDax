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
    Grid(alignment: .leading) {
      GridRow {
        Text("Connection")
        Picker("", selection: $store.smartlinkEnabled) {
          Text("Local").tag(false)
          Text("Smartlink").tag(true)
        }
        .labelsHidden()
        .pickerStyle(.radioGroup)
        .horizontalRadioGroupLayout()
      }

      GridRow {
        Text("Mode")
        Picker("", selection: $store.autoStartEnabled) {
          Text("Auto").tag(true)
          Text("Manual").tag(false)
        }
        .labelsHidden()
        .pickerStyle(.radioGroup)
        .horizontalRadioGroupLayout()
      }

      GridRow {
        Text("Reduced Bandwidth")
        Toggle("", isOn: $store.reducedBandwidth)
          .labelsHidden()
      }

      Spacer()
        GridRow {
          Toggle("Enable TX", isOn: $store.txEnabled)
          Toggle("Enable MIC", isOn: $store.micEnabled)
        }
        GridRow {
          Toggle("Enable RX", isOn: $store.rxEnabled)
          Toggle("Enable IQ", isOn: $store.iqEnabled)
        }
      Spacer()
    }
  }
}

#Preview {
  SDRDaxSettingsView(store: Store(initialState: SDRDaxSettingsCore.State(iqEnabled: Shared(true),
                                                                         micEnabled: Shared(true),
                                                                         rxEnabled: Shared(true),
                                                                         txEnabled: Shared(true), 
                                                                         autoStartEnabled: Shared(false),
                                                                         reducedBandwidth: Shared(false),
                                                                         smartlinkEnabled: Shared(true))) {
    SDRDaxSettingsCore()
  })
  .frame(width: 300, height: 140)
  .padding()
}
