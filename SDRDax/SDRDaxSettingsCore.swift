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
    @Shared(.fileStorage(.appSettings)) var appSettings: AppSettings = AppSettings()
//    @Shared(.appStorage("iqEnabled")) var iqEnabled: Bool = true
//    @Shared(.appStorage("micEnabled")) var micEnabled: Bool = true
//    @Shared(.appStorage("rxEnabled")) var rxEnabled: Bool = true
//    @Shared(.appStorage("txEnabled")) var txEnabled: Bool = true
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
