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
  @Bindable var store: StoreOf<SDRDaxCore>
  let devices: [AudioDevice]
  
  var body: some View {
    
    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.daxMic.showDetails ? "chevron.down" : "chevron.right").font(.title2)
            .onTapGesture {
              store.daxMic.showDetails.toggle()
            }.frame(width: 40)
            .help("Show / Hide Details")
          Toggle("MIC", isOn: $store.daxMic.enabled).toggleStyle(.button)
          Spacer()
          Text("Status")
          Text(store.daxMic.status).frame(width: 150)
        }.frame(width: 320)

        if store.daxMic.showDetails{
          Grid(alignment: .topLeading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device")
              Picker("", selection: $store.daxMic.deviceID) {
                Text("None").tag(nil as AudioDeviceID?)
                ForEach(devices, id: \.id) {
                  if $0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
                }
              }
              .labelsHidden()
            }
            
            GridRow {
              HStack {
                Text("Gain")
                Text("\(Int(store.daxMic.gain * 100))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.daxMic.gain, in: 0...1, label: {
              })
            }
          }
        }
      }
    }
  }
}



//#Preview {
//  DaxMicView(store: Store(initialState: DaxMicCore.State() {
//    DaxMicCore()
//  }, devices: [AudioDevice]())
//    .frame(width: 320)
//}
