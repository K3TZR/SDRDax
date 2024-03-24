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

@Reducer
public struct DaxIqCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable, Identifiable {
    let channel: Int
    var deviceUid: String?
    var isOn: Bool
    var sampleRate: Double
    var showDetails: Bool
    @Shared var isConnected: Bool
    @Shared var isActive: Bool

    var audioOutput: DaxAudioPlayer?
    let devices = AudioDevice.getDevices()
    var frequency: Double?
    var streamStatus = "Off"

    public var id: Int { channel }
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
        if state.isConnected && state.isOn {
          return iqStart(&state)
        }
        return .none
        
      case .onDisappear:
        // if Streaming, stop streaming
        if state.isOn && state.isConnected {
          return iqStop(&state)
        }
        return .none
        
      case .isConnectedChanged:
        // if now Active and isOn, start streaming
        if state.isConnected && state.isOn {
          return iqStart(&state)
        }
        // if now not Active and isOn, stop streaming
        if !state.isConnected && state.isOn {
          return iqStop(&state)
        }
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
        
      case .binding(_):
        // DeviceId, Gain, or isOn changed
        state.audioOutput?.deviceId = getDeviceId(state)
        if state.isOn && state.isConnected {
          return iqStart(&state)
        }
        if !state.isOn && state.isConnected {
          return iqStop(&state)
        }
        return .none
      }
    }
  }
  
  
  // ----------------------------------------------------------------------------
  // MARK: - IQ effect methods
  
  private func iqStart(_ state: inout State) -> Effect<DaxIqCore.Action> {
    //    state.audioOutput = DaxAudioPlayer()
    //    state.status = "Streaming"
    //    return .run { [state] _ in
    //      // request a stream
    //      if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.ch.channel).streamId {     // FIXME: Mic Stream
    //        // finish audio setup
    //        state.audioOutput?.start(streamId, deviceId: state.ch.deviceId, gain: 100 )
    //        await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.audioOutput
    //        log("DaxRxCore: audioOutput STARTED, channel = \(state.ch.channel)", .debug, #function, #file, #line)
    //
    //      } else {
    //        // FAILURE, tell the user it failed
    //        //      alertText = "Failed to start a RemoteRxAudioStream"
    //        //      showAlert = true
    //        fatalError("DaxRxCore: Failed to start a RemoteRxAudioStream")
    //      }
    //    }
    return .none
  }
  
  private func iqStop(_ state: inout State) -> Effect<DaxIqCore.Action> {
    //    state.status = "Off"
    //    state.audioOutput?.stop()
    //    state.audioOutput = nil
    //    log("DaxRxCore: audioOutput STOPPED, channel = \(state.ch.channel)", .debug, #function, #file, #line)
    //    return .run { [streamId = state.audioOutput?.streamId] _ in
    //      // remove stream(s)
    //      await ApiModel.shared.sendRemoveStreams([streamId])
    //    }
    return .none
  }
  
  private func getDeviceId(_ state: State) -> AudioDeviceID {
    for device in state.devices where device.uid == state.deviceUid {
      return device.id
    }
    fatalError("DaxIqCore: Device Id NOT FOUND")
  }
}
