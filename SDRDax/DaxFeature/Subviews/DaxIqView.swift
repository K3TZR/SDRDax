//
//  DaxIqView.swift
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

struct DaxIqView: View {
  @Bindable var store: StoreOf<DaxIqCore>
  let devices: [AudioDevice]
  
  private let rates = [24_000, 48_000, 96_000, 192_000]
  @State var showDetails = true
  
  var body: some View {

    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.showDetails ? "chevron.down" : "chevron.right").font(.title2)
            .onTapGesture {
              store.showDetails.toggle()
            }.frame(width: 40)
            .help("Show / Hide Details")
          Toggle("Iq\(store.channel)", isOn: $store.isOn).toggleStyle(.button).disabled(store.device == nil)
          Spacer()
          Text("Status")
          Text(store.status).frame(width: 150)
        }.frame(width: 320)

        if showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            GridRow {
              Text("Rate")
              Picker("", selection: $store.sampleRate) {
                ForEach(rates, id: \.self) {
                  Text("\($0)").tag($0)
                }
              }
              .labelsHidden()
              .frame(width: 150)
            }
            
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
    }
    .frame(width: 320)
  }
}

#Preview {
  DaxIqView(
    store: Store(initialState: DaxIqCore.State(channel: 1)) {
      DaxIqCore()
    }, devices: AudioDevice.getDevices()
  )
  .frame(width: 320)
}
