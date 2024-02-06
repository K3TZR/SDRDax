//
//  DaxIqView.swift
//
//
//  Created by Douglas Adams on 11/29/23.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import LevelIndicatorView
import SharedFeature

struct DaxIqView: View {
  @Bindable var store: StoreOf<DaxIqCore>
  let devices: [AudioDevice]
  
  private let channels = [0,1,2,3,4,5,6,7,8]
  private let rates = [24_000, 48_000, 96_000, 192_000]
  @State var showDetails = true
  
  var body: some View {

    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 20) {
          Image(systemName: showDetails ? "chevron.down" : "chevron.right").font(.title2)
            .onTapGesture {
              showDetails.toggle()
            }
            .help(showDetails ? "Hide Details" : "Show Details")

          Toggle(isOn: $store.enabled,
                 label: { Text("Enabled") }).disabled(store.deviceID == nil || store.channel == 0)

          Text("Status")
          Text(DaxModel.shared.status).frame(width: 110)
        }.frame(width: 320)
        
        if showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            Divider()
            
            GridRow {
              Picker("Channel", selection: $store.channel) {
                ForEach(channels, id: \.self) {
                  Text($0 == 0 ? "none" : "\($0)").tag($0)
                }
              }.frame(width: 145)
              
              Picker("Rate", selection: $store.sampleRate) {
                ForEach(rates, id: \.self) {
                  Text("\($0)").tag($0)
                }
              }.frame(width: 150)
            }
            
            GridRow {
              Picker("Output Device", selection: $store.deviceID) {
                Text("none").tag(nil as AudioDeviceID?)
                ForEach(devices, id: \.id) {
                  if $0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
                }
              }
              .gridCellColumns(2)
//              .labelsHidden()
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
          LevelIndicatorView(levels: DaxModel.shared.daxRxAudioPlayer?.levels ?? SignalLevel(rms: -40, peak: -40), type: .dax)
        }
      }
    }
    .frame(width: 320)
  }
}

#Preview {
  DaxIqView(
    store: Store(initialState: DaxIqCore.State(id: UUID())) {
      DaxIqCore()
    }, devices: AudioDevice.getDevices()
  )
  .frame(width: 320)
}
