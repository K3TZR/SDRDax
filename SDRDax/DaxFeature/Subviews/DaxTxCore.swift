//
//  DaxTxCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 3/1/24.
//

import AVFoundation
import ComposableArchitecture
import Foundation

import FlexApiFeature
import DaxAudioFeature
import XCGLogFeature
import SharedFeature

@Reducer
public struct DaxTxCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable, Identifiable {
    public let id: Int
    var deviceUid: String?
    var gain: Double
    var isOn: Bool
    var sampleRate: SampleRate
    var showDetails: Bool

    @Shared var isConnected: Bool

    let audioDevices = AudioDevice.getDevices()
    var audioInput: DaxAudioInput?
    var streamStatus: StreamStatus = .off
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    
    case onAppear
    case onDisappear
    case isConnectedChanged
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
        if state.isConnected && state.isOn && state.streamStatus != .streaming {
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
        // start streaming
        if state.isConnected && state.isOn && state.streamStatus != .streaming {
          return daxStart(&state)
        }
        // stop streaming
        if !state.isConnected && state.streamStatus == .streaming {
          return daxStop(&state)
        }
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
        
      case .binding(\.deviceUid):
        print("----->>>>> DaxTxCore: Binding deviceUid = \(state.deviceUid ?? "nil")")
        state.audioInput?.setDevice(getDeviceId(state))
        if state.isOn {
          // Start (CONNECTED, status OFF, DEVICE selected)
          if state.isConnected && state.streamStatus == .off && state.deviceUid != nil {
            return daxStart(&state)
          }
        }
        return .none

      case .binding(\.gain):
        print("----->>>>> DaxTxCore: Binding gain = \(state.gain)")
        state.audioInput?.setGain(state.gain)
        return .none

      case .binding(\.isOn):
        print("----->>>>> DaxTxCore: Binding isOn = \(state.isOn)")
        if state.isOn {
          // Start (CONNECTED, status OFF, DEVICE selected)
          if state.isConnected && state.streamStatus == .off && state.deviceUid != nil {
            return daxStart(&state)
          }
        } else {
          // Stop (CONNECTED, status STREAMING)
          if state.isConnected && state.streamStatus == .streaming {
            return daxStop(&state)
          }
        }
        return .none

      case .binding(_):
        print("----->>>>> DaxTxCore: Binding OTHER")
        return .none
      }
    }
  }
  
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State) -> Effect<DaxTxCore.Action> {
    state.audioInput = DaxAudioInput(deviceId: getDeviceId(state), gain: state.gain)
    state.streamStatus = .streaming
    // request a stream, reply to handler
    ApiModel.shared.requestStream(StreamType.daxTxAudioStream, replyTo: state.audioInput!.streamReplyHandler)
    log("DaxTxCore: stream REQUESTED", .debug, #function, #file, #line)
    return .none
  }
  
  private func daxStop(_ state: inout State) -> Effect<DaxTxCore.Action> {
    let streamId = state.audioInput?.streamId
    state.streamStatus = .off
    state.audioInput?.stop()
    state.audioInput = nil
    log("DaxTxCore: stream STOPPED", .debug, #function, #file, #line)
    if let streamId {
      // remove stream(s)
      ApiModel.shared.removeStream(streamId)
    }
    return .none
  }

  private func getDeviceId(_ state: State) -> AudioDeviceID {
    for device in state.audioDevices where device.uid == state.deviceUid {
      return device.id
    }
    fatalError("DaxTxCore: Device Id NOT FOUND")
  }
}
