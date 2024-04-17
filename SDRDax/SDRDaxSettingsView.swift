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
      Spacer()
      Toggle("Enable TX", isOn: $store.appSettings.txEnabled)
      Toggle("Enable MIC", isOn: $store.appSettings.micEnabled)
      Toggle("Enable RX", isOn: $store.appSettings.rxEnabled)
      Toggle("Enable IQ", isOn: $store.appSettings.iqEnabled)
      Spacer()
    }
  }
}

#Preview {
//  SDRDaxSettingsView(store: Store(initialState: SDRDaxSettingsCore.State(iqEnabled: Shared(true),
//                                                                         micEnabled: Shared(true),
//                                                                         rxEnabled: Shared(true),
//                                                                         txEnabled: Shared(true))) {
  SDRDaxSettingsView(store: Store(initialState: SDRDaxSettingsCore.State()) {
    SDRDaxSettingsCore()
  })
  .frame(width: 300, height: 100)
  .padding()
}
