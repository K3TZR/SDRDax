//
//  DaxTxView.swift
//
//
//  Created by Douglas Adams on 11/29/23.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import SharedFeature

struct DaxTxView: View {
  @Bindable var store: StoreOf<SDRDaxCore>
  let devices: [AudioDevice]
  
  @State var showDetails = true
  var body: some View {

    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.daxTx.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.daxTx.showDetails.toggle()
            }
            .help("Show / Hide Details")
          Toggle(isOn: $store.daxTx.isOn) { Text("TX").frame(width: 30) }
            .toggleStyle(.button)
          
          Spacer()
          Text("Status").frame(width: 90)
          Text(store.daxTx.status).frame(width: 140)
        }
//        .frame(width: 320)

        if store.daxTx.showDetails{
          Grid(alignment: .topLeading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Input Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.daxTx.audioPlayer.deviceId) {
                Text("None").tag(nil as AudioDeviceID?)
                ForEach(devices, id: \.id) {
                  if !$0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
                }
              }
              .labelsHidden()
            }
            
            GridRow {
              HStack {
                Text("Gain")
                Text("\(Int(store.daxTx.audioPlayer.gain))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.daxTx.audioPlayer.gain, in: 0...100, label: {
              })
            }
          }
        }
      }
    }
//    .frame(width: 320)
//    .groupBoxStyle(PlainGroupBoxStyle())
  }
}

//#Preview {
//  DaxTxView(store: Store(initialState: DaxTxCore.State()) {
//    DaxTxCore()
//  }, devices: [AudioDevice]())
//    .frame(width: 320)
//}
