//
//  DaxRxView.swift
//
//
//  Created by Douglas Adams on 11/29/23.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import FlexApiFeature
//import LevelIndicatorView
import SharedFeature

struct DaxRxView: View {
  @Bindable var store: StoreOf<SDRDax>
  let devices: [AudioDevice]
  
  private let channels = [0,1,2,3,4,5,6,7,8]
  
  var body: some View {
    
    GroupBox("DAX RX Settings") {
      VStack(alignment: .leading) {
        Grid(alignment: .leading, horizontalSpacing: 10) {
          GridRow {
            Toggle(isOn: $store.daxRxSetting.enabled,
                   label: { Text("Enable") }).disabled(store.daxRxSetting.deviceID == nil)
            
            Picker("Channel:", selection: $store.daxRxSetting.channel) {
              Text("").tag(0)
              ForEach(channels, id: \.self) {
                Text("\($0)").tag($0)
              }
            }
          }
          
          Divider()
          
          GridRow {
            Text("Output Device:")
            Picker("", selection: $store.daxRxSetting.deviceID) {
              Text("none").tag(nil as AudioDeviceID?)
              ForEach(devices, id: \.id) {
                if $0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
              }
            }
            .labelsHidden()
          }
          
          GridRow {
            HStack {
              Text("Gain:")
              Text("\(Int(store.daxRxSetting.gain))").frame(width: 40, alignment: .trailing)
            }
            Slider(value: $store.daxRxSetting.gain, in: 0...100)
          }
        }
//        LevelIndicatorView(levels: DaxModel.shared.daxRxAudioPlayer?.levels ?? SignalLevel(rms: -40, peak: -40), type: .dax)
        
        HStack {
          Text("Status:")
          Text(DaxModel.shared.status)
        }
      }
      
      // DEVICE change
//      .onChange(of: store.daxRxSetting.deviceID) {_, newValue in
//        if newValue != nil {
//          print("----->>>>> New AudioDeviceID", newValue!)
//          DaxModel.shared.setDevice(store.daxRxSetting.channel, newValue!)
//          
//        } else {
//          print("----->>>>> New AudioDeviceID", "none")
//        }
//      }
      
      // ENABLED change
//      .onChange(of: store.daxRxSetting.enabled) {_, newValue in
//        if newValue {
//          DaxModel.shared.startDaxRxAudio(store.daxRxSetting.deviceID!, store.daxRxSetting.channel)
//        } else {
//          DaxModel.shared.stopDaxRxAudio(store.daxRxSetting.channel)
//        }
//      }
      
      // GAIN change
//      .onChange(of: store.daxRxSetting.gain) {_, newValue in
//        DaxModel.shared.setGain(channel: store.daxRxSetting.channel, gain: store.daxRxSetting.gain)
//      }
    }
  }
}

#Preview {
  DaxRxView(store: Store(initialState: SDRDax.State(daxPanelOptions: DaxPanelOptions(rawValue: 0))) {
    SDRDax()
  }, devices: [AudioDevice]())
    .frame(minWidth: 450)
}
