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
  @Bindable var store: StoreOf<DaxTxCore>
  
  @State var showDetails = true
  var body: some View {

    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.ch.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.ch.showDetails.toggle()
            }
            .help("Show / Hide Details")
          Toggle(isOn: $store.ch.isOn) { Text("TX").frame(width: 30) }
            .toggleStyle(.button)
          
          Spacer()
          Text("Status").frame(width: 90)
          Text(store.status).frame(width: 140)
        }
//        .frame(width: 320)

        if store.ch.showDetails{
          Grid(alignment: .topLeading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Input Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.ch.deviceUid) {
                Text("None").tag(nil as String?)
                ForEach(store.devices, id: \.uid) {
                  if !$0.hasOutput { Text($0.name!).tag($0.uid as String?) }
                }
              }
              .labelsHidden()
            }
            
            GridRow {
              HStack {
                Text("Gain")
                Text("\(Int(store.ch.gain))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.ch.gain, in: 0...100, label: {
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
