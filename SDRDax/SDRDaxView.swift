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
        if store.autoStart {
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
          
          Image(systemName: "circle.fill").foregroundColor(store.stationFound ? .green : .red)
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
    
    // Alert
    .alert($store.scope(state: \.showAlert, action: \.alert))
    
    // Login sheet
    .sheet( item: self.$store.scope(state: \.showLogin, action: \.login)) {
      store in LoginView(store: store) }
    
    .toolbar {
      ToolbarItemGroup {
        HStack {
          Text("Modes")
          VStack(spacing: 0) {
            Toggle(isOn: $store.smartlinkEnabled) {
              Text(store.smartlinkEnabled ? "Smartlink" : "Local").frame(width: 60)
            }
            Toggle(isOn: $store.autoStart) {
              Text(store.autoStart ? "Auto" : "Manual").frame(width: 60)
            }
          }
          .toggleStyle(.button)
          .controlSize(.small)
        }
      }
    }
  }
}

private struct DaxSelectionView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
  
  private func toggleOption(_ option: DaxPanelOptions) {
    if store.daxPanelOptions.contains(option) {
      store.daxPanelOptions.remove(option)
    } else {
      store.daxPanelOptions.insert(option)
    }
  }
  
  var body: some View {
    
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
      
      if store.autoStart && !store.stationFound {
        SpinnerView()
      } else {
        
        // scrollview to display selected DAX panels
        ScrollView {
          VStack(spacing: 5) {
            if store.daxPanelOptions.contains(.tx) {
              DaxTxView(store: store, devices: AudioDevice.getDevices())
              Divider().frame(height: 3).background(Color(.controlTextColor))
            }
            if store.daxPanelOptions.contains(.mic) {
              ForEach(store.scope(state: \.micStates, action: \.micStates)) { store in
                DaxRxView(store: store, devices: AudioDevice.getDevices())
              }
              Divider().frame(height: 3).background(Color(.controlTextColor))
            }
            if store.daxPanelOptions.contains(.rx) {
              ForEach(store.scope(state: \.rxStates, action: \.rxStates)) { store in
                DaxRxView(store: store, devices: AudioDevice.getDevices())
              }
              Divider().frame(height: 3).background(Color(.controlTextColor))
            }
            if store.daxPanelOptions.contains(.iq) {
              ForEach(store.scope(state: \.iqStates, action: \.iqStates)) { store in
                DaxIqView(store: store, devices: AudioDevice.getDevices())
              }
            }
          }
        } .scrollIndicators(.visible, axes: .vertical)
      }
    }
  }
}

#Preview {
  SDRDaxView(
    store: Store(initialState: SDRDaxCore.State()) {
      SDRDaxCore()
    }
  )
  .environment(ApiModel.shared)
  .environment(ListenerModel.shared)
}
