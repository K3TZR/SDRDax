//
//  SpinnerCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 2/22/24.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct SpinnerFeature {

  public init() {}

  @ObservableState
  public struct State {
    var selection: String

    public init(selection: String) {
      self.selection = selection
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
  }
}
