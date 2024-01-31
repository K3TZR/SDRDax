//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 11/29/23.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import SharedFeature

struct DaxMicView: View {
  @Bindable var store: StoreOf<SDRDax>
  let devices: [AudioDevice]
  
  @State var status = "Off"
  
  var body: some View {

    GroupBox("DAX MIC Settings") {
      Grid(alignment: .topLeading, horizontalSpacing: 10) {
        
          GridRow {
            Toggle(isOn: $store.daxMicSetting.enabled,
                   label: { Text("Enable") })
            HStack {
              Text("Status:")
              Text(status).frame(width: 40)
            }.gridColumnAlignment(.trailing)
          }

          GridRow {
            Text("Output Device:")
            Picker("", selection: $store.daxMicSetting.deviceID) {
              Text("None").tag(nil as AudioDeviceID?)
              ForEach(devices, id: \.id) {
                if $0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
              }
            }
            .labelsHidden()
          }

          GridRow {
            HStack {
              Text("Gain:")
              Text("\(Int(store.daxMicSetting.gain * 100))").frame(width: 40, alignment: .trailing)
            }
            Slider(value: $store.daxMicSetting.gain, in: 0...1, label: {
            })
          }
      }
    }
//    .groupBoxStyle(PlainGroupBoxStyle())
  }
}



#Preview {
  DaxMicView(store: Store(initialState: SDRDax.State(daxPanelOptions: DaxPanelOptions(rawValue: 0))) {
    SDRDax()
  }, devices: [AudioDevice]())
    .frame(width: 320)
}
