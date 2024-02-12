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
//            .frame(width: 40)
            .help("Show / Hide Details")
          Toggle(isOn: $store.isOn) { Text("Rx\(store.channel)").frame(width:30) }
            .toggleStyle(.button)
            .disabled(store.device == nil)
          Spacer()
          Text("Slice " + store.sliceLetter).opacity(store.sliceLetter.isEmpty ? 0 : 1)
          Text(store.status).frame(width: 150)
        }.frame(width: 320)
        
        if store.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device").frame(width: 100, alignment: .leading)
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
          // TODO: need source of levels
          LevelIndicatorView(levels: SignalLevel(rms: -30, peak: -20), type: .dax)
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
