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
            .disabled(store.audioPlayer.deviceId == nil /* || store.sliceLetter == nil */)

          Spacer()
          Text(store.sliceLetter == nil ? "No Slice" : store.sliceLetter!)
          Text(store.status).frame(width: 150)
        }.frame(width: 320)
        
        if store.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.audioPlayer.deviceId) {
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
                Text("\(Int(store.audioPlayer.gain))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.audioPlayer.gain, in: 0...100, label: {
              })
            }
          }
          LevelIndicatorView(levels: store.audioPlayer.levels, type: .dax)
        }
      }
    }.frame(width: 320)
  }
}


#Preview {
  DaxRxView(
    store: Store(initialState: DaxRxCore.State(audioPlayer: DaxAudioPlayer(), channel: 1)) {
      DaxRxCore()
    }, devices: AudioDevice.getDevices()
  )
  .frame(width: 320)
}
