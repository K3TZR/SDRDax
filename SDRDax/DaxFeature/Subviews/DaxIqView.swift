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
  
  var body: some View {

    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.showDetails.toggle()
            }
            .help("Show / Hide Details")
          Toggle(isOn: $store.isOn) { Text("IQ\(store.id - 5)").frame(width: 30) }
            .toggleStyle(.button)
            .disabled(store.deviceUid == nil)
          
          Spacer()
          Text("\(store.frequency == nil ? "No Pan" : String(format: "%2.6f", store.frequency!))")
            .frame(width: 90)
          Text(store.streamStatus.rawValue).frame(width: 140)
        }

        if store.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            GridRow {
              Text("Rate")
              Picker("", selection: $store.sampleRate) {
                ForEach(SampleRate.allCases, id: \.self) {
                  Text("\($0.rawValue)").tag($0.rawValue)
                }
              }
              .labelsHidden()
              .frame(width: 150)
            }
            
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
          }
        }
      }
      
      // monitor isActive
      .onChange(of: store.isConnected) {
        store.send(.isConnectedChanged)
      }
            
      // monitor opening
      .onAppear {
        store.send(.onAppear)
      }

      // monitor closing
      .onDisappear {
        store.send(.onDisappear)
      }
    }
  }
}

#Preview {
  DaxIqView(
    store: Store(initialState: DaxIqCore.State(id: 6, deviceUid: nil, isOn: false, sampleRate: .r24, showDetails: false, isConnected: Shared(false))) {
      DaxIqCore()
    }
  )

  .frame(minWidth: 370, maxWidth: 370)
}
