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

// struct for use in Dax settings
public struct DaxChannel: Identifiable, Equatable {
  public init(channel: Int, isOn: Bool = false, showDetails: Bool = false, sliceLetter: String? = nil, status: String = "Off", sampleRate: Int = 24_000) {
    self.channel = channel
    self.isOn = isOn
    self.showDetails = showDetails
    self.sliceLetter = sliceLetter
    self.status = status
    self.sampleRate = sampleRate
  }
  public var channel: Int
  public var isOn: Bool
  public var showDetails: Bool
  public var sliceLetter: String?
  public var status: String
  public var sampleRate: Int
  
  public var audioPlayer = DaxAudioPlayer()
  public var id: Int { channel }
}

public struct DaxState: Identifiable, Equatable {
  public init(channel: Int, isOn: Bool = false, deviceID: UInt32? = nil, gain: Double = 0.5, sampleRate: Int = 24_000, showDetails: Bool = true, sliceLetter: String = "", status: String = "Off") {
    self.channel = channel
    
    self.isOn = isOn
    self.deviceID = deviceID
    self.gain = gain
    self.sampleRate = sampleRate
    self.showDetails = showDetails
    self.sliceLetter = sliceLetter
    self.status = status
  }
  public var channel: Int
  public var isOn: Bool
  public var deviceID: UInt32?
  public var gain: Double
  public var sampleRate: Int
  public var showDetails: Bool
  public var sliceLetter: String
  public var status: String
  
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
//    var localEnabled = true                         {didSet { AppDefaults.set(localEnabled, forKey: "localEnabled")}}
    var lowBandwidthDax = false                     {didSet { AppDefaults.set(lowBandwidthDax, forKey: "lowBandwidthDax")}}
    var mtuValue = 1_300                            {didSet { AppDefaults.set(mtuValue, forKey: "mtuValue")}}
    var previousIdToken: String?                    {didSet { AppDefaults.set(previousIdToken, forKey: "previousIdToken")}}
    var refreshToken: String?                       {didSet { AppDefaults.set(refreshToken, forKey: "refreshToken")}}
    var autoSelection: String?                      {didSet { AppDefaults.set(autoSelection, forKey: "autoSelection")}}
    var smartlinkEnabled = false                    {didSet { AppDefaults.set(smartlinkEnabled, forKey: "smartlinkEnabled")}}
    var smartlinkLoginRequired = false              {didSet { AppDefaults.set(smartlinkLoginRequired, forKey: "smartlinkLoginRequired")}}
    var smartlinkUser = ""                          {didSet { AppDefaults.set(smartlinkUser, forKey: "smartlinkUser")}}
    
    // non-persistent
    var initialized = false
    var connectionState: ConnectionState = .disconnected
    var selection: String? = nil
    var isActive = false
    
//    var isActive: Bool {
//      if selectedStation == nil {
//        return false
//      } else {
//        return ListenerModel.shared.stations[id: selectedStation!] != nil
//      }
//    }

    var iqStates: IdentifiedArrayOf<DaxIqCore.State> = [
      DaxIqCore.State(
        channel: 1,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: false
      ),
      DaxIqCore.State(
        channel: 2,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: false
      ),
      DaxIqCore.State(
        channel: 3,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: false
      ),
      DaxIqCore.State(
        channel: 4,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: false
      ),

    ]
    var daxMic = DaxChannel(channel: 0)
    
//    var daxDevices = [
//      DaxAudioPlayer(),     // Mic
//      DaxAudioPlayer(),     // Rx1
//      DaxAudioPlayer(),     // Rx2
//      DaxAudioPlayer(),     // Rx3
//      DaxAudioPlayer(),     // Rx4
//    ]
    var rxStates: IdentifiedArrayOf<DaxRxCore.State> = [
//      DaxRxCore.State(daxState: DaxState(channel: 1)),
//      DaxRxCore.State(daxState: DaxState(channel: 2)),
//      DaxRxCore.State(daxState: DaxState(channel: 3)),
//      DaxRxCore.State(daxState: DaxState(channel: 4))
      DaxRxCore.State(
        audioPlayer: DaxAudioPlayer(),
        channel: 1,
        isOn: false,
        showDetails: false,
        sliceLetter: nil
      ),
      DaxRxCore.State(
        audioPlayer: DaxAudioPlayer(),
        channel: 2,
        isOn: false,
        showDetails: false,
        sliceLetter: nil
      ),
      DaxRxCore.State(
        audioPlayer: DaxAudioPlayer(),
        channel: 3,
        isOn: false,
        showDetails: false,
        sliceLetter: nil
      ),
      DaxRxCore.State(
        audioPlayer: DaxAudioPlayer(),
        channel: 4,
        isOn: false,
        showDetails: false,
        sliceLetter: nil
      ),
    ]
    var daxTx = DaxChannel(channel: 0)

    @Presents var showAlert: AlertState<Action.Alert>?
    @Presents var showLogin: LoginFeature.State?
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case stationsChanged
    case setAutoSelection(String?)
    
    // subview actions
    case iqStates(IdentifiedActionOf<DaxIqCore>)
    case rxStates(IdentifiedActionOf<DaxRxCore>)
    
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
      .forEach(\.rxStates, action: \.rxStates) {
        DaxRxCore()
      }

    EmptyReducer()
      .forEach(\.iqStates, action: \.iqStates) {
        DaxIqCore()
      }

    Reduce { state, action in
      switch action {
        
        // ----------------------------------------------------------------------------
        // MARK: - Root Actions
        
      case .onAppear:
        // perform initialization
        return .concatenate( initState(&state))
        
      case let .setAutoSelection(selection):
        state.autoSelection = selection
        return .none

      case .stationsChanged:
        print("stationsChanged")
        if state.selection == nil {
          state.isActive = false
        } else {
          state.isActive = ListenerModel.shared.stations[id: state.selection!] != nil
        }
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
        print("Selection = \(state.selection)")
        if state.selection == nil {
          state.isActive = false
        } else {
          state.isActive = ListenerModel.shared.stations[id: state.selection!] != nil
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
        // MARK: - Presented Views
        
      case let .showAlert(alertType, message):
        switch alertType {
        case .connectFailed, .disconnectFailed, .unknownError:
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
        
      case .login(.dismiss):
        return .none
      
      case .login(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Dax IQ Actions
        
      case .iqStates(.element(_, .binding(\.device))):
        return .none

      case .iqStates(.element(_, .binding(\.isOn))):
        return .none

      case .iqStates(.element(_, .binding(\.sampleRate))):
        return .none

      case .iqStates(.element(_, .binding(\.showDetails))):
        return .none

      case .iqStates(_):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Dax MIC Actions
        
      case .binding(\.daxMic):
        return .none

        // ----------------------------------------------------------------------------
        // MARK: - Dax RX Actions
        
      case let .rxStates(.element(channel, .binding(\.audioPlayer))):
        if state.rxStates[id: channel]?.audioPlayer.deviceId == nil {
          // STOP when device removed
          return daxStop(&state, channels: [channel])
        }
        return .none

      case let .rxStates(.element(channel, .binding(\.isOn))):
        // if already connected, Start/Stop a channel
        if state.connectionState == .connected {
          if state.rxStates[id: channel]!.isOn {
            return daxStart(&state, channels: [channel])
          } else {
            return daxStop(&state, channels: [channel])
          }
        }
        return .none

      case .rxStates(_):
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Dax TX Actions
        
      case .binding(\.daxTx):
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
  
  private func connect(_ state: State, _ selection: String?) -> Effect<SDRDaxCore.Action> {
    if let selection {
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
  
  private func connectionStartLocalSmartlink(_ state: State) -> Effect<SDRDaxCore.Action> {
    // is there a valid Default?
    if ListenerModel.shared.isValidDefault(for: nil, state.selection, false) {
      // YES, valid default
      return connect( state, state.selection)
    }
    return .none
  }
  
  private func connectionStop() -> Effect<SDRDaxCore.Action> {
    return .run {
      await ApiModel.shared.disconnect()
      await $0(.connectionStatus(.disconnected))
    }
  }
  
  private func connectionStatus(_ state: inout State, _ status: ConnectionState) -> Effect<SDRDaxCore.Action> {
    switch status {
    case .connected:
      state.connectionState = .connected
      return daxStartAll(&state)
      
    case .errorOnConnect:
      state.connectionState = .disconnected
      return .run {
        await $0(.showAlert(.connectFailed, ""))
      }
      
    case .disconnected:
      state.connectionState = .disconnected
      return daxStopAll(&state)
      
    case .errorOnDisconnect:
      state.connectionState = .disconnected
      return .run {
        await $0(.showAlert(.disconnectFailed, ""))
      }
    case .connecting:
      state.connectionState = .connecting
      return .none
      
    case .disconnecting:
      state.connectionState = .disconnecting
      return .none
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: inout State, channels: [Int]) -> Effect<SDRDaxCore.Action> {
    for channel in channels {
      state.rxStates[id: channel]?.status = "Streaming"
    }
    return .run { [state, channels] _ in
      for channel in channels {
        // request a stream
        if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: channel).streamId {
          // finish audio setup
          state.rxStates[id: channel]?.audioPlayer.start(streamId)
          await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.rxStates[id: channel]?.audioPlayer
          log("DaxAudioPlayer: STARTED, channel = \(channel)", .debug, #function, #file, #line)

        } else {
          // FAILURE, tell the user it failed
          //      alertText = "Failed to start a RemoteRxAudioStream"
          //      showAlert = true
          fatalError("Failed to start a RemoteRxAudioStream")
        }
      }
    }
  }
  
  private func daxStartAll(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    var channels = [Int]()
    for rxState in state.rxStates where rxState.isOn {
      channels.append(rxState.channel)
    }
    return daxStart(&state, channels: channels)
  }
  
  private func daxStop(_ state: inout State, channels: [Int]) -> Effect<SDRDaxCore.Action> {
    var streamIds = [UInt32?]()
    for channel in channels {
      state.rxStates[id: channel]?.status = "Off"
      streamIds.append(state.rxStates[id: channel]?.audioPlayer.streamId)
      state.rxStates[id: channel]?.audioPlayer.stop()
      log("DaxAudioPlayer: STOPPED, channel = \(channel)", .debug, #function, #file, #line)
    }
    return .run { [streamIds] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams(streamIds)
    }
  }
  
  private func daxStopAll(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    var channels = [Int]()
    for rxState in state.rxStates where rxState.isOn {
      channels.append(rxState.channel)
    }
    return daxStop(&state, channels: channels)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization effect methods
  
  private func initState(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    if state.initialized == false {
      
      state.autoStart = UserDefaults.standard.bool(forKey: "autoStart")
      state.daxPanelOptions = DaxPanelOptions(rawValue: UInt8(UserDefaults.standard.integer(forKey: "daxPanelOptions")))
//      state.localEnabled = UserDefaults.standard.bool(forKey: "localEnabled")
      state.lowBandwidthDax = UserDefaults.standard.bool(forKey: "lowBandwidthDax")
      state.mtuValue = UserDefaults.standard.integer(forKey: "mtuValue")
      state.previousIdToken = UserDefaults.standard.string(forKey: "previousIdToken")
      state.refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
      state.autoSelection = UserDefaults.standard.string(forKey: "autoSelection") ?? nil
      state.smartlinkEnabled = UserDefaults.standard.bool(forKey: "smartlinkEnabled")
      state.smartlinkLoginRequired = UserDefaults.standard.bool(forKey: "smartlinkLoginRequired")
      state.smartlinkUser = UserDefaults.standard.string(forKey: "smartlinkUser") ?? ""
      
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
//    ListenerModel.shared.removePackets(condition: {$0.source == .local})
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
//    ListenerModel.shared.removePackets(condition: {$0.source == .smartlink})
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
