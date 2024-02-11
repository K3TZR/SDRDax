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
          Image(systemName: store.daxTx.showDetails ? "chevron.down" : "chevron.right").font(.title2)
            .onTapGesture {
              store.daxTx.showDetails.toggle()
            }.frame(width: 40)
            .help("Show / Hide Details")
          Toggle("TX", isOn: $store.daxTx.enabled).toggleStyle(.button)
          Spacer()
          Text("Status")
          Text(store.daxTx.status).frame(width: 150)
        }.frame(width: 320)

        if store.daxTx.showDetails{
          Grid(alignment: .topLeading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Input Device")
              Picker("", selection: $store.daxTx.deviceID) {
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
                Text("\(Int(store.daxTx.gain * 100))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.daxTx.gain, in: 0...1, label: {
              })
            }
          }
        }
      }
    }
//    .groupBoxStyle(PlainGroupBoxStyle())
  }
}

//#Preview {
//  DaxTxView(store: Store(initialState: DaxTxCore.State()) {
//    DaxTxCore()
//  }, devices: [AudioDevice]())
//    .frame(width: 320)
//}
