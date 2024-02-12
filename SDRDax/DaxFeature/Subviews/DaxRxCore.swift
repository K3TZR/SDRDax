//
//  DaxRxCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 2/3/24.
//

import ComposableArchitecture
import Foundation

import FlexApiFeature
import DaxAudioFeature
import SharedFeature

@Reducer
public struct DaxRxCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable, Identifiable {
    let channel: Int
    var device: UInt32?
    var gain: Double = 0.5
    var isOn: Bool = false
    var showDetails = true
    var sliceLetter = ""
    var status = "Off"

    public var id: Int { channel }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Reducer
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
        
//      case .binding(\.audioPlayer.deviceID):
//        print("--->>> DaxRxCore deviceID = \(state.audioPlayer.deviceID ?? 0)")
//        state.audioPlayer?.deviceID = state.deviceID
//        return .none
        
//      case .binding(\.enabled):
//        print("--->>> DaxRxCore enabled = \(state.enabled)")
//        if state.enabled && state.audioPlayer.deviceID != nil {
//          // START AUDIO
//          state.audioPlayer.status = "Streaming"
//          // start player
//          state.audioPlayer = DaxAudioPlayer(sampleRate: 24_000)   // FIXNE: Where does volume come from?
//          return .run { [state] _ in
//            // request a stream
//            if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.channel).streamId {
//              // finish audio setup
//              state.audioPlayer.start(streamId)
//              await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.audioPlayer
//              
//            } else {
//              // FAILURE, tell the user it failed
//              //      alertText = "Failed to start a RemoteRxAudioStream"
//              //      showAlert = true
//              fatalError("Failed to start a RemoteRxAudioStream")
//            }
//          }
//        } else {
//          // STOP AUDIO
//          state.audioPlayer.status = "Off"
//          let streamId = state.audioPlayer.streamId
//          state.audioPlayer.stop()
////          state.audioPlayer = nil
//          return .run { _ in
//            // remove stream
//            await ApiModel.shared.sendRemoveStream(streamId)
//          }
//        }
        
//      case .binding(\.gain):
//        print("--->>> DaxRxCore gain = \(state.gain)")
//        if let streamId = state.audioPlayer.streamId {
//          return .run { [gain = state.gain * 100] _ in
//            if let sliceLetter = await ApiModel.shared.daxRxAudioStreams[id: streamId]?.sliceLetter {
//              for slice in await ApiModel.shared.slices where await slice.sliceLetter == sliceLetter {
//                if await ApiModel.shared.daxRxAudioStreams[id: streamId]?.clientHandle == ApiModel.shared.connectionHandle {
//                  await ApiModel.shared.sendCommand("audio stream \(streamId.hex) slice \(slice.id) gain \(Int(gain))")
//                }
//              }
//            }
//          }
//        }
//        return .none
            
//      case .binding(\.audioPlayer):
//        print("--->>> DaxRxCore audioPlayer -> \(state.audioPlayer.deviceID)")
//        print("--->>> DaxRxCore audioPlayer -> \(state.audioPlayer.gain)")
//        return .none

//      case .binding(\.isOn):
//        print("--->>> DaxRxCore binding")
//        state.status = state.isOn ? "Streaming" : "Off"
//        return .none

      case .binding(_):
        print("--->>> DaxRxCore binding")
        return .none
      }
    }
  }
  
  
}
