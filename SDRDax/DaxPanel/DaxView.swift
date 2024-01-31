//
//  DaxView.swift
//  
//
//  Created by Douglas Adams on 11/29/23.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct DaxView: View {
  @Bindable var store: StoreOf<SDRDax>
  
  @Environment(ApiModel.self) private var api
  
  @State var txIsOn = false
  @State var micIsOn = false
  @State var rxIsOn = true
  @State var iqIsOn = false
  
  @State var daxRxChannels = [1, 2, 3, 4]
  @State var daxIqChannels = [1, 2, 3, 4]

  private func toggleOption(_ option: DaxPanelOptions) {
    if store.daxPanelOptions.contains(option) {
      store.daxPanelOptions.remove(option)
    } else {
      store.daxPanelOptions.insert(option)
    }
  }
  
  public var body: some View {
    
    VStack(alignment: .center) {
      HStack {
        ControlGroup {
          Toggle("Tx", isOn: Binding(get: { store.daxPanelOptions.contains(.tx) }, set: {_,_  in toggleOption(.tx) } ))
          Toggle("Mic", isOn: Binding(get: { store.daxPanelOptions.contains(.mic)  }, set: {_,_  in toggleOption(.mic) } ))
          Toggle("Rx", isOn: Binding(get: { store.daxPanelOptions.contains(.rx)  }, set: {_,_  in toggleOption(.rx) } ))
          Toggle("IQ", isOn: Binding(get: { store.daxPanelOptions.contains(.iq)  }, set: {_,_  in toggleOption(.iq) } ))
        }
//        .frame(width: 280)
      }
      Divider().background(Color(.blue))

      Spacer()
      
      ScrollView {
        VStack(spacing: 20) {
          if store.daxPanelOptions.contains(.tx) { DaxTxView(store: store, devices: AudioDevice.getDevices()) }
          if store.daxPanelOptions.contains(.mic) { DaxMicView(store: store, devices: AudioDevice.getDevices()) }
          if store.daxPanelOptions.contains(.rx) { DaxRxView(store: store, devices: AudioDevice.getDevices()) }
          if store.daxPanelOptions.contains(.iq) { DaxIqView(store: store, devices: AudioDevice.getDevices()) }
        }
      }.scrollIndicators(.visible, axes: .vertical)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  DaxView(store: Store(initialState: SDRDax.State(daxPanelOptions: DaxPanelOptions(rawValue: 0))) {
    SDRDax()
  })
    .environment(ApiModel.shared)
    .frame(width: 320)
}
