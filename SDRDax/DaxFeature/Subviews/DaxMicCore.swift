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
import XCGLogFeature

@Reducer
public struct DaxMicCore {
  
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
    var audioOutput: DaxAudioOutput?
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
//        print("----->>>>> DaxMicCore: Binding deviceUid = \(state.deviceUid ?? "nil")")
//        state.audioOutput?.setDevice(getDeviceId(state))
        if state.isOn {
          // Start (CONNECTED, status OFF, DEVICE selected)
          if state.isConnected && state.streamStatus == .off && state.deviceUid != nil {
            return daxStart(&state)
          }
        }
        return .none

      case .binding(\.gain):
//        print("----->>>>> DaxMicCore: Binding gain = \(state.gain)")
        state.audioOutput?.setGain(state.gain)
        return .none

      case .binding(\.isOn):
//        print("----->>>>> DaxMicCore: Binding isOn = \(state.isOn)")
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
//        print("----->>>>> DaxMicCore: Binding OTHER")
        return .none
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State) -> Effect<DaxMicCore.Action> {
//    state.audioOutput = DaxAudioOutput(deviceId: getDeviceId(state), gain: state.gain)
    state.audioOutput = DaxAudioOutput()
    state.streamStatus = .streaming
    // request a stream, reply to handler
    ApiModel.shared.requestStream(StreamType.daxMicAudioStream, replyTo: state.audioOutput!.streamReplyHandler)
    log("DaxMicCore: stream REQUESTED", .debug, #function, #file, #line)
    return .none
  }

  private func daxStop(_ state: inout State) -> Effect<DaxMicCore.Action> {
    let streamId = state.audioOutput?.streamId
    state.streamStatus = .off
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxMicCore: stream STOPPED", .debug, #function, #file, #line)
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
    fatalError("DaxMicCore: Device Id NOT FOUND")
  }
}
