//
//  SDRDaxView.swift
//  SDRDax
//
//  Created by Douglas Adams on 1/30/24.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import ListenerFeature
import LoginFeature
import SharedFeature

struct SDRDaxView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
  
  @Environment(ListenerModel.self) var listenerModel
  
  @State var confirmationText = ""
  @State var confirmationPresented = false
  
  private func nameString(_ id: String) -> String {
    let components = id.components(separatedBy: "|")
    return components[2] + " (" + components[3] + ")"
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 10) {
        if store.autoStartEnabled && store.autoSelection != nil {
          // use the default Station
          Text("Station")
          if store.autoSelection == nil {
            Text("NO Default Station").frame(width: 215)
          } else {
            Text(nameString(store.autoSelection!)).frame(width: 215)
              .onAppear{
                store.selection = store.autoSelection
              }
            Spacer()
            Image(systemName: "minus.circle").disabled(store.selection == nil)
              .help("REMOVE DEFAULT")
              .onTapGesture{
                store.send(.setAutoSelection(nil))
                confirmationText = "Default Removed"
                confirmationPresented = true
              }
          }
          
        } else {
          // manually choose a Station
          Text("Station")
          Picker("", selection: $store.selection) {
            Text("none").tag(nil as String?)
            ForEach(listenerModel.stations, id: \.id) {
              Text(nameString($0.id))
                .tag($0.id as String?)
            }
          }
          .labelsHidden()
          
          Image(systemName: "circle.fill").foregroundColor(store.isActive ? .green : .red)
          Spacer()
          Image(systemName: "plus.circle").disabled(store.selection == nil)
            .help("SAVE DEFAULT")
            .onTapGesture{
              store.send(.setAutoSelection(store.selection!))
              confirmationText = "Default Saved"
              confirmationPresented = true
            }
        }
      }
      .confirmationDialog(confirmationText, isPresented: $confirmationPresented) {}
      
      DaxSelectionView(store: store)
      Spacer()
    }
    
    .onChange(of: listenerModel.stations) {
      if let selection = store.selection {
        if $1[id: selection] == nil {
          store.selection = nil
        }
      }
    }
    
    // initialize on first appearance
    .onAppear() {
      store.send(.onAppear)
    }
    .onDisappear() {
      store.send(.onDisappear)
    }
    
    // Alert
    .alert($store.scope(state: \.showAlert, action: \.alert))
    
    // Login sheet
    .sheet( item: self.$store.scope(state: \.showLogin, action: \.login)) {
      store in LoginView(store: store) }
    
    .toolbar {
      ToolbarItemGroup {
        VStack(spacing: 0) {
          Button(action: { store.send(.modeTapped) }) {
            Text(store.autoStartEnabled ? "Auto" : "Manual").frame(width: 60)
          }
          Button(action: { store.send(.connectionTapped) }) {
            Text(store.smartlinkEnabled ? "Smartlink" : "Local").frame(width: 60)
          }
          Button(action: { store.send(.bandwidthTapped) }) {
            Text(store.reducedBandwidth ? "Reduced" : "Full")
              .frame(width: 60)
              .foregroundColor(store.reducedBandwidth ? .yellow : nil)
          }
        }
        .controlSize(.small)
        .disabled(store.isConnected)
      }
    }
  }
}

private struct DaxSelectionView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
  
  var body: some View {
    
    VStack(alignment: .center) {
      
      if store.autoStartEnabled && store.autoSelection != nil && !store.isConnected {
        SpinnerView()
      } else {
        
        // scrollview to display selected DAX panels
        ScrollView {
          VStack(spacing: 5) {
            if store.txEnabled {
              ForEach(store.scope(state: \.txStates, action: \.txStates)) { store in
                DaxTxView(store: store)
              }
              Divider().frame(height: 3).background(Color(.controlTextColor))
            }
            if store.micEnabled {
              ForEach(store.scope(state: \.micStates, action: \.micStates)) { store in
                DaxMicView(store: store)
              }
              Divider().frame(height: 3).background(Color(.controlTextColor))
            }
            if store.rxEnabled {
              ForEach(store.scope(state: \.rxStates, action: \.rxStates)) { store in
                VStack(spacing: 5) {
                  DaxRxView(store: store)
                  Divider().background(Color(.blue))
                }
              }
              Divider().frame(height: 3).background(Color(.controlTextColor))
            }
            if store.iqEnabled {
              ForEach(store.scope(state: \.iqStates, action: \.iqStates)) { store in
                VStack(spacing: 5) {
                  DaxIqView(store: store)
                  Divider().background(Color(.blue))
                }
              }
              Divider().frame(height: 3).background(Color(.controlTextColor))
            }
          }
        } .scrollIndicators(.visible, axes: .vertical)
      }
    }
  }
}

#Preview {
  SDRDaxView(
    store: Store(initialState: SDRDaxCore.State(iqEnabled: Shared(true),
                                                micEnabled: Shared(true),
                                                rxEnabled: Shared(true),
                                                txEnabled: Shared(true), 
                                                autoStartEnabled: Shared(false),
                                                reducedBandwidth: Shared(false),
                                                smartlinkEnabled: Shared(true))) {
      SDRDaxCore()
    }
  )
  .environment(ApiModel.shared)
  .environment(ListenerModel.shared)

  .frame(minWidth: 370, maxWidth: 370)
}
