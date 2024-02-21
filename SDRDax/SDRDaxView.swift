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
    
  @State var selection: String? = nil
  @State var confirmationText = ""
  @State var confirmationPresented = false
  
  private func isActive(_ selection: String?) -> Bool {
    if selection == nil {
      return false
    } else {
      return listenerModel.stations[id: selection!] != nil
    }
  }
  
//  private func components(_ stationId: String) -> [String] {
//    return stationId.components(separatedBy: "|")
//  }
  
//  private func isLocal(_ id: String) -> Bool {
//   id.components(separatedBy: "|")[4] == "Local"
//  }
  
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
            Spacer()
            Image(systemName: "minus.circle").disabled(selection == nil)
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
          Picker("", selection: $selection) {
            Text("none").tag(nil as String?)
            ForEach(listenerModel.stations, id: \.id) {
              Text(nameString($0.id))
                .tag($0.id as String?)
            }
          }
          .labelsHidden()
          
          Image(systemName: "circle.fill").foregroundColor(selection == nil ? .red : .green)
          Spacer()
          Image(systemName: "plus.circle").disabled(selection == nil)
            .help("SAVE DEFAULT")
            .onTapGesture{
              store.send(.setAutoSelection(selection!))
              confirmationText = "Default Saved"
              confirmationPresented = true
            }
        }
      }
      .confirmationDialog(confirmationText, isPresented: $confirmationPresented) {}
      
      DaxSelectionView(store: store, isActive: selection != nil)
      Spacer()
    }
        
    .onChange(of: listenerModel.stations) {
      if let selection {
        if $1[id: selection] == nil {
          self.selection = nil
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
//    .frame(minWidth: 370)
//    .padding(10)
  }
}

private struct DaxSelectionView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
  let isActive: Bool
  
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
      
      if isActive {
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
      } else {
        Spacer()
        Text("Select a Station")
        Spacer()
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
