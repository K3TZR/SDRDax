//
//  DaxRxCore.swift
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
public struct DaxRxCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable, Identifiable {
    var audioPlayer: DaxAudioPlayer
    let channel: Int
    var isOn: Bool = false
    var showDetails = false
    var sliceLetter: String?
    var status = "Off"
    
    public var id: Int { channel }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Reducer
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
        
      case .binding(\.audioPlayer):
        if state.audioPlayer.deviceId == nil {
          // set to OFF
          state.isOn = false
        }        
        return .none

      case .binding(_):
        return .none
      }
    }
  }
}
