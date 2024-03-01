//
//  DaxMicCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 3/1/24.
//

import AVFoundation
import ComposableArchitecture
import Foundation

import FlexApiFeature
import DaxAudioFeature
import SharedFeature

@Reducer
public struct DaxMicCore {
  
  public init() {}

  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable, Identifiable {
    var ch: MicChannel
    var sliceLetter: String?
    var status: String = "Off"

    public var id: Int { ch.channel }

    var audioOutput: DaxAudioPlayer?
    
    @Shared var isActive: Bool
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)

    case isActiveChanged
    case onAppear
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
        
      case .onAppear:
        print("--->>> Channel: onAppear")
        // if Active and isOn, start streaming
        state.audioOutput?.gain = state.ch.gain
        if state.isActive && state.ch.isOn {
          return daxStart(&state)
        }
        return .none

      case .onDisappear:
        print("--->>> Channel: onDisappear")
        // if Streaming, stop streaming
        state.isActive = false
        if state.ch.isOn && state.isActive {
          return daxStop(&state)
        }
        return .none

      case .isActiveChanged:
        print("--->>> Channel: isActiveChanged = \(state.isActive)")
        // if now Active and isOn, start streaming
        state.audioOutput?.gain = state.ch.gain
        if state.isActive && state.ch.isOn {
          return daxStart(&state)
        }
        // if now not Active and isOn, stop streaming
        if !state.isActive && state.ch.isOn {
          return daxStop(&state)
        }
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
        
      case .binding(_):
        // DeviceId, Gain, or isOn changed
        state.audioOutput?.gain = state.ch.gain
        state.audioOutput?.deviceId = state.ch.deviceId
        if state.ch.isOn && state.isActive {
            return daxStart(&state)
        }
        if !state.ch.isOn && state.isActive {
            return daxStop(&state)
        }
        return .none
     }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State) -> Effect<DaxMicCore.Action> {
    state.audioOutput = DaxAudioPlayer()
    state.status = "Streaming"
    return .run { [state] _ in
      // request a stream
      if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.ch.channel).streamId {     // FIXME: Mic Stream
        // finish audio setup
        state.audioOutput?.start(streamId, deviceId: state.ch.deviceId, gain: state.ch.gain )
        await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.audioOutput
        log("DaxMicCore: audioOutput STARTED, channel = \(state.ch.channel)", .debug, #function, #file, #line)
        
      } else {
        // FAILURE, tell the user it failed
        //      alertText = "Failed to start a RemoteRxAudioStream"
        //      showAlert = true
        fatalError("DaxMicCore: Failed to start a RemoteRxAudioStream")
      }
    }
  }
    
  private func daxStop(_ state: inout State) -> Effect<DaxMicCore.Action> {
    state.status = "Off"
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxMicCore: audioOutput STOPPED, channel = \(state.ch.channel)", .debug, #function, #file, #line)
    return .run { [streamId = state.audioOutput?.streamId] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams([streamId])
    }
  }
}
