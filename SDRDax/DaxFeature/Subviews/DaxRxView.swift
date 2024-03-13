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
import FlexApiFeature
import LevelIndicatorView
import SharedFeature

struct DaxRxView: View {
  @Bindable var store: StoreOf<DaxRxCore>
  
  @Environment(ApiModel.self) var apiModel

//  private var buttonLabel: String {
//    if store.ch.channel == 0 { return "Mic"}
//    return "Rx\(store.ch.channel)"
//  }
  
  @MainActor private var activeSlice: String? {
    var letter: String?
    for slice in apiModel.slices where slice.daxChannel == store.channel {
      letter = slice.sliceLetter
    }
    return letter
  }
    
  @MainActor private var status: String {
    if store.isOn {
      return activeSlice == nil ? "Waiting" : store.status.rawValue
    } else {
      return "Off"
    }
  }
  
  var body: some View {
    
    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.showDetails.toggle()
            }
            .help("Show / Hide Details")

          Toggle(isOn: $store.isOn) { Text("Rx\(store.channel)").frame(width:30) }
            .toggleStyle(.button)
            .disabled(store.deviceUid == nil /* || store.sliceLetter == nil */)

          Spacer()
          Text(activeSlice == nil ? "No Slice" : "Slice " + activeSlice!)
            .foregroundColor(activeSlice == nil ? .red : .green)
            .frame(width: 90)
          Text(status).frame(width: 140)
        }
        
        if store.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.deviceUid) {
                Text("none").tag(nil as String?)
                ForEach(store.devices, id: \.uid) {
                  if $0.hasOutput { Text($0.name!).tag($0.uid as String?) }
                }
              }
              .labelsHidden()
            }
            
            GridRow {
              HStack {
                Text("Gain")
                Text("\(Int(store.gain))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.gain, in: 0...100, label: {
              })
            }
          }
//          if store.audioOutput != nil {
            LevelIndicatorView(levels: store.audioOutput?.levels ?? SignalLevel(rms: -40, peak: -40), type: .dax)
//          } else {
//            LevelIndicatorView(levels: SignalLevel(rms: -40, peak: -40), type: .dax)
//          }
        }
      }
            
      .onAppear {
        store.send(.onAppear)
      }
      .onChange(of: activeSlice) {
        store.send(.activeSliceChanged($1))
      }
      .onChange(of: store.isConnected) {
        store.send(.isConnectedChanged)
      }
      .onDisappear {
        store.send(.onDisappear)
      }
    }
  }
}


#Preview {
  DaxRxView(
    store: Store(initialState: DaxRxCore.State(channel: 1, deviceUid: nil, gain: 50, isOn: false, showDetails: true, isConnected: Shared(false))) {
      DaxRxCore()
    }
  )

  .frame(minWidth: 370, maxWidth: 370)
}
