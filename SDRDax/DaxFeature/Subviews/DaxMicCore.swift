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
        print("DaxMicCore: onAppear isActive = \(state.isActive), status = \(state.status), isOn = \(state.isOn)")
        // if Active and isOn, start streaming
        if state.isActive && state.isOn {
          return daxStart(&state)
        }
        return .none

      case .onDisappear:
        print("DaxMicCore: onDisappear isActive = \(state.isActive), status = \(state.status), isOn = \(state.isOn)")
        // if Streaming, stop streaming
        if state.isOn && state.isActive {
          return daxStop(&state)
        }
        return .none

      case .isActiveChanged:
        print("DaxMicCore: isActiveChanged isActive = \(state.isActive), status = \(state.status), isOn = \(state.isOn)")
        return startStop(&state)
                
        // ----------------------------------------------------------------------------
        // MARK: - Binding Actions
        
      case .binding(\.isOn):
        print("DaxMicCore: binding isOn = \(state.isOn)")
        return startStop(&state)
        
      case .binding(\.gain):
        print("DaxMicCore: binding gain = \(state.gain)")
        state.audioOutput?.gain = state.gain
        return .none
        
      case .binding(\.deviceId):
        print("DaxMicCore: binding deviceId = \(state.deviceId ?? 0)")
        state.audioOutput?.deviceId = state.deviceId!
        if state.deviceId == nil {
          return daxStop(&state)
        } else {
          return startStop(&state)
        }
        
      case .binding(\.showDetails):
        print("DaxMicCore: binding showDetails = \(state.showDetails)")
        return .none
        
      case .binding(_):
        print("DaxMicCore: binding OTHER")
        return .none
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func startStop(_ state: inout State)  -> Effect<DaxMicCore.Action> {
    print("DaxMicCore: startStop isActive = \(state.isActive), status = \(state.status), isOn = \(state.isOn)")
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
  
  private func daxStart(_ state: inout State) -> Effect<DaxMicCore.Action> {
//    print("DaxMicCore: daxStart")
//    state.audioOutput = DaxAudioPlayer()
//    state.status = "Streaming"
//    return .run { [state] _ in
//      // request a stream
//      if let streamId = try await ApiModel.shared.requestDaxMicAudioStream().streamId {
//        // finish audio setup
//        state.audioOutput!.start(streamId, deviceId: state.deviceId, gain: state.gain )
//        await ApiModel.shared.daxMicAudioStreams[id: streamId]?.delegate = state.audioOutput
//        log("DaxMicCore: audioOutput STARTED, channel = \(state.channel)", .debug, #function, #file, #line)
//        
//      } else {
//        // FAILURE, tell the user it failed
//        //      alertText = "Failed to start a RemoteRxAudioStream"
//        //      showAlert = true
//        fatalError("DaxMicCore: Failed to start a RemoteRxAudioStream")
//      }
//    }
    return .none
  }
    
  private func daxStop(_ state: inout State) -> Effect<DaxMicCore.Action> {
//    print("DaxMicCore: daxStop")
//    state.status = "Off"
//    state.audioOutput?.stop()
//    state.audioOutput = nil
//    log("DaxMicCore: audioOutput STOPPED, channel = \(state.channel)", .debug, #function, #file, #line)
//    return .run { [streamId = state.audioOutput?.streamId] _ in
//      // remove stream(s)
//      await ApiModel.shared.sendRemoveStreams([streamId])
//    }
    return .none
  }
}
