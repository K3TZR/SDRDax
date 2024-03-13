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
    var deviceUid: String?
    var gain: Double
    var isOn: Bool
    var showDetails: Bool
    @Shared var isConnected: Bool


    var audioOutput: DaxAudioPlayer?
    let devices = AudioDevice.getDevices()
    var sliceLetter: String = "NO Slice"
    var status: DaxStatus = .off

    public var id: Int { channel }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)

    case activeSliceChanged(String?)
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
        if state.isConnected && state.isOn {
          return daxStart(&state)
        }
        return .none

      case .onDisappear:
        // if Streaming, stop streaming
        if state.isConnected && state.status == .streaming {
          return daxStop(&state)
        }
        return .none

      case let .activeSliceChanged(letter):
        print("activeSliceChanged: activeSlice = \(letter ?? "nil")")
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
  
  private func updateState(_ state: inout State) -> Effect<DaxRxCore.Action> {
    if state.deviceUid != nil { state.audioOutput?.setDevice(getDeviceId(state)) }
    state.audioOutput?.setGain(state.gain)

    // Start (CONNECTED, status OFF, is ON, DEVICE selected)
    if state.isConnected && state.status == .off && state.isOn && state.deviceUid != nil {
      return daxStart(&state)
    }

    // Stop (CONNECTED, not ON or no DEVICE)
    if state.isConnected && state.status == .streaming && (!state.isOn || state.deviceUid == nil) {
      return daxStop(&state)
    }

    // Stop (not CONNECTED, status STREAMING)
    if !state.isConnected && state.status == .streaming {
      return daxStop(&state)
    }
    return .none
  }
  
  private func daxStart(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.audioOutput = DaxAudioPlayer(deviceId: getDeviceId(state), gain: state.gain, sampleRate: 24_000)
    state.status = .streaming
    return .run { [state] send in
      // request a stream, reply to handler
      await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.channel, replyTo: state.audioOutput!.streamReplyHandler)
      log("DaxRxCore: stream REQUESTED, channel = \(state.channel)", .debug, #function, #file, #line)
    }
  }

  private func daxStop(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.status = .off
    state.audioOutput?.stop()
    state.audioOutput = nil
    return .run { [streamId = state.audioOutput?.streamId, channel = state.channel] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams([streamId])
      log("DaxRxCore: stream STOPPED, channel = \(channel)", .debug, #function, #file, #line)
    }
  }
  
  private func getDeviceId(_ state: State) -> AudioDeviceID {
    for device in state.devices where device.uid == state.deviceUid! {
      return device.id
    }
    fatalError("DaxRxCore: Device Id NOT FOUND")
  }
}
