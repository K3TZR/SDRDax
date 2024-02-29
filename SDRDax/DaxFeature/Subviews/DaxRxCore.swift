//
//  DaxRxCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 2/3/24.
//

import AVFoundation
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
    var deviceId: AudioDeviceID?
    var gain: Double
    var isOn: Bool
    var showDetails: Bool
    var sliceLetter: String?
    var status: String = "Off"

    public var id: Int { channel }

    var audioOutput: DaxAudioPlayer?
    
    @Shared var isActive: Bool
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case isActiveChanged
    case onDisappear
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Reducer
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
        
        // ----------------------------------------------------------------------------
        // MARK: - View Actions
        
      case .onDisappear:
        print("--->>> Channel: onDisappear")
        state.isActive = false
        if state.isOn && state.isActive {
          return daxStop(&state)
        }
        return .none

      case .isActiveChanged:
        print("--->>> Channel: isActiveChanged = \(state.isActive)")
        state.audioOutput?.gain = state.gain
        if state.isActive && state.isOn {
          return daxStart(&state)
        }
        
        if !state.isActive && state.isOn {
          return daxStop(&state)
        }
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
        
//      case .binding(\.isActive):
//        print("--->>> Channel: stationIsActive = \(state.isActive)")
//        state.audioOutput?.gain = state.gain
//        if state.isActive && state.isOn {
//          return daxStart(&state)
//        }
//        
//        if !state.isActive && state.isOn {
//          return daxStop(&state)
//        }
//        return .none
        
      case .binding(\.deviceId):
        print("--->>> Channel: Id = \(state.deviceId)")
        state.audioOutput?.deviceId = state.deviceId
        return .none
        
      case .binding(\.gain):
        print("--->>> Channel: gain = \(state.gain)")
        state.audioOutput?.gain = state.gain
        return .none
        
      case .binding(\.isOn):
        print("--->>> Channel: isOn = \(state.isOn)")
        if state.isOn && state.isActive {
            return daxStart(&state)
        }
        if !state.isOn && state.isActive {
            return daxStop(&state)
        }
        return .none

      case .binding(\.showDetails):
        print("--->>> Channel: showDetails = \(state.showDetails)")
        return .none
        
      case .binding(_):
        print("--->>> Channel: MISC gain = \(state.gain)")
        print("--->>> Channel: MISC Id = \(state.deviceId)")
        print("--->>> Channel: MISC isOn = \(state.isOn)")
        print("--->>> Channel: MISC showDetails = \(state.showDetails)")
        return .none
     }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.audioOutput = DaxAudioPlayer()
    state.status = "Streaming"
    return .run { [state] _ in
      // request a stream
      if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.channel).streamId {     // FIXME: Mic Stream
        // finish audio setup
        state.audioOutput?.start(streamId, deviceId: state.deviceId, gain: state.gain )
        await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.audioOutput
        log("DaxRxCore: audioOutput STARTED, channel = \(state.channel)", .debug, #function, #file, #line)
        
      } else {
        // FAILURE, tell the user it failed
        //      alertText = "Failed to start a RemoteRxAudioStream"
        //      showAlert = true
        fatalError("DaxRxCore: Failed to start a RemoteRxAudioStream")
      }
    }
  }
    
  private func daxStop(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.status = "Off"
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxRxCore: audioOutput STOPPED, channel = \(state.channel)", .debug, #function, #file, #line)
    return .run { [streamId = state.audioOutput?.streamId] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams([streamId])
    }
  }  
}
