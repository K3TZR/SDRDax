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
import XCGLogFeature

@Reducer
public struct DaxRxCore {
  
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
//        print("----->>>>> DaxRxCore: Binding deviceUid = \(state.deviceUid ?? "nil")")
        state.audioOutput?.setDevice(getDeviceId(state))
        if state.isOn {
          // Start (CONNECTED, status OFF, DEVICE selected)
          if state.isConnected && state.streamStatus == .off && state.deviceUid != nil {
            return daxStart(&state)
          }
        }
        return .none

      case .binding(\.gain):
//        print("----->>>>> DaxRxCore: Binding gain = \(state.gain)")
        state.audioOutput?.setGain(state.gain)
        return .none

      case .binding(\.isOn):
//        print("----->>>>> DaxRxCore: Binding isOn = \(state.isOn)")
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
//        print("----->>>>> DaxRxCore: Binding OTHER")
        return .none
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.audioOutput = DaxAudioOutput(deviceId: getDeviceId(state), gain: state.gain)
    state.streamStatus = .streaming
    return .run { [state] send in
      // request a stream, reply to handler
      await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.id, replyTo: state.audioOutput!.streamReplyHandler)
      log("DaxRxCore: stream REQUESTED, channel = \(state.id)", .debug, #function, #file, #line)
    }
  }

  private func daxStop(_ state: inout State) -> Effect<DaxRxCore.Action> {
    let streamId = state.audioOutput?.streamId
    state.streamStatus = .off
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxRxCore: stream STOPPED, channel = \(state.id)", .debug, #function, #file, #line)
    if let streamId {
      return .run { [streamId] _ in
        // remove stream(s)
        await ApiModel.shared.sendRemoveStreams([streamId])
      }
    }
    return .none
  }
  
  private func getDeviceId(_ state: State) -> AudioDeviceID {
    for device in state.audioDevices where device.uid == state.deviceUid! {
      return device.id
    }
    fatalError("DaxRxCore: Device Id NOT FOUND")
  }
}
