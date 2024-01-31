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
  @Bindable var store: StoreOf<SDRDax>
      
  var body: some View {
    VStack(alignment: .leading) {
      TopButtonsView(store: store)
      DaxView(store: store)
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

#Preview {
  SDRDaxView(store: Store(initialState: SDRDax.State(daxPanelOptions: DaxPanelOptions(rawValue: 1))) {
    SDRDax()
  })
  .environment(ApiModel.shared)
}
