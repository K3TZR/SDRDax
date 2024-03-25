//
//  SDRDaxSettingsCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 3/19/24.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct SDRDaxSettingsCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State {
    // persistent
    @Shared var iqEnabled: Bool
    @Shared var micEnabled: Bool
    @Shared var rxEnabled: Bool
    @Shared var txEnabled: Bool

    @Shared var autoStartEnabled: Bool
    @Shared var reducedBandwidth: Bool
    @Shared var smartlinkEnabled: Bool
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
