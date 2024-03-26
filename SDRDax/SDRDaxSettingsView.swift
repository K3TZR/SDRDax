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
      Toggle("Enable TX", isOn: $store.txEnabled)
      Toggle("Enable MIC", isOn: $store.micEnabled)
      Toggle("Enable RX", isOn: $store.rxEnabled)
      Toggle("Enable IQ", isOn: $store.iqEnabled)
      Spacer()
    }
  }
}

#Preview {
  SDRDaxSettingsView(store: Store(initialState: SDRDaxSettingsCore.State(iqEnabled: Shared(true),
                                                                         micEnabled: Shared(true),
                                                                         rxEnabled: Shared(true),
                                                                         txEnabled: Shared(true))) {
    SDRDaxSettingsCore()
  })
  .frame(width: 300, height: 100)
  .padding()
}
