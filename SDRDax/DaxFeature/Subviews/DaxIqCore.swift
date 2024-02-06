//
//  DaxIqCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 2/3/24.
//

import ComposableArchitecture
import Foundation

import SharedFeature

@Reducer
public struct DaxIqCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable, Identifiable {
    public var id: UUID
    public var enabled: Bool = false
    public var channel: Int = 0
    public var deviceID: UInt32? = nil
    public var gain: Double = 0.5
    public var status: String = "off"
    public var sampleRate: Int = 24_000
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
}
