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
          Image(systemName: store.showDetails ? "chevron.down" : "chevron.right").font(.title2)
            .onTapGesture {
              store.showDetails.toggle()
            }.frame(width: 40)
            .help("Show / Hide Details")
          Toggle("Rx\(store.channel)", isOn: $store.isOn).toggleStyle(.button).disabled(store.device == nil)
          Spacer()
          Text("Status")
          Text(store.status).frame(width: 150)
        }.frame(width: 320)
        
        if store.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device")
              Picker("", selection: $store.device) {
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
                Text("\(Int(store.gain * 100))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.gain, in: 0...1, label: {
              })
            }
          }
//          LevelIndicatorView(levels: store.audioPlayer.levels, type: .dax)
        }
      }
    }.frame(width: 320)
  }
}


#Preview {
  DaxRxView(
    store: Store(initialState: DaxRxCore.State(channel: 1)) {
      DaxRxCore()
    }, devices: AudioDevice.getDevices()
  )
  .frame(width: 320)
}
