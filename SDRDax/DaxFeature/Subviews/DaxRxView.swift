//
//  DaxRxView.swift
//
//
//  Created by Douglas Adams on 11/29/23.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import DaxAudioFeature
import LevelIndicatorView
import SharedFeature

struct DaxRxView: View {
  @Bindable var store: StoreOf<DaxRxCore>
  let devices: [AudioDevice]
      
  var body: some View {
    
    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.showDetails.toggle()
            }
            .help("Show / Hide Details")

          Toggle(isOn: $store.isOn) { Text("Rx\(store.channel)").frame(width:30) }
            .toggleStyle(.button)
            .disabled(store.deviceId == nil /* || store.sliceLetter == nil */)

          Spacer()
          Text(store.sliceLetter == nil ? "No Slice" : store.sliceLetter!)
          Text(store.status).frame(width: 150)
        }.frame(width: 320)
        
        if store.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.deviceId) {
                Text("none").tag(nil as AudioDeviceID?)
                ForEach(devices, id: \.id) {
                  if $0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
                }
              }
              .labelsHidden()
            }
            
            GridRow {
              HStack {
                Text("Gain")
                Text("\(Int(store.gain))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.gain, in: 0...100, label: {
              })
            }
          }
          if store.audioOutput != nil {
            LevelIndicatorView(levels: store.audioOutput!.levels, type: .dax)
          } else {
            LevelIndicatorView(levels: SignalLevel(rms: -40, peak: -40), type: .dax)
          }
        }
      }
      
      // monitor isActive
      .onChange(of: store.isActive) {
        store.send(.isActiveChanged)
      }
      
      // monitor closing
      .onDisappear {
        store.send(.onDisappear)
      }
      
    }.frame(width: 320)
  }
}


#Preview {
  DaxRxView(
    store: Store(initialState: DaxRxCore.State(isActive: true, channel: 1, gain: 50)) {
      DaxRxCore()
    }, devices: AudioDevice.getDevices()
  )
  .frame(width: 320)
}
