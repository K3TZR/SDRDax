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
  public struct State: Equatable {
    public static func == (lhs: SDRDaxSettingsCore.State, rhs: SDRDaxSettingsCore.State) -> Bool {
      lhs.iqEnabled == rhs.iqEnabled &&
      lhs.micEnabled ==  rhs.micEnabled &&
      lhs.rxEnabled ==  rhs.rxEnabled &&
      lhs.txEnabled ==  rhs.txEnabled
    }
        
    // persistent
    @Shared var iqEnabled: Bool
    @Shared var micEnabled: Bool
    @Shared var rxEnabled: Bool
    @Shared var txEnabled: Bool

    @Shared var autoStartEnabled: Bool
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


    Reduce { state, action in
      switch action {
        
        // ----------------------------------------------------------------------------
        // MARK: - Root Actions
        
                
        // ----------------------------------------------------------------------------
        // MARK: - Root Binding Actions
        
      case .binding(_):
        return .none
      }
    }
  }
}
