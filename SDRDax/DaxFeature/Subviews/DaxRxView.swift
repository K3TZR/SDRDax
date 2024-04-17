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

  @MainActor private var activeSlice: String {
    for slice in apiModel.slices where slice.daxChannel == store.id {
      return SliceStatus.sliceFound.rawValue + (slice.sliceLetter ?? "")
    }
    if store.isOn && store.isConnected {
      return SliceStatus.waiting.rawValue
    } else {
      return SliceStatus.sliceNotFound.rawValue
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

          Toggle(isOn: $store.isOn) { Text("RX\(store.id)").frame(width:30) }
            .toggleStyle(.button)
            .disabled(store.deviceUid == nil /* || store.sliceLetter == nil */)

          Spacer()
          Text(activeSlice)
            .foregroundColor(activeSlice == SliceStatus.sliceNotFound.rawValue ? .red : .green)
            .frame(width: 90)
          Text(store.streamStatus.rawValue).frame(width: 140)
        }
        
        if store.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            
            GridRow {
              Text("Output Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.deviceUid) {
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
                Text("\(Int(store.gain))").frame(width: 40, alignment: .trailing)
              }
              Slider(value: $store.gain, in: 0...100, label: {
              })
            }
          }
          LevelIndicatorView(levels: store.audioOutput?.levels ?? SignalLevel(rms: -40, peak: -40), type: .dax)
        }
      }
            
      .onAppear {
        store.send(.onAppear)
      }
      .onDisappear {
        store.send(.onDisappear)
      }
      .onChange(of: store.isConnected) {
        store.send(.isConnectedChanged)
      }
    }
  }
}


#Preview {
  DaxRxView(
    store: Store(initialState: DaxRxCore.State(id: 1, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false, isConnected: Shared(false))) {
      DaxRxCore()
    }
  )

  .frame(minWidth: 370, maxWidth: 370)
}
