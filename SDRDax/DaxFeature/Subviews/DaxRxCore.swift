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
    var isActive: Bool
    let channel: Int
    var deviceId: AudioDeviceID?
    var gain: Double
    var isOn: Bool = false
    var showDetails = false
    var sliceLetter: String?
    var status = "Off"
    
    public var id: Int { channel }

    var audioOutput: DaxAudioPlayer?
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
        print("Device onDisappear")
        if state.isOn && state.isActive {
          return daxStop(&state)
        }
        return .none

      case .isActiveChanged:
        print("Device isActiveChanged = \(state.isActive)")
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
        
      case .binding(\.deviceId):
        print("Device Id = \(state.deviceId)")
        state.audioOutput?.deviceId = state.deviceId
        return .none
        
      case .binding(\.gain):
        print("Device gain = \(state.gain)")
        state.audioOutput?.gain = state.gain
        return .none
        
      case .binding(\.isOn):
        print("Device isOn = \(state.isOn)")
        if state.isOn && state.isActive {
            return daxStart(&state)
        }
        if !state.isOn && state.isActive {
            return daxStop(&state)
        }
        return .none
        
      case .binding(_):
        return .none
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.audioOutput = DaxAudioPlayer()
    state.audioOutput?.deviceId = state.deviceId
    state.audioOutput?.gain = state.gain
    state.status = "Streaming"
    return .run { [state] _ in
      // request a stream
      if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.channel).streamId {
        // finish audio setup
        state.audioOutput?.start(streamId)
        await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.audioOutput
        log("DaxAudioPlayer: STARTED, channel = \(state.channel)", .debug, #function, #file, #line)
        
      } else {
        // FAILURE, tell the user it failed
        //      alertText = "Failed to start a RemoteRxAudioStream"
        //      showAlert = true
        fatalError("Failed to start a RemoteRxAudioStream")
      }
    }
  }
    
  private func daxStop(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.status = "Off"
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxAudioPlayer: STOPPED, channel = \(state.channel)", .debug, #function, #file, #line)
    return .run { [streamId = state.audioOutput?.streamId] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams([streamId])
    }
  }
}
