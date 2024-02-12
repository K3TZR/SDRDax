//
//  SDRDaxView.swift
//  SDRDax
//
//  Created by Douglas Adams on 1/30/24.
//

import ComposableArchitecture
import SwiftUI

import ClientFeature
import DirectFeature
import FlexApiFeature
import LoginFeature
import PickerFeature
import SharedFeature

struct SDRDaxView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
      
  var body: some View {
    VStack(alignment: .leading) {
      TopButtonsView(store: store)
      DaxSelectionView(store: store)
      Spacer()
    }
    
    // Alert
    .alert($store.scope(state: \.showAlert, action: \.alert))
    
    // Client sheet
    .sheet( item: self.$store.scope(state: \.showClient, action: \.client)) {
      store in ClientView(store: store) }
    
    // Direct sheet
    .sheet( item: self.$store.scope(state: \.showDirect, action: \.direct)) {
      store in DirectView(store: store) }
    
    // Login sheet
    .sheet( item: self.$store.scope(state: \.showLogin, action: \.login)) {
      store in LoginView(store: store) }
    
    // Picker sheet
    .sheet( item: self.$store.scope(state: \.showPicker, action: \.picker)) {
      store in PickerView(store: store) }
    
    // initialize on first appearance
    .onAppear() {
      store.send(.onAppear)
      // setup left mouse down tracking
    }
    .frame(width: 320)
    .padding(10)
  }
}

struct DaxSelectionView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
  
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
        // segmented contol to select DAX type(s)
        ControlGroup {
          Toggle("Tx", isOn: Binding(get: { store.daxPanelOptions.contains(.tx) }, set: {_,_  in toggleOption(.tx) } ))
          Toggle("Mic", isOn: Binding(get: { store.daxPanelOptions.contains(.mic)  }, set: {_,_  in toggleOption(.mic) } ))
          Toggle("Rx", isOn: Binding(get: { store.daxPanelOptions.contains(.rx)  }, set: {_,_  in toggleOption(.rx) } ))
          Toggle("IQ", isOn: Binding(get: { store.daxPanelOptions.contains(.iq)  }, set: {_,_  in toggleOption(.iq) } ))
        }
      }

      // scrollview to display selected DAX panels
      ScrollView {
        VStack(spacing: 5) {
          if store.daxPanelOptions.contains(.tx) {
            DaxTxView(store: store, devices: AudioDevice.getDevices())
            Divider().frame(height: 3).background(Color(.controlTextColor))
          }
          if store.daxPanelOptions.contains(.mic) {
            DaxMicView(store: store, devices: AudioDevice.getDevices())
            Divider().frame(height: 3).background(Color(.controlTextColor))
          }
          if store.daxPanelOptions.contains(.rx) {
            ForEach(store.scope(state: \.daxRxStates, action: \.daxRxStates)) { store in
              DaxRxView(store: store, devices: AudioDevice.getDevices())
            }
            Divider().frame(height: 3).background(Color(.controlTextColor))
          }
          if store.daxPanelOptions.contains(.iq) {
            ForEach(store.scope(state: \.daxIqStates, action: \.daxIqStates)) { store in
              DaxIqView(store: store, devices: AudioDevice.getDevices())
            }
          }
        }
      }
      
    }
    .scrollIndicators(.visible, axes: .vertical)
  }
}

#Preview {
  SDRDaxView(
    store: Store(initialState: SDRDaxCore.State()) {
      SDRDaxCore()
    }
  )
  .environment(ApiModel.shared)
}
