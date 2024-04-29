//
//  SDRDaxCore.swift
//  SDRDax
//
//  Created by Douglas Adams on 1/30/24.
//

import AVFoundation
import Cocoa
import ComposableArchitecture
import Foundation

import DaxAudioFeature
import FlexApiFeature
import ListenerFeature
import LoginFeature
import SharedFeature
import XCGLogFeature

// ----------------------------------------------------------------------------
// MARK: - Definitions

extension URL {
  static let channels = Self
    .applicationSupportDirectory
    .appending(path: "channels.json")
}

extension URL {
  static let appSettings = Self
    .applicationSupportDirectory
    .appending(path: "appSettings.json")
}

enum SampleRate: Int, CaseIterable, Codable {
  case r24 = 24_000
  case r48 = 48_000
  case r96 = 96_000
  case r192 = 192_000
}

enum ChannelType: String, Codable {
  case rx
  case tx
  case mic
  case iq
}

struct AppSettings: Equatable, Codable {
  var autoSelection: String? = nil
  var autoStartEnabled: Bool = false
  var iqEnabled: Bool = true
  var micEnabled: Bool = true
  var mtuValue: Int = 1_300
  var previousIdToken: String? = nil
  var reducedBandwidth: Bool = false
  var refreshToken: String? = nil
  var rxEnabled: Bool = true
  var smartlinkEnabled: Bool = false
  var smartlinkLoginRequired: Bool = false
  var smartlinkUser: String = ""
  var txEnabled: Bool = true
  
  var channels: IdentifiedArrayOf<Channel> = [Channel(id: 0, channelType: .mic, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 1, channelType: .rx, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 2, channelType: .rx, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 3, channelType: .rx, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 4, channelType: .rx, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 5, channelType: .tx, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 6, channelType: .iq, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 7, channelType: .iq, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 8, channelType: .iq, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
                                                                               Channel(id: 9, channelType: .iq, deviceUid: nil, gain: 50, isOn: false, sampleRate: .r24, showDetails: false),
  ]
}

struct Channel: Identifiable, Equatable, Codable, Sendable {
  public var id: Int
  var channelType: ChannelType
  var deviceUid: String?
  var gain: Double
  var isOn: Bool
  var sampleRate: SampleRate
  var showDetails: Bool
}


@Reducer
public struct SDRDaxCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State {
    // persistent (in memory only)
    @Shared(.inMemory("isActive")) var isActive = false
    @Shared(.inMemory("isConnected")) var isConnected = false

    // persistent (File Storage)
    @Shared(.fileStorage(.appSettings)) var appSettings: AppSettings = AppSettings()
    
    // non-persistent
    var initialized = false
    var selection: String? = nil
    var previousSelection: String? = nil

    var iqStates: IdentifiedArrayOf<DaxIqCore.State> = []
    var micStates: IdentifiedArrayOf<DaxMicCore.State> = []
    var rxStates: IdentifiedArrayOf<DaxRxCore.State> = []
    var txStates: IdentifiedArrayOf<DaxTxCore.State> = []

    @Presents var showAlert: AlertState<Action.Alert>?
    @Presents var showLogin: LoginFeature.State?
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    
    case bandwidthTapped
    case connect
    case connectionTapped
    case modeTapped
    case onAppear
    case onDisappear
    case setAutoSelection(String?)
    
    // subview actions
    case iqStates(IdentifiedActionOf<DaxIqCore>)
    case micStates(IdentifiedActionOf<DaxMicCore>)
    case rxStates(IdentifiedActionOf<DaxRxCore>)
    case txStates(IdentifiedActionOf<DaxTxCore>)

    // secondary actions
    case connectionStatus(ConnectionState)
    case saveTokens(Tokens)
    case showAlert(Alert,String)
    case showLoginSheet
    
    // navigation actions
    case alert(PresentationAction<Alert>)
    case login(PresentationAction<LoginFeature.Action>)

    // alert sub-actions
    public enum Alert : String, Sendable {
      case connectFailed = "Connect FAILED"
      case disconnectFailed = "Disconnect FAILED"
      case remoteRxAudioFailed = "RemoteRxAudio FAILED"
      case smartlinkLoginFailed = "Smartlink login FAILED"
      case unknownError = "Unknown error logged"
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Reducer
  
  public var body: some ReducerOf<Self> {
    BindingReducer()

    EmptyReducer()
      .forEach(\.iqStates, action: \.iqStates) {
        DaxIqCore()
      }

    EmptyReducer()
      .forEach(\.micStates, action: \.micStates) {
        DaxMicCore()
      }
    EmptyReducer()
      .forEach(\.rxStates, action: \.rxStates) {
        DaxRxCore()
      }

    EmptyReducer()
      .forEach(\.txStates, action: \.txStates) {
        DaxTxCore()
      }

    Reduce { state, action in
      switch action {
        
        // ----------------------------------------------------------------------------
        // MARK: - Root Actions
        
      case .onAppear:
        // perform initialization
        return initState(&state)
        
      case .onDisappear:
        return .run {_ in
          await closeAuxiliaryWindows()
        }
        
      case .bandwidthTapped:
        state.appSettings.reducedBandwidth.toggle()
        return .none
        
      case .connect:
        return connect(state)
                
      case .connectionTapped:
        state.appSettings.smartlinkEnabled.toggle()
        return .none

      case .modeTapped:
        state.appSettings.autoStartEnabled.toggle()
        return .none

      case let .setAutoSelection(selection):
        state.appSettings.autoSelection = selection
        return .none
                
        // ----------------------------------------------------------------------------
        // MARK: - Root Binding Actions
        
      case .binding(\.appSettings.smartlinkEnabled):
        if state.appSettings.smartlinkEnabled {
          return .concatenate(localListenerStop(), smartlinkListenerStart(&state))
        } else {
          return .concatenate( smartlinkListenerStop(), localListenerStart())
        }

      case .binding(\.selection):
        if state.selection == nil {
          if state.isActive{
            state.isActive = false
            return disconnect()
          }
        } else {
          if state.selection != state.previousSelection {
            state.isActive = ListenerModel.shared.stations[id: state.selection!] != nil
            if state.isActive { return connect(state) }
          }
        }
        return .none

      case .binding(_):

        print("----->>>>> SDRDaxCore: Binding")
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Effect Actions
        
      case let .connectionStatus(status):
        // identify new state and take appropriate action(s)
        return connectionStatus(&state, status)
        
      case let .saveTokens(tokens):
        if tokens.idToken != nil {
          // success
          state.appSettings.previousIdToken = tokens.idToken
          state.appSettings.refreshToken = tokens.refreshToken
        } else {
          // failure
          state.appSettings.previousIdToken = nil
          state.appSettings.refreshToken = nil
        }
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - View Presentation
        
      case let .showAlert(alertType, message):
        switch alertType {
        case .connectFailed, .disconnectFailed, .unknownError:        // TODO:
          break
          //        case .remoteRxAudioFailed:
          //          state.remoteRxAudioEnabled = false
        case .smartlinkLoginFailed:
          state.appSettings.smartlinkEnabled = false
        default: break
        }
        state.showAlert = AlertState(title: TextState(alertType.rawValue), message: TextState(message))
        return .none
        
      case .showLoginSheet:
        state.showLogin = LoginFeature.State(user: state.appSettings.smartlinkUser)
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Alert Actions
        
      case .alert(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Login Actions
        
      case .login(.presented(.cancelButtonTapped)):
        state.appSettings.smartlinkEnabled = false
        return .none
        
      case let .login(.presented(.loginButtonTapped(user, password))):
        // attempt to login to Smartlink
        return smartlinkUserLogin(&state, user, password)
        
      case .login(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Subview Actions
        
      case let .iqStates(.element(id: id, action: _)):
        state.appSettings.channels[id: id]!.deviceUid = state.iqStates[id: id]!.deviceUid
        state.appSettings.channels[id: id]!.sampleRate = state.iqStates[id: id]!.sampleRate
        state.appSettings.channels[id: id]!.isOn = state.iqStates[id: id]!.isOn
        state.appSettings.channels[id: id]!.showDetails = state.iqStates[id: id]!.showDetails
        return .none

      case let .micStates(.element(id: id, action: _)):
        state.appSettings.channels[id: id]!.deviceUid = state.micStates[id: id]!.deviceUid
        state.appSettings.channels[id: id]!.gain = state.micStates[id: id]!.gain
        state.appSettings.channels[id: id]!.isOn = state.micStates[id: id]!.isOn
        state.appSettings.channels[id: id]!.showDetails = state.micStates[id: id]!.showDetails
        return .none

      case let .rxStates(.element(id: id, action: _)):
        state.appSettings.channels[id: id]!.deviceUid = state.rxStates[id: id]!.deviceUid
        state.appSettings.channels[id: id]!.gain = state.rxStates[id: id]!.gain
        state.appSettings.channels[id: id]!.isOn = state.rxStates[id: id]!.isOn
        state.appSettings.channels[id: id]!.showDetails = state.rxStates[id: id]!.showDetails
        return .none

      case let .txStates(.element(id: id, action: _)):
        state.appSettings.channels[id: id]!.deviceUid = state.txStates[id: id]!.deviceUid
        state.appSettings.channels[id: id]!.gain = state.txStates[id: id]!.gain
        state.appSettings.channels[id: id]!.isOn = state.txStates[id: id]!.isOn
        state.appSettings.channels[id: id]!.showDetails = state.txStates[id: id]!.showDetails
        return .none
      }
    }

    // ----------------------------------------------------------------------------
    // MARK: - Sheet / Alert reducer integration
    
    .ifLet(\.$showAlert, action: /Action.alert)
    .ifLet(\.$showLogin, action: /Action.login) { LoginFeature() }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Connection effect methods
  
  private func connect(_ state: State) -> Effect<SDRDaxCore.Action> {
    if let selection = state.selection {
      ListenerModel.shared.setActive(false, selection, false)
      return .run {
        // attempt to connect to the selected Radio / Station
        do {
          // try to connect
          try await ApiModel.shared.connect(selection: selection,
                                            isGui: false,
                                            disconnectHandle: nil,
                                            programName: "SDRDax",
                                            mtuValue: state.appSettings.mtuValue,
                                            lowBandwidthDax: state.appSettings.reducedBandwidth)
          await $0(.connectionStatus(.connected))
          
        } catch {
          // connection attempt failed
          await $0(.connectionStatus(.errorOnConnect))
        }
      }
    }
    return .none
  }
  
  private func disconnect() -> Effect<SDRDaxCore.Action> {
    return .run {
      ApiModel.shared.disconnect()
      await $0(.connectionStatus(.disconnected))
    }
  }
  
  private func connectionStatus(_ state: inout State, _ status: ConnectionState) -> Effect<SDRDaxCore.Action> {
    switch status {
    case .connected:
      state.previousSelection = state.selection
      state.isConnected = true
      return .none
      
    case .errorOnConnect:
      state.previousSelection = nil
      state.isConnected = false
      return .run {
        await $0(.showAlert(.connectFailed, ""))
      }
      
    case .disconnected:
      state.previousSelection = nil
      state.isConnected = false
      return .none

    case .errorOnDisconnect:
      state.previousSelection = nil
      state.isConnected = false
      return .run {
        await $0(.showAlert(.disconnectFailed, ""))
      }
    
    case .connecting:                           // is this needed ????
      state.isConnected = true
      return .none
      
    case .disconnecting:                        // is this needed ????
      state.isConnected = false
      return .none
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization effect methods
  
  private func initState(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    if state.initialized == false {
      
      // States
      for ch in state.appSettings.channels where ch.channelType == .iq {
        state.iqStates.append(DaxIqCore.State(id: ch.id, deviceUid: ch.deviceUid, isOn: ch.isOn, sampleRate: ch.sampleRate, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }

      for ch in state.appSettings.channels where ch.channelType == .mic {
        state.micStates.append(DaxMicCore.State(id: ch.id, deviceUid: ch.deviceUid, gain: ch.gain, isOn: ch.isOn, sampleRate: ch.sampleRate, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }
      
      for ch in state.appSettings.channels where ch.channelType == .rx {
        state.rxStates.append(DaxRxCore.State(id: ch.id, deviceUid: ch.deviceUid, gain: ch.gain, isOn: ch.isOn, sampleRate: ch.sampleRate, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }

      for ch in state.appSettings.channels where ch.channelType == .tx {
        state.txStates.append(DaxTxCore.State(id: ch.id, deviceUid: ch.deviceUid, gain: ch.gain, isOn: ch.isOn, sampleRate: ch.sampleRate, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }

      // instantiate the Logger, use the group defaults (not the Standard)
      _ = XCGWrapper(logLevel: .debug, group: "group.net.k3tzr.flexapps")
      
      // mark as initialized
      state.initialized = true
      
      if state.appSettings.smartlinkEnabled {
        return smartlinkListenerStart(&state)
      } else {
        return localListenerStart()
      }
    }
    return .none
  }

  // ----------------------------------------------------------------------------
  // MARK: - Local Listener effect methods

  private func localListenerStart() -> Effect<SDRDaxCore.Action> {
    ListenerModel.shared.localMode(true)
    return .none
  }
  
  private func localListenerStop() -> Effect<SDRDaxCore.Action> {
    ListenerModel.shared.localMode(false)
    return .none
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Smartlink Listener effect methods

  private func smartlinkListenerStart(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    if state.appSettings.smartlinkLoginRequired || state.appSettings.smartlinkUser.isEmpty {
      // YES but login required or no user
      state.appSettings.previousIdToken = nil
      state.appSettings.refreshToken = nil
      return .run {
        await $0(.showLoginSheet)
      }
      
    } else {
      // YES, try
      return .run { [state] in
        let tokens = await ListenerModel.shared.smartlinkMode(state.appSettings.smartlinkUser,
                                                              state.appSettings.smartlinkLoginRequired,
                                                              state.appSettings.previousIdToken,
                                                              state.appSettings.refreshToken)
        await $0(.saveTokens(tokens))
      }
    }
  }
  
  private func smartlinkListenerStop() -> Effect<SDRDaxCore.Action> {
    ListenerModel.shared.smartlinkStop()
    return .none
  }
    
  private func smartlinkUserLogin(_ state: inout State, _ user: String, _ password: String) -> Effect<SDRDaxCore.Action> {
    state.appSettings.smartlinkUser = user
    return .run {
      let tokens = await ListenerModel.shared.smartlinkStart(user, password)
      await $0(.saveTokens(tokens))
    }
  }
}
