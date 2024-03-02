//
//  DaxIqCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 2/3/24.
//

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
    var ch: IqChannel
    var frequency: Double?
    var status = "Off"
    
    var audioOutput: DaxAudioPlayer?
    
    public var id: Int { ch.channel }
    
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
        // if Active and isOn, start streaming
        if state.isActive && state.ch.isOn {
          return iqStart(&state)
        }
        return .none
        
      case .onDisappear:
        // if Streaming, stop streaming
        state.isActive = false
        if state.ch.isOn && state.isActive {
          return iqStop(&state)
        }
        return .none
        
      case .isActiveChanged:
        // if now Active and isOn, start streaming
        if state.isActive && state.ch.isOn {
          return iqStart(&state)
        }
        // if now not Active and isOn, stop streaming
        if !state.isActive && state.ch.isOn {
          return iqStop(&state)
        }
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
        
      case .binding(_):
        // DeviceId, Gain, or isOn changed
        state.audioOutput?.deviceId = state.ch.deviceId
        if state.ch.isOn && state.isActive {
          return iqStart(&state)
        }
        if !state.ch.isOn && state.isActive {
          return iqStop(&state)
        }
        return .none
      }
    }
  }
  
  
  // ----------------------------------------------------------------------------
  // MARK: - IQ effect methods
  
  private func iqStart(_ state: inout State) -> Effect<DaxIqCore.Action> {
    state.audioOutput = DaxAudioPlayer()
    state.status = "Streaming"
    return .run { [state] _ in
      // request a stream
      if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.ch.channel).streamId {     // FIXME: Mic Stream
        // finish audio setup
        state.audioOutput?.start(streamId, deviceId: state.ch.deviceId, gain: 100 )
        await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.audioOutput
        log("DaxRxCore: audioOutput STARTED, channel = \(state.ch.channel)", .debug, #function, #file, #line)
        
      } else {
        // FAILURE, tell the user it failed
        //      alertText = "Failed to start a RemoteRxAudioStream"
        //      showAlert = true
        fatalError("DaxRxCore: Failed to start a RemoteRxAudioStream")
      }
    }
  }
  
  private func iqStop(_ state: inout State) -> Effect<DaxIqCore.Action> {
    state.status = "Off"
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxRxCore: audioOutput STOPPED, channel = \(state.ch.channel)", .debug, #function, #file, #line)
    return .run { [streamId = state.audioOutput?.streamId] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams([streamId])
    }
  }
}
