//
//  DaxMicView.swift
//  SDRDax
//
//  Created by Douglas Adams on 3/1/24.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

import DaxAudioFeature
import FlexApiFeature
import LevelIndicatorView
import SharedFeature

struct DaxMicView: View {
  @Bindable var store: StoreOf<DaxMicCore>
        
  var body: some View {
    
    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.showDetails.toggle()
            }
            .help("Show / Hide Details")

          Toggle(isOn: $store.isOn) { Text("Mic").frame(width:30) }
            .toggleStyle(.button)
            .disabled(store.deviceUid == nil /* || store.sliceLetter == nil */)

          Spacer()
          Text(store.status.rawValue).frame(width: 140)
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
          if store.audioOutput != nil {
            LevelIndicatorView(levels: store.audioOutput!.levels, type: .dax)
          } else {
            LevelIndicatorView(levels: SignalLevel(rms: -40, peak: -40), type: .dax)
          }
        }
      }
      
      .onAppear {
        store.send(.onAppear)
      }

      .onChange(of: store.isConnected) {
        store.send(.isConnectedChanged)
      }
            
//      .onChange(of: store.ch.isOn) {
//        store.send(.isOnChanged)
//      }
//
//      .onChange(of: store.ch.gain) {
//        store.send(.gainChanged)
//      }
//
//      .onChange(of: store.ch.deviceId) {
//        store.send(.deviceIdChanged)
//      }
//
      .onDisappear {
        store.send(.onDisappear)
      }
    }
  }
}


#Preview {
  DaxMicView(store: Store(initialState: DaxMicCore.State(channel: 1, deviceUid: nil, gain: 50, isOn: false, showDetails: true, isConnected: Shared(false))) {
      DaxMicCore()
    }
  )

  .frame(minWidth: 370, maxWidth: 370)
}
