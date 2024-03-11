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
    var deviceId: AudioDeviceID?
    var gain: Double
    var isOn: Bool
    var showDetails: Bool
    
    var sliceLetter: String?
    var status: String = "Off"

    public var id: Int { channel }

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
    
    case replyReceived(String?)
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
        print("DaxRxCore: onAppear isActive = \(state.isActive), status = \(state.status), isOn = \(state.isOn)")
        // if Active and isOn, start streaming
        if state.isActive && state.isOn {
          return daxStart(&state)
        }
        return .none

      case .onDisappear:
        print("DaxRxCore: onDisappear isActive = \(state.isActive), status = \(state.status), isOn = \(state.isOn)")
        // if Streaming, stop streaming
        if state.isOn && state.isActive {
          return daxStop(&state)
        }
        return .none

      case .isActiveChanged:
        return startStop(&state)
                
      case let .replyReceived(reply):
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
        
      case .binding(\.isOn):
        return startStop(&state)
        
      case .binding(\.gain):
        state.audioOutput?.gain = state.gain
        return .none
        
      case .binding(\.deviceId):
        if state.deviceId == nil {
          return daxStop(&state)
        } else {
          state.audioOutput?.deviceId = state.deviceId!
          return startStop(&state)
        }
        
      case .binding(\.showDetails):
        return .none
        
      case .binding(_):
        return .none
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func startStop(_ state: inout State) -> Effect<DaxRxCore.Action> {
    // if now Active and isOn, start streaming
    if state.isActive && state.status == "Off" && state.isOn {
      return daxStart(&state)
    }
    if state.isActive && state.status == "Streaming" && !state.isOn {
      return daxStop(&state)
    }

    // if now not Active and isOn, stop streaming
    if !state.isActive && state.isOn {
      return daxStop(&state)
    }
    return .none
  }
  
  private func daxStart(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.audioOutput = DaxAudioPlayer(deviceId: state.deviceId!, gain: state.gain, sampleRate: 24_000)
    state.status = "Streaming"
    return .run { [state] send in
      // request a stream & wait for the reply
      await ApiModel.shared.requestDaxRxAudioStream(daxChannel: state.channel, replyTo: state.audioOutput!.streamReplyHandler)
    }
  }

  private func daxStop(_ state: inout State) -> Effect<DaxRxCore.Action> {
    state.status = "Off"
    state.audioOutput?.stop()
    state.audioOutput = nil
    log("DaxRxCore: audioOutput STOPPED, channel = \(state.channel)", .debug, #function, #file, #line)
    return .run { [streamId = state.audioOutput?.streamId] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams([streamId])
    }
  }
}
