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

//struct DaxMicView: View {
//  @Bindable var store: StoreOf<SDRDaxCore>
//  let devices: [AudioDevice]
//  
//  var body: some View {
//    
//    GroupBox {
//      VStack(alignment: .leading) {
//        HStack(spacing: 10) {
//          Image(systemName: store.daxTx.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
//            .onTapGesture {
//              store.daxMic.showDetails.toggle()
//            }
//            .help("Show / Hide Details")
//          Toggle(isOn: $store.daxMic.isOn) { Text("MIC").frame(width: 30) }
//            .toggleStyle(.button)
//          Spacer()
//          Text("Status")
//          Text(store.daxMic.status).frame(width: 150)
//        }.frame(width: 320)
//
//        if store.daxMic.showDetails{
//          Grid(alignment: .topLeading, horizontalSpacing: 10) {
//            
//            GridRow {
//              Text("Output Device").frame(width: 100, alignment: .leading)
//              Picker("", selection: $store.daxMic.audioPlayer.deviceId) {
//                Text("None").tag(nil as AudioDeviceID?)
//                ForEach(devices, id: \.id) {
//                  if $0.hasOutput { Text($0.name!).tag($0.id as AudioDeviceID?) }
//                }
//              }
//              .labelsHidden()
//            }
//            
//            GridRow {
//              HStack {
//                Text("Gain")
//                Text("\(Int(store.daxMic.audioPlayer.gain ))").frame(width: 40, alignment: .trailing)
//              }
//              Slider(value: $store.daxMic.audioPlayer.gain, in: 0...100, label: {
//              })
//            }
//          }
//        }
//      }
//    }.frame(width: 320)
//  }
//}



//#Preview {
//  DaxMicView(store: Store(initialState: DaxMicCore.State() {
//    DaxMicCore()
//  }, devices: [AudioDevice]())
//    .frame(width: 320)
//}
