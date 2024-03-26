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

// DAX channel types
public struct IqChannel: Identifiable, Equatable, Codable {
  public let channel: Int
  public var deviceUid: String?
  public var isOn: Bool
  public var sampleRate: Int
  public var showDetails: Bool

  public var id: Int { channel }
}

public struct MicChannel: Identifiable, Equatable, Codable {
  public let channel: Int
  public var deviceUid: String?
  public var gain: Double
  public var isOn: Bool
  public var showDetails: Bool

  public var id: Int { channel }
}

public struct RxChannel: Identifiable, Equatable, Codable {
  public let channel: Int
  public var deviceUid: String?
  public var gain: Double
  public var isOn: Bool
  public var showDetails: Bool

  public var id: Int { channel }
}

public struct TxChannel: Identifiable, Equatable, Codable {
  public let channel: Int
  public var deviceUid: String?
  public var gain: Double
  public var isOn: Bool
  public var showDetails: Bool

  public var id: Int { channel }
}

enum SampleRate: Int, CaseIterable {
  case r24 = 24_000
  case r48 = 48_000
  case r96 = 96_000
  case r192 = 192_000
}

@Reducer
public struct SDRDaxCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State {
    let AppDefaults = UserDefaults.standard
    
    @Shared(.appStorage("mtuValue")) var mtuValue: Int = 1_300
    @Shared(.appStorage("previousIdToken")) var previousIdToken: String? = nil
    @Shared(.appStorage("refreshToken")) var refreshToken: String? = nil
    @Shared(.appStorage("autoSelection")) var autoSelection: String? = nil
    @Shared(.appStorage("smartlinkLoginRequired")) var smartlinkLoginRequired: Bool = false
    @Shared(.appStorage("smartlinkUser")) var smartlinkUser: String = ""
    
    @Shared(.appStorage("iqChannels")) var iqChannels: [IqChannel] = [IqChannel(channel: 1, deviceUid: nil, isOn: false, sampleRate: SampleRate.r24.rawValue, showDetails: false),
                                                                      IqChannel(channel: 2, deviceUid: nil, isOn: false, sampleRate: SampleRate.r24.rawValue, showDetails: false),
                                                                      IqChannel(channel: 3, deviceUid: nil, isOn: false, sampleRate: SampleRate.r24.rawValue, showDetails: false),
                                                                      IqChannel(channel: 4, deviceUid: nil, isOn: false, sampleRate: SampleRate.r24.rawValue, showDetails: false),
    ]
    @Shared(.appStorage("micChannels")) var micChannels: [MicChannel] = [MicChannel(channel: 0, deviceUid: nil, gain: 50, isOn: false, showDetails: false)]
    @Shared(.appStorage("rxChannels")) var rxChannels: [RxChannel] = [RxChannel(channel: 1, deviceUid: nil, gain: 50, isOn: false, showDetails: false),
                                                                      RxChannel(channel: 2, deviceUid: nil, gain: 50, isOn: false, showDetails: false),
                                                                      RxChannel(channel: 3, deviceUid: nil, gain: 50, isOn: false, showDetails: false),
                                                                      RxChannel(channel: 4, deviceUid: nil, gain: 50, isOn: false, showDetails: false),
    ]
    @Shared(.appStorage("txChannels")) var txChannels: [TxChannel] = [TxChannel(channel: 0, deviceUid: nil, gain: 50, isOn: false, showDetails: false)]
    
    var iqStates: IdentifiedArrayOf<DaxIqCore.State> = []
    var micStates: IdentifiedArrayOf<DaxMicCore.State> = []
    var rxStates: IdentifiedArrayOf<DaxRxCore.State> = []
    var txStates: IdentifiedArrayOf<DaxTxCore.State> = []

    // non-persistent
    var initialized = false
    var selection: String? = nil
    var previousSelection: String? = nil

    @Presents var showAlert: AlertState<Action.Alert>?
    @Presents var showLogin: LoginFeature.State?
    
    @Shared(.inMemory("isActive")) var isActive = false
    @Shared(.inMemory("isConnected")) var isConnected = false

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
    public enum Alert : String {
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
        return .concatenate( initState(&state))
        
      case .onDisappear:
        return .run {_ in
          await closeAuxiliaryWindows()
        }
        
      case .bandwidthTapped:
        state.reducedBandwidth.toggle()
        return .none
        
      case .connect:
        return connect(state)
                
      case .connectionTapped:
        state.smartlinkEnabled.toggle()
        return .none

      case .modeTapped:
        state.autoStartEnabled.toggle()
        return .none

      case let .setAutoSelection(selection):
        state.autoSelection = selection
        return .none
                
        // ----------------------------------------------------------------------------
        // MARK: - Root Binding Actions
        
      case .binding(\.smartlinkEnabled):
        if state.smartlinkEnabled {
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
          state.previousIdToken = tokens.idToken
          state.refreshToken = tokens.refreshToken
        } else {
          // failure
          state.previousIdToken = nil
          state.refreshToken = nil
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
          state.smartlinkEnabled = false
        default: break
        }
        state.showAlert = AlertState(title: TextState(alertType.rawValue), message: TextState(message))
        return .none
        
      case .showLoginSheet:
        state.showLogin = LoginFeature.State(user: state.smartlinkUser)
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Alert Actions
        
      case .alert(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Login Actions
        
      case .login(.presented(.cancelButtonTapped)):
        state.smartlinkEnabled = false
        return .none
        
      case let .login(.presented(.loginButtonTapped(user, password))):
        // attempt to login to Smartlink
        return smartlinkUserLogin(&state, user, password)
        
      case .login(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Subview Actions (persist to User Defaults)
        
      case let .iqStates(.element(id: channel, action: _)):
        state.iqChannels[channel - 1].deviceUid = state.iqStates[id: channel]!.deviceUid
        state.iqChannels[channel - 1].sampleRate = state.iqStates[id: channel]!.sampleRate
        state.iqChannels[channel - 1].isOn = state.iqStates[id: channel]!.isOn
        state.iqChannels[channel - 1].showDetails = state.iqStates[id: channel]!.showDetails
        return .none

      case let .micStates(.element(id: channel, action: _)):
        state.micChannels[channel].deviceUid = state.micStates[id: channel]!.deviceUid
        state.micChannels[channel].gain = state.micStates[id: channel]!.gain
        state.micChannels[channel].isOn = state.micStates[id: channel]!.isOn
        state.micChannels[channel].showDetails = state.micStates[id: channel]!.showDetails
        return .none

      case let .rxStates(.element(id: channel, action: _)):
        state.rxChannels[channel - 1].deviceUid = state.rxStates[id: channel]!.deviceUid
        state.rxChannels[channel - 1].gain = state.rxStates[id: channel]!.gain
        state.rxChannels[channel - 1].isOn = state.rxStates[id: channel]!.isOn
        state.rxChannels[channel - 1].showDetails = state.rxStates[id: channel]!.showDetails
        return .none

      case let .txStates(.element(id: channel, action: _)):
        state.txChannels[channel].deviceUid = state.txStates[id: channel]!.deviceUid
        state.txChannels[channel].gain = state.txStates[id: channel]!.gain
        state.txChannels[channel].isOn = state.txStates[id: channel]!.isOn
        state.txChannels[channel].showDetails = state.txStates[id: channel]!.showDetails
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
                                            mtuValue: state.mtuValue,
                                            lowBandwidthDax: state.reducedBandwidth)
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
      await ApiModel.shared.disconnect()
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
      for ch in state.iqChannels {
        state.iqStates.append(DaxIqCore.State(channel: ch.channel, deviceUid: ch.deviceUid, isOn: ch.isOn, sampleRate: ch.sampleRate, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }

      for ch in state.micChannels {
        state.micStates.append(DaxMicCore.State(channel: ch.channel, deviceUid: ch.deviceUid, gain: ch.gain, isOn: ch.isOn, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }
      
      for ch in state.rxChannels {
        state.rxStates.append(DaxRxCore.State(channel: ch.channel, deviceUid: ch.deviceUid, gain: ch.gain, isOn: ch.isOn, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }

      for ch in state.txChannels {
        state.txStates.append(DaxTxCore.State(channel: ch.channel, deviceUid: ch.deviceUid, gain: ch.gain, isOn: ch.isOn, showDetails: ch.showDetails, isConnected: state.$isConnected))
      }

      // instantiate the Logger, use the group defaults (not the Standard)
      _ = XCGWrapper(logLevel: .debug, group: "group.net.k3tzr.flexapps")
      
      // mark as initialized
      state.initialized = true
      
      if state.smartlinkEnabled {
        return smartlinkListenerStart(&state)
      } else {
        _ = localListenerStart()
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
    if state.smartlinkLoginRequired || state.smartlinkUser.isEmpty {
      // YES but login required or no user
      state.previousIdToken = nil
      state.refreshToken = nil
      return .run {
        await $0(.showLoginSheet)
      }
      
    } else {
      // YES, try
      return .run { [state] in
        let tokens = await ListenerModel.shared.smartlinkMode(state.smartlinkUser,
                                                              state.smartlinkLoginRequired,
                                                              state.previousIdToken,
                                                              state.refreshToken)
        await $0(.saveTokens(tokens))
      }
    }
  }
  
  private func smartlinkListenerStop() -> Effect<SDRDaxCore.Action> {
    ListenerModel.shared.smartlinkStop()
    return .none
  }
    
  private func smartlinkUserLogin(_ state: inout State, _ user: String, _ password: String) -> Effect<SDRDaxCore.Action> {
    state.smartlinkUser = user
    return .run {
      let tokens = await ListenerModel.shared.smartlinkStart(user, password)
      await $0(.saveTokens(tokens))
    }
  }
}
