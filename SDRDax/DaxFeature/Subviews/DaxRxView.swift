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
  
  @MainActor private var activeSlice: String {
    for slice in apiModel.slices where slice.daxChannel == store.ch.channel {
      return SliceStatus.sliceFound.rawValue + (slice.sliceLetter ?? "")
    }
    if store.ch.isOn {
      return SliceStatus.waiting.rawValue
    } else {
      return SliceStatus.sliceNotFound.rawValue
    }
  }
    
  var body: some View {
    
    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.ch.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.ch.showDetails.toggle()
            }
            .help("Show / Hide Details")

          Toggle(isOn: $store.ch.isOn) { Text("Rx\(store.ch.channel)").frame(width:30) }
            .toggleStyle(.button)
            .disabled(store.ch.deviceUid == nil /* || store.sliceLetter == nil */)

          Spacer()
          Text(activeSlice)
            .foregroundColor(activeSlice == SliceStatus.sliceNotFound.rawValue ? .red : .green)
            .frame(width: 90)
          Text(store.streamStatus.rawValue).frame(width: 140)
        }
        
        if store.ch.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.ch.deviceUid) {
                Text("none").tag(nil as String?)
                ForEach(store.audioDevices, id: \.uid) {
                  if $0.hasOutput { Text($0.name!).tag($0.uid as String?) }
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
          LevelIndicatorView(levels: store.audioOutput?.levels ?? SignalLevel(rms: -40, peak: -40), type: .dax)
        }
      }
            
      .onAppear {
        store.send(.onAppear)
      }
//      .onChange(of: activeSlice) {
//        store.send(.activeSliceChanged($1))
//      }
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
    store: Store(initialState: DaxRxCore.State(ch: RxChannel(channel: 1, deviceUid: nil, gain: 50, isOn: false, showDetails: false), isConnected: Shared(false))) {
      DaxRxCore()
    }
  )

  .frame(minWidth: 370, maxWidth: 370)
}
