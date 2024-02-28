//
//  DaxIqCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 2/3/24.
//

import ComposableArchitecture
import Foundation

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
    var device: UInt32?
    var frequency: Double?
    var isActive = false
    var isOn = false
    var sampleRate = 24_000
    var showDetails = false
    var status = "Off"

    public var id: Int { channel }

    var audioOutput: DaxAudioPlayer?
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
  }
  
  // FIXME: Stream ????
}
