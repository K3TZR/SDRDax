//
//  DaxTxView.swift
//
//
//  Created by Douglas Adams on 11/29/23.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import SharedFeature

struct DaxTxView: View {
  @Bindable var store: StoreOf<SDRDax>
  let devices: [AudioDevice]
  
  @State var status = "Off"
    
  var body: some View {
    
    GroupBox("DAX TX Settings") {
      Grid(alignment: .topLeading, horizontalSpacing: 10) {
        
        GridRow {
          Toggle(isOn: $store.daxTxSetting.enabled,
                 label: { Text("Enable") })
          HStack {
            Text("Status:")
            Text(status).frame(width: 40)
          }.gridColumnAlignment(.trailing)
        }
        
        GridRow {
          Text("Input Device: ")
          Picker("", selection: $store.daxTxSetting.deviceID) {
            Text("None").tag(nil as AudioDeviceID?)
            ForEach(devices, id: \.id) {
              if !$0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
            }
          }
          .labelsHidden()
        }
        
        GridRow {
          HStack {
            Text("Gain:")
            Text("\(Int(store.daxTxSetting.gain * 100))").frame(width: 40, alignment: .trailing)
          }
          Slider(value: $store.daxTxSetting.gain, in: 0...1, label: {
          })
        }
      }
    }
//    .groupBoxStyle(PlainGroupBoxStyle())
  }
}

#Preview {
  DaxTxView(store: Store(initialState: SDRDax.State(daxPanelOptions: DaxPanelOptions(rawValue: 0))) {
    SDRDax()
  }, devices: [AudioDevice]())
    .frame(width: 450)
}
