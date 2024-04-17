//
//  DaxIqCore.swift
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
public struct DaxIqCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable, Identifiable {
    public let id: Int
    var deviceUid: String?
//    var gain: Double
    var isOn: Bool
    var sampleRate: SampleRate
    var showDetails: Bool
    
    @Shared var isConnected: Bool

    let audioDevices = AudioDevice.getDevices()
    var audioOutput: DaxAudioOutput?
    var frequency: Double?
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
//        print("----->>>>> DaxIqCore: Binding deviceUid = \(state.deviceUid ?? "nil")")
        state.audioOutput?.setDevice(getDeviceId(state))
        if state.isOn {
          // Start (CONNECTED, status OFF, DEVICE selected)
          if state.isConnected && state.streamStatus == .off && state.deviceUid != nil {
            return daxStart(&state)
          }
        }
        return .none

      case .binding(\.sampleRate):
//        print("----->>>>> DaxIqCore: Binding gain = \(state.sampleRate)")
        state.audioOutput?.setSampleRate(state.sampleRate.rawValue)
        return .none

      case .binding(\.isOn):
//        print("----->>>>> DaxIqCore: Binding isOn = \(state.isOn)")
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
//        print("----->>>>> DaxIqCore: Binding OTHER")
        return .none
      }
    }
  }
  
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State) -> Effect<DaxIqCore.Action> {
    state.audioOutput = DaxAudioOutput(deviceId: getDeviceId(state), gain: 100, sampleRate: state.sampleRate.rawValue)
    state.streamStatus = .streaming
    return .run { [state] send in
      // request a stream, reply to handler
      await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.id - 5, replyTo: state.audioOutput!.streamReplyHandler)
      log("DaxIqCore: stream REQUESTED, channel = \(state.id - 5)", .debug, #function, #file, #line)
    }
  }

  private func daxStop(_ state: inout State) -> Effect<DaxIqCore.Action> {
    let streamId = state.audioOutput?.streamId
    state.streamStatus = .off
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxIqCore: stream STOPPED, channel = \(state.id - 5)", .debug, #function, #file, #line)
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
    fatalError("DaxIqCore: Device Id NOT FOUND")
  }
}
