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
  
  private let rates = [24_000, 48_000, 96_000, 192_000]
  
  var body: some View {

    GroupBox {
      VStack(alignment: .leading) {
        HStack(spacing: 10) {
          Image(systemName: store.ch.showDetails ? "chevron.up.square" : "chevron.down.square").font(.title)
            .onTapGesture {
              store.ch.showDetails.toggle()
            }
            .help("Show / Hide Details")
          Toggle(isOn: $store.ch.isOn) { Text("Iq\(store.ch.channel)").frame(width: 30) }
            .toggleStyle(.button)
            .disabled(store.ch.deviceUid == nil)
          
          Spacer()
          Text("\(store.frequency == nil ? "No Pan" : String(format: "%2.6f", store.frequency!))")
            .frame(width: 90)
          Text(store.status).frame(width: 140)
        }

        if store.ch.showDetails {
          Grid(alignment: .leading, horizontalSpacing: 10) {
            GridRow {
              Text("Rate")
              Picker("", selection: $store.ch.sampleRate) {
                ForEach(rates, id: \.self) {
                  Text("\($0)").tag($0)
                }
              }
              .labelsHidden()
              .frame(width: 150)
            }
            
            GridRow {
              Text("Output Device").frame(width: 100, alignment: .leading)
              Picker("", selection: $store.ch.deviceUid) {
                Text("none").tag(nil as String?)
                ForEach(store.devices, id: \.uid) {
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
        store.send(.isActiveChanged)
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
    store: Store(initialState: DaxIqCore.State(ch: IqChannel(channel: 1, deviceUid: nil, isOn: false, sampleRate: 24_000, showDetails: true), isConnected: Shared(false))) {
      DaxIqCore()
    }
  )

  .frame(minWidth: 370, maxWidth: 370)
}
