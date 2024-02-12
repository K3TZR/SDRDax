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
          Image(systemName: store.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.showDetails.toggle()
            }
            .help("Show / Hide Details")
          Toggle(isOn: $store.isOn) { Text("Iq\(store.channel)").frame(width: 30) }
            .toggleStyle(.button)
            .disabled(store.device == nil)
          Spacer()
          Text("\(String(format: "%2.6f", store.frequency ?? 0))")
            .opacity( store.frequency == nil ? 0 : 1)
            .frame(width: 150)
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
              Text("Output Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.device) {
                Text("none").tag(nil as AudioDeviceID?)
                ForEach(devices, id: \.id) {
                  if $0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
                }
              }
              .labelsHidden()
            }

          }
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
