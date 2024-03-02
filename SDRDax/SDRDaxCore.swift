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
  public var deviceId: AudioDeviceID?
  public var isOn: Bool
  public var sampleRate: Double
  public var showDetails: Bool

  public var id: Int { channel }
}

public struct MicChannel: Identifiable, Equatable, Codable {
  public let channel: Int
  public var deviceId: AudioDeviceID?
  public var gain: Double
  public var isOn: Bool
  public var showDetails: Bool

  public var id: Int { channel }
}

public struct RxChannel: Identifiable, Equatable, Codable {
  public let channel: Int
  public var deviceId: AudioDeviceID?
  public var gain: Double
  public var isOn: Bool
  public var showDetails: Bool

  public var id: Int { channel }
}

public struct TxChannel: Identifiable, Equatable, Codable {
  public let channel: Int
  public var deviceId: AudioDeviceID?
  public var gain: Double
  public var isOn: Bool
  public var showDetails: Bool

  public var id: Int { channel }
}

@Reducer
public struct SDRDaxCore {
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable {
    public static func == (lhs: SDRDaxCore.State, rhs: SDRDaxCore.State) -> Bool {
      lhs.daxPanelOptions == rhs.daxPanelOptions
    }
    
    let AppDefaults = UserDefaults.standard
    
    // persistent
    var autoStart = false                           {didSet { AppDefaults.set(autoStart, forKey: "autoStart")}}
    var daxPanelOptions: DaxPanelOptions = []       {didSet { AppDefaults.set(daxPanelOptions.rawValue, forKey: "daxPanelOptions")}}
    var lowBandwidthDax = false                     {didSet { AppDefaults.set(lowBandwidthDax, forKey: "lowBandwidthDax")}}
    var mtuValue = 1_300                            {didSet { AppDefaults.set(mtuValue, forKey: "mtuValue")}}
    var previousIdToken: String?                    {didSet { AppDefaults.set(previousIdToken, forKey: "previousIdToken")}}
    var refreshToken: String?                       {didSet { AppDefaults.set(refreshToken, forKey: "refreshToken")}}
    var autoSelection: String?                      {didSet { AppDefaults.set(autoSelection, forKey: "autoSelection")}}
    var smartlinkEnabled = false                    {didSet { AppDefaults.set(smartlinkEnabled, forKey: "smartlinkEnabled")}}
    var smartlinkLoginRequired = false              {didSet { AppDefaults.set(smartlinkLoginRequired, forKey: "smartlinkLoginRequired")}}
    var smartlinkUser = ""                          {didSet { AppDefaults.set(smartlinkUser, forKey: "smartlinkUser")}}
    
    var iqChannels = [IqChannel(channel: 1, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
                      IqChannel(channel: 2, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
                      IqChannel(channel: 3, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
                      IqChannel(channel: 4, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
    ]
    
    var micChannels = [MicChannel(channel: 0, deviceId: nil, gain: 50, isOn: false, showDetails: false)]

    var rxChannels = [RxChannel(channel: 1, deviceId: nil, gain: 50, isOn: false, showDetails: false),
                      RxChannel(channel: 2, deviceId: nil, gain: 50, isOn: false, showDetails: false),
                      RxChannel(channel: 3, deviceId: nil, gain: 50, isOn: false, showDetails: false),
                      RxChannel(channel: 4, deviceId: nil, gain: 50, isOn: false, showDetails: false),
    ]

    var txChannels = [TxChannel(channel: 0, deviceId: nil, gain: 50, isOn: false, showDetails: false)]
    
    @Shared(.appStorage("isActive")) var isActive = false
    
    var iqStates: IdentifiedArrayOf<DaxIqCore.State> = []
    var micStates: IdentifiedArrayOf<DaxMicCore.State> = []
    var rxStates: IdentifiedArrayOf<DaxRxCore.State> = []
    var txStates: IdentifiedArrayOf<DaxTxCore.State> = []

    // non-persistent
    var initialized = false
    var connectionState: ConnectionState = .disconnected
    var selection: String? = nil

    @Presents var showAlert: AlertState<Action.Alert>?
    @Presents var showLogin: LoginFeature.State?
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case connect
    case onAppear
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
        
      case .connect:
        return connect(state)
                
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
          state.isActive = ListenerModel.shared.stations[id: state.selection!] != nil
          if state.isActive { return connect(state) }
        }
        return .none

      case .binding(_):
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
        // MARK: - Dax IQ Actions
        
//      case .iqStates(.element(id: _, action: .isActiveChanged)):
//        print("--->>> App: iqStates: isActiveChanged")
//        return .none

      case let .iqStates(.element(id: channel, action: .binding)):
        state.iqChannels[channel - 1] = state.iqStates[id: channel]!.ch
        UserDefaults.saveStructToSettings("daxIqChannels", state.iqChannels, defaults: UserDefaults.standard)
        return .none

      case .iqStates(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Dax MIC Actions
        
      case let .micStates(.element(id: channel, action: .binding)):
        state.micChannels[channel - 1] = state.micStates[id: channel]!.ch
        UserDefaults.saveStructToSettings("daxMicChannels", state.micChannels, defaults: UserDefaults.standard)
        return .none

      case .micStates(_):
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Dax RX Actions
        
      case let .rxStates(.element(id: channel, action: .binding)):
        state.rxChannels[channel - 1] = state.rxStates[id: channel]!.ch
        UserDefaults.saveStructToSettings("daxRxChannels", state.rxChannels, defaults: UserDefaults.standard)
        return .none

      case .rxStates(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Dax TX Actions
        
      case let .txStates(.element(id: channel, action: .binding)):
        state.txChannels[channel - 1] = state.txStates[id: channel]!.ch
        UserDefaults.saveStructToSettings("daxTxChannels", state.txChannels, defaults: UserDefaults.standard)
        return .none

      case .txStates(_):
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
                                            lowBandwidthDax: state.lowBandwidthDax)
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
      state.connectionState = .connected
      state.isActive = true
      return .none
      
    case .errorOnConnect:
      state.connectionState = .disconnected
      return .run {
        await $0(.showAlert(.connectFailed, ""))
      }
      
    case .disconnected:
      state.connectionState = .disconnected
      state.isActive = false
      return .none

    case .errorOnDisconnect:
      state.connectionState = .disconnected
      state.isActive = false
      return .run {
        await $0(.showAlert(.disconnectFailed, ""))
      }
    
    case .connecting:                           // is this needed ????
      state.connectionState = .connecting
      return .none
      
    case .disconnecting:                        // is this needed ????
      state.connectionState = .disconnecting
      return .none
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization effect methods
  
  private func initState(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    if state.initialized == false {
      
      // load from User Defaults (use default value if not in User Defaults)
      state.autoStart = UserDefaults.standard.bool(forKey: "autoStart")
      state.daxPanelOptions = DaxPanelOptions(rawValue: UInt8(UserDefaults.standard.integer(forKey: "daxPanelOptions")))
      state.lowBandwidthDax = UserDefaults.standard.bool(forKey: "lowBandwidthDax")
      state.mtuValue = UserDefaults.standard.integer(forKey: "mtuValue")
      state.previousIdToken = UserDefaults.standard.string(forKey: "previousIdToken")
      state.refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
      state.autoSelection = UserDefaults.standard.string(forKey: "autoSelection") ?? nil
      state.smartlinkEnabled = UserDefaults.standard.bool(forKey: "smartlinkEnabled")
      state.smartlinkLoginRequired = UserDefaults.standard.bool(forKey: "smartlinkLoginRequired")
      state.smartlinkUser = UserDefaults.standard.string(forKey: "smartlinkUser") ?? ""
            
      // Channels
      // IQ Channels (Radio -> SDRDax), 1...4
      state.iqChannels = UserDefaults.getStructFromSettings("daxIqChannels", defaults: UserDefaults.standard) ?? [
        IqChannel(channel: 1, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
        IqChannel(channel: 2, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
        IqChannel(channel: 3, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
        IqChannel(channel: 4, deviceId: nil, isOn: false, sampleRate: 24_000, showDetails: false),
      ]
      // Mic Channels (Radio -> SDRDax)
      state.micChannels = UserDefaults.getStructFromSettings("daxMicChannels", defaults: UserDefaults.standard) ?? [
        MicChannel(channel: 1, deviceId: nil, gain: 50, isOn: false, showDetails: false),
      ]
      // Rx Channels (Radio -> SDRDax),
      state.rxChannels = UserDefaults.getStructFromSettings("daxRxChannels", defaults: UserDefaults.standard) ?? [
        RxChannel(channel: 1, deviceId: nil, gain: 50, isOn: false, showDetails: false),
        RxChannel(channel: 2, deviceId: nil, gain: 50, isOn: false, showDetails: false),
        RxChannel(channel: 3, deviceId: nil, gain: 50, isOn: false, showDetails: false),
        RxChannel(channel: 4, deviceId: nil, gain: 50, isOn: false, showDetails: false),
      ]
      // Tx channel (SDRDax -> Radio)
      state.txChannels = UserDefaults.getStructFromSettings("daxTxChannel", defaults: UserDefaults.standard) ?? [
        TxChannel(channel: 1, gain: 50, isOn: false, showDetails: false)
      ]
      
      // States
      state.iqStates = [
        DaxIqCore.State(ch: state.iqChannels[0], isActive: state.$isActive),
        DaxIqCore.State(ch: state.iqChannels[1], isActive: state.$isActive),
        DaxIqCore.State(ch: state.iqChannels[2], isActive: state.$isActive),
        DaxIqCore.State(ch: state.iqChannels[3], isActive: state.$isActive),
      ]
      state.micStates = [
        DaxMicCore.State(ch: state.micChannels[0], isActive: state.$isActive)
      ]
      state.rxStates = [
        DaxRxCore.State(ch: state.rxChannels[0], isActive: state.$isActive),
        DaxRxCore.State(ch: state.rxChannels[1], isActive: state.$isActive),
        DaxRxCore.State(ch: state.rxChannels[2], isActive: state.$isActive),
        DaxRxCore.State(ch: state.rxChannels[3], isActive: state.$isActive),
      ]
      state.txStates = [
        DaxTxCore.State(ch: state.txChannels[0], isActive: state.$isActive)
      ]
            
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

// ----------------------------------------------------------------------------
// MARK: - Extensions

extension UserDefaults {
  /// Read a user default entry and decode it into a struct
  /// - Parameters:
  ///    - key:         the name of the user default
  /// - Returns:        a struct (or nil)
  public class func getStructFromSettings<T: Decodable>(_ key: String, defaults: UserDefaults) -> T? {
    if let data = defaults.object(forKey: key) as? Data {
      let decoder = JSONDecoder()
      if let value = try? decoder.decode(T.self, from: data) {
        return value
      } else {
        return nil
      }
    }
    return nil
  }
  
  /// Encode a struct and write it to a user default
  /// - Parameters:
  ///    - key:        the name of the user default
  ///    - value:      a struct  to be encoded (or nil)
  public class func saveStructToSettings<T: Encodable>(_ key: String, _ value: T?, defaults: UserDefaults) {
    if value == nil {
      defaults.removeObject(forKey: key)
    } else {
      let encoder = JSONEncoder()
      if let encoded = try? encoder.encode(value) {
        defaults.set(encoded, forKey: key)
      } else {
        defaults.removeObject(forKey: key)
      }
    }
  }

}

//extension URL {
//  static var rxs: URL {
//    return try! FileManager.default.url(
//      for: .applicationSupportDirectory,
//      in: .userDomainMask,
//      appropriateFor: nil,
//      create: false
//    ).appendingPathComponent("RxDevice.json")
//  }
//}
