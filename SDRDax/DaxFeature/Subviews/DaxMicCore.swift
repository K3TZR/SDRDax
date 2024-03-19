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
    @Shared var isConnected: Bool

    var audioOutput: DaxAudioPlayer?
    let devices = AudioDevice.getDevices()
    var sliceLetter: String?
    var streamStatus: StreamStatus = .off

    public var id: Int { ch.channel }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)

    case isConnectedChanged
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
        // if Active and isOn, start streaming
        if state.isConnected && state.ch.isOn {
          return daxStart(&state)
        }
        return .none

      case .onDisappear:
        // if Streaming, stop streaming
        if state.isConnected && state.streamStatus == .streaming {
          return daxStop(&state)
        }
        return .none

      case .isConnectedChanged:
        return updateState(&state)
                
        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
                
      case .binding(_):
        return updateState(&state)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func updateState(_ state: inout State) -> Effect<DaxMicCore.Action> {
    if state.ch.deviceUid != nil { state.audioOutput?.setDevice(getDeviceId(state)) }
    state.audioOutput?.setGain(state.ch.gain)

    // Start (CONNECTED, status OFF, is ON, DEVICE selected)
    if state.isConnected && state.streamStatus == .off && state.ch.isOn && state.ch.deviceUid != nil {
      return daxStart(&state)
    }

    // Stop (CONNECTED, not ON or no DEVICE)
    if state.isConnected && state.streamStatus == .streaming && (!state.ch.isOn || state.ch.deviceUid == nil) {
      return daxStop(&state)
    }

    // Stop (not CONNECTED, status STREAMING)
    if !state.isConnected && state.streamStatus == .streaming {
      return daxStop(&state)
    }
    return .none
  }
  
  private func daxStart(_ state: inout State) -> Effect<DaxMicCore.Action> {
    state.audioOutput = DaxAudioPlayer(deviceId: getDeviceId(state), gain: state.ch.gain, sampleRate: 24_000)
    state.streamStatus = .streaming
    return .run { [state] send in
      // request a stream, reply to handler
      await ApiModel.shared.requestDaxMicAudioStream(replyTo: state.audioOutput!.streamReplyHandler)
      log("DaxMicCore: stream REQUESTED, channel = \(state.ch.channel)", .debug, #function, #file, #line)
    }
  }

  private func daxStop(_ state: inout State) -> Effect<DaxMicCore.Action> {
    state.streamStatus = .off
    state.audioOutput?.stop()
    state.audioOutput = nil
    return .run { [streamId = state.audioOutput?.streamId, channel = state.ch.channel] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams([streamId])
      log("DaxMicCore: stream STOPPED, channel = \(channel)", .debug, #function, #file, #line)
    }
  }
  
  private func getDeviceId(_ state: State) -> AudioDeviceID {
    for device in state.devices where device.uid == state.ch.deviceUid {
      return device.id
    }
    fatalError("DaxMicCore: Device Id NOT FOUND")
  }
}
