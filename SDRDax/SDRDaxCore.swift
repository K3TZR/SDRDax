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

import ClientFeature
import DaxAudioFeature
import DirectFeature
import FlexApiFeature
import ListenerFeature
import LoginFeature
import PickerFeature
import SharedFeature
import XCGLogFeature

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
    var daxPanelOptions: DaxPanelOptions = []       {didSet { AppDefaults.set(daxPanelOptions.rawValue, forKey: "daxPanelOptions")}}
    var directEnabled = false                       {didSet { AppDefaults.set(directEnabled, forKey: "directEnabled")}}
    var directGuiIp = ""                            {didSet { AppDefaults.set(directGuiIp, forKey: "directGuiIp")}}
    var directNonGuiIp = ""                         {didSet { AppDefaults.set(directNonGuiIp, forKey: "directNonGuiIp")}}
    var guiDefault: String?                         {didSet { AppDefaults.set(guiDefault, forKey: "guiDefault")}}
    var isGui = false                               {didSet { AppDefaults.set(isGui, forKey: "isGui")}}
    var localEnabled = true                         {didSet { AppDefaults.set(localEnabled, forKey: "localEnabled")}}
    var lowBandwidthDax = false                     {didSet { AppDefaults.set(lowBandwidthDax, forKey: "lowBandwidthDax")}}
    var mtuValue = 1_300                            {didSet { AppDefaults.set(mtuValue, forKey: "mtuValue")}}
    var nonGuiDefault: String?                      {didSet { AppDefaults.set(nonGuiDefault, forKey: "nonGuiDefault")}}
    var previousIdToken: String?                    {didSet { AppDefaults.set(previousIdToken, forKey: "previousIdToken")}}
    var refreshToken: String?                       {didSet { AppDefaults.set(refreshToken, forKey: "refreshToken")}}
    var smartlinkEnabled = false                    {didSet { AppDefaults.set(smartlinkEnabled, forKey: "smartlinkEnabled")}}
    var smartlinkLoginRequired = false              {didSet { AppDefaults.set(smartlinkLoginRequired, forKey: "smartlinkLoginRequired")}}
    var smartlinkUser = ""                          {didSet { AppDefaults.set(smartlinkUser, forKey: "smartlinkUser")}}
    var station = "SDRDax"                          {didSet { AppDefaults.set(station, forKey: "station")}}
    var useDefaultEnabled = false                   {didSet { AppDefaults.set(useDefaultEnabled, forKey: "useDefaultEnabled")}}
    

    // non-persistent
    var initialized = false
    var connectionState: ConnectionState = .disconnected
        
    var daxIqStates: IdentifiedArrayOf<DaxIqCore.State> = [
      DaxIqCore.State(
        channel: 1,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: true
      ),
      DaxIqCore.State(
        channel: 2,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: true
      ),
      DaxIqCore.State(
        channel: 3,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: true
      ),
      DaxIqCore.State(
        channel: 4,
        device: nil,
        frequency: nil,
        isOn: false,
        sampleRate: 24_000,
        showDetails: true
      ),

    ]
    var daxMic = DaxDevice(channel: 0)
    
    var daxRxDevices = [
      DaxAudioPlayer(),
      DaxAudioPlayer(),
      DaxAudioPlayer(),
      DaxAudioPlayer(),
    ]
    var daxRxStates: IdentifiedArrayOf<DaxRxCore.State> = [
      DaxRxCore.State(
        channel: 1,
        device: nil,
        gain: 0.5,
        isOn: false,
        showDetails: true,
        sliceLetter: "A"
      ),
      DaxRxCore.State(
        channel: 2,
        device: nil,
        gain: 0.5,
        isOn: false,
        showDetails: true,
        sliceLetter: "B"
      ),
      DaxRxCore.State(
        channel: 3,
        device: nil,
        gain: 0.5,
        isOn: false,
        showDetails: true,
        sliceLetter: "C"
      ),
      DaxRxCore.State(
        channel: 4,
        device: nil,
        gain: 0.5,
        isOn: false,
        showDetails: true,
        sliceLetter: ""
      ),
    ]
    var daxTx = DaxDevice(channel: 0)

    //    var rxAVAudioPlayer = RxAVAudioPlayer()
    
    @Presents var showAlert: AlertState<Action.Alert>?
    @Presents var showClient: ClientFeature.State?
    @Presents var showDirect: DirectFeature.State?
    @Presents var showLogin: LoginFeature.State?
    @Presents var showPicker: PickerFeature.State?
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Actions
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    
    case startStopButtonTapped
    
    // subview actions
    case daxIqStates(IdentifiedActionOf<DaxIqCore>)
    case daxRxStates(IdentifiedActionOf<DaxRxCore>)
    
    // secondary actions
    case multiflexStatus(String)
    case connect(String, UInt32?)
    case connectionStatus(ConnectionState)
    case saveTokens(Tokens)
    case showAlert(Alert,String)
    case showClientSheet(String, IdentifiedArrayOf<GuiClient>)
    case showDirectSheet
    case showLoginSheet
    case showPickerSheet
    
    // navigation actions
    case alert(PresentationAction<Alert>)
    case client(PresentationAction<ClientFeature.Action>)
    case direct(PresentationAction<DirectFeature.Action>)
    case login(PresentationAction<LoginFeature.Action>)
    case picker(PresentationAction<PickerFeature.Action>)
    
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
      .forEach(\.daxRxStates, action: \.daxRxStates) {
        DaxRxCore()
      }

    EmptyReducer()
      .forEach(\.daxIqStates, action: \.daxIqStates) {
        DaxIqCore()
      }

    Reduce { state, action in
      switch action {
        
        // ----------------------------------------------------------------------------
        // MARK: - Root Actions
        
      case .onAppear:
        // perform initialization
        return initState(&state)
        
      case .startStopButtonTapped:
        // attempt to connect to the selected radio
        if state.connectionState == .connected {
          return connectionStop()
        } else {
          return connectionStart(state)
        }
                
        // ----------------------------------------------------------------------------
        // MARK: - Root Binding Actions
        
      case .binding(\.directEnabled):
        state.localEnabled = false
        state.smartlinkEnabled = false
        if state.directEnabled {
          return .run {
            await $0(.showDirectSheet)
          }
        } else {
          return .none
        }
        
      case .binding(\.localEnabled):
        state.directEnabled = false
        if state.localEnabled {
          return localListenerStart()
        } else {
          return localListenerStop()
        }
        
      case .binding(\.smartlinkEnabled):
        state.directEnabled = false
        if state.smartlinkEnabled {
          return smartlinkListenerStart(&state)
        } else {
          return smartlinkListenerStop()
        }
        
      case .binding(\.daxMic):
        print("----->>>>> binding .daxMic")
        return .none

      case .binding(\.daxPanelOptions):
        print("----->>>>> binding .daxPanelOptions")
        return .none

      case .binding(\.daxTx):
        print("----->>>>> binding .daxTx")
        return .none

      case .binding(_):
        print("----->>>>> binding ????")
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Effect Actions
        
      case let .connect(selection, disconnectHandle):
        // connect and optionally disconnect another client
        return connect(state, selection, disconnectHandle)
        
      case let .connectionStatus(status):
        // identify new state and take appropriate action(s)
        return connectionStatus(&state, status)
        
      case let .multiflexStatus(selection):
        // check for need to show Client view
        return multiflexConnectionStatus(state, selection)
        
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
        
      case let .showClientSheet(selection, guiClients):
        state.showClient = ClientFeature.State(selection: selection, guiClients: guiClients)
        return .none
        
      case .showDirectSheet:
        state.showDirect = DirectFeature.State(ip: state.isGui ? state.directGuiIp : state.directNonGuiIp)
        return .none
        
      case .showLoginSheet:
        state.showLogin = LoginFeature.State(user: state.smartlinkUser)
        return .none
        
      case .showPickerSheet:
        state.showPicker = PickerFeature.State(isGui: state.isGui, defaultValue: state.isGui ? state.guiDefault : state.nonGuiDefault)
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Alert Actions
        
      case .alert(_):
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Client Actions
        
      case let .client(.presented(.connect(selection, disconnectHandle))):
        // connect in the chosen manner
        return .run { await $0(.connect(selection, disconnectHandle)) }
        
      case .client(_):
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Direct Actions
        
      case .direct(.presented(.cancelButtonTapped)):
        state.directEnabled = false
        return .none
        
      case let .direct(.presented(.saveButtonTapped(ip))):
        // Direct is mutually exclusive of the other modes
        state.localEnabled = false
        state.smartlinkEnabled = false
        if state.isGui {
          state.directGuiIp = ip
        } else {
          state.directNonGuiIp = ip
        }
        return .none
        
      case .direct(_):
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
        // MARK: - Picker Actions
        
      case let .picker(.presented(.connectButtonTapped(selection))):
        // check the status of the selection
        return .run {await $0(.multiflexStatus(selection)) }
        
      case let .picker(.presented(.defaultButtonTapped(selection))):
        if state.isGui {
          state.guiDefault = state.guiDefault == selection ? nil : selection
        } else {
          state.nonGuiDefault = state.nonGuiDefault == selection ? nil : selection
        }
        return .none
        
      case .picker(_):
        return .none
        
        // ----------------------------------------------------------------------------
        // MARK: - Dax RX Actions
        
      case let .daxRxStates(.element(channel, .binding(\.device))):
        print("--->>> daxRxs[\(channel)] device = \(state.daxRxStates[id: channel]?.device)")
        state.daxRxDevices[channel - 1].device = state.daxRxStates[id: channel]?.device
        return .none

      case let .daxRxStates(.element(channel, .binding(\.gain))):
        print("--->>> daxRxs[\(channel)] gain = \(state.daxRxStates[id: channel]?.gain)")
        if let gain = state.daxRxStates[id: channel]?.gain {
          state.daxRxDevices[channel - 1].gain = gain
        }
        return .none

      case let .daxRxStates(.element(channel, .binding(\.isOn))):
//        print("----->>>>> .daxRxs[\(id)] isOn = \(state.daxRxs[id: id]?.isOn)")
        // if already connected, Start/Stop the id'd stream
        if state.connectionState == .connected {
          if state.daxRxStates[id: channel]!.isOn {
            log("DaxAudioPlayer: STARTED, channel = \(channel)", .debug, #function, #file, #line)
            state.daxRxStates[id: channel]!.status = "Streaming"
            return daxStart(state, channels: [channel])
          } else {
            log("DaxAudioPlayer: STOPPED, channel = \(channel)", .debug, #function, #file, #line)
            state.daxRxStates[id: channel]!.status = "Off"
            return daxStop(state, channels: [channel])
          }
        }
        return .none

      case let .daxRxStates(.element(channel, .binding(\.showDetails))):
        print("----->>>>> .daxRxs[\(channel)] showDetails = \(state.daxRxStates[id: channel]?.showDetails)")
        return .none

      case .daxRxStates(_):
        print("----->>>>> .daxRxs ????")
        return .none
              
        // ----------------------------------------------------------------------------
        // MARK: - Dax IQ Actions
        
      case let .daxIqStates(.element(channel, .binding(\.device))):
        print("--->>> daxRxs[\(channel)] device = \(state.daxIqStates[id: channel]?.device)")
        return .none

      case let .daxIqStates(.element(channel, .binding(\.isOn))):
        print("----->>>>> .daxRxs[\(channel)] isOn = \(state.daxIqStates[id: channel]?.isOn)")
        return .none

      case let .daxIqStates(.element(channel, .binding(\.sampleRate))):
        print("----->>>>> .daxRxs[\(channel)] sampleRate = \(state.daxIqStates[id: channel]?.sampleRate)")
        return .none

      case let .daxIqStates(.element(channel, .binding(\.showDetails))):
        print("----->>>>> .daxRxs[\(channel)] showDetails = \(state.daxIqStates[id: channel]?.showDetails)")
        return .none

      case .daxIqStates(_):
        print("----->>>>> .daxIqs ????")
        return .none
      }
    }

    // ----------------------------------------------------------------------------
    // MARK: - Sheet / Alert reducer integration
    
    .ifLet(\.$showAlert, action: /Action.alert)
    .ifLet(\.$showClient, action: /Action.client) { ClientFeature() }
    .ifLet(\.$showDirect, action: /Action.direct) { DirectFeature() }
    .ifLet(\.$showLogin, action: /Action.login) { LoginFeature() }
    .ifLet(\.$showPicker, action: /Action.picker) { PickerFeature() }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Connection effect methods
  
  private func connect(_ state: State, _ selection: String, _ disconnectHandle: UInt32?) -> Effect<SDRDaxCore.Action> {
    ListenerModel.shared.setActive(state.isGui, selection, state.directEnabled)
    return .run {
      // attempt to connect to the selected Radio / Station
      do {
        // try to connect
        try await ApiModel.shared.connect(selection: selection,
                                          isGui: state.isGui,
                                          disconnectHandle: disconnectHandle,
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
  
  private func connectionStart(_ state: State) -> Effect<SDRDaxCore.Action> {
    if state.directEnabled {
      return connectionStartDirect(state)
    } else {
      return connectionStartLocalSmartlink(state)
    }
  }
  
  private func connectionStartDirect(_ state: State) -> Effect<SDRDaxCore.Action> {
    return .run {
      if state.isGui && !state.directGuiIp.isEmpty {
        let selection = "9999-9999-9999-9999" + state.directGuiIp
        await $0(.connect(selection, nil))
        
      } else if !state.directNonGuiIp.isEmpty {
        let selection = "9999-9999-9999-9999" + state.directNonGuiIp
        await $0(.connect(selection, nil))
        
      } else {
        // no Ip Address for the current connection type
        await $0(.showDirectSheet)
      }
    }
  }
  
  private func connectionStartLocalSmartlink(_ state: State) -> Effect<SDRDaxCore.Action> {
    return .run {
      if state.useDefaultEnabled {
        // LOCAL/SMARTLINK mode connection using the Default, is there a valid? Default
        if ListenerModel.shared.isValidDefault(for: state.guiDefault, state.nonGuiDefault, state.isGui) {
          // YES, valid default
          if state.isGui {
            await $0(.multiflexStatus(state.guiDefault!))
          } else {
            await $0(.multiflexStatus(state.nonGuiDefault!))
          }
        } else {
          // NO, default is invalid
          await $0(.showPickerSheet)
        }
      } else {
        // default not in use, open the Picker
        await $0(.showPickerSheet)
      }
    }
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
      return daxStartAll(state)
      
    case .errorOnConnect:
      state.connectionState = .disconnected
      return .run {
        await $0(.showAlert(.connectFailed, ""))
      }
      
    case .disconnected:
      state.connectionState = .disconnected
      return daxStopAll(state)
      
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
  
  private func multiflexConnectionStatus(_ state: State, _ selection: String) -> Effect<SDRDaxCore.Action> {
    return .run {
      if state.isGui {
        // GUI selection
        if let selectedPacket = ListenerModel.shared.packets[id: selection] {
          
          // Gui connection with other stations?
          if selectedPacket.guiClients.count > 0 {
            // show the client chooser, let the user choose
            await $0(.showClientSheet(selection, selectedPacket.guiClients))
          } else {
            // Gui without other stations, attempt to connect
            await $0(.connect(selection, nil))
          }
        } else {
          // packet not found, should be impossible
          fatalError("ConnectionStatus: Packet not found")
        }
      } else {
        // NON-GUI selection
        await $0(.connect(selection, nil))
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - DAX effect methods
  
  private func daxStart(_ state: State, channels: [Int]) -> Effect<SDRDaxCore.Action> {
    return .run { [state, channels] _ in
      for channel in channels {
        // request a stream
        if let streamId = try await ApiModel.shared.requestDaxRxAudioStream(daxChannel: channel).streamId {
          // finish audio setup
          state.daxRxDevices[channel - 1].start(streamId)
          await ApiModel.shared.daxRxAudioStreams[id: streamId]?.delegate = state.daxRxDevices[channel - 1]
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
  
  private func daxStartAll(_ state: State) -> Effect<SDRDaxCore.Action> {
    var channels = [Int]()
    for daxRxState in state.daxRxStates where daxRxState.isOn {
      channels.append(daxRxState.channel)
    }
    return daxStart(state, channels: channels)
  }
  
  private func daxStop(_ state: State, channels: [Int]) -> Effect<SDRDaxCore.Action> {
    var streamIds = [UInt32?]()
    for channel in channels {
      streamIds.append(state.daxRxDevices[channel - 1].streamId)
      state.daxRxDevices[channel - 1].stop()
      log("DaxAudioPlayer: STOPPED, channel = \(channel)", .debug, #function, #file, #line)
    }
    return .run { [streamIds] _ in
      // remove stream(s)
      await ApiModel.shared.sendRemoveStreams(streamIds)
    }
  }
  
  private func daxStopAll(_ state: State) -> Effect<SDRDaxCore.Action> {
    var channels = [Int]()
    for daxRxState in state.daxRxStates where daxRxState.isOn {
      channels.append(daxRxState.channel)
    }
    return daxStop(state, channels: channels)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization effect methods
  
  private func initState(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    if state.initialized == false {
      
      state.daxPanelOptions = DaxPanelOptions(rawValue: UInt8(UserDefaults.standard.integer(forKey: "daxPanelOptions")))
//      state.daxMicSetting = UserDefaults.getStructFromSettings("daxMicSetting", defaults: UserDefaults.standard) ?? DaxSetting(channel: 1) as DaxSetting
//      state.daxRxSetting = UserDefaults.getStructFromSettings("daxRxSetting", defaults: UserDefaults.standard) ?? DaxSetting(channel: 1) as DaxSetting
//      state.daxTxSetting = UserDefaults.getStructFromSettings("daxTxSetting", defaults: UserDefaults.standard) ?? DaxSetting(channel: 1) as DaxSetting
      state.guiDefault = UserDefaults.standard.string(forKey: "guiDefault") ?? nil
      state.isGui = UserDefaults.standard.bool(forKey: "isGui")
      state.directEnabled = UserDefaults.standard.bool(forKey: "directEnabled")
      state.directGuiIp = UserDefaults.standard.string(forKey: "directGuiIp") ?? ""
      state.directNonGuiIp = UserDefaults.standard.string(forKey: "directNonGuiIp") ?? ""
      state.localEnabled = UserDefaults.standard.bool(forKey: "localEnabled")
      state.lowBandwidthDax = UserDefaults.standard.bool(forKey: "lowBandwidthDax")
      state.mtuValue = UserDefaults.standard.integer(forKey: "mtuValue")
      state.nonGuiDefault = UserDefaults.standard.string(forKey: "nonGuiDefault") ?? nil
      state.previousIdToken = UserDefaults.standard.string(forKey: "previousIdToken")
      state.refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
      state.smartlinkEnabled = UserDefaults.standard.bool(forKey: "smartlinkEnabled")
      state.smartlinkLoginRequired = UserDefaults.standard.bool(forKey: "smartlinkLoginRequired")
      state.smartlinkUser = UserDefaults.standard.string(forKey: "smartlinkUser") ?? ""
      state.useDefaultEnabled = UserDefaults.standard.bool(forKey: "useDefaultEnabled")
      
      // instantiate the Logger, use the group defaults (not the Standard)
      _ = XCGWrapper(logLevel: .debug, group: "group.net.k3tzr.flexapps")
      
      // mark as initialized
      state.initialized = true
      
      if state.localEnabled { _ = localListenerStart() }
      if state.smartlinkEnabled { return smartlinkListenerStart(&state) }
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
    ListenerModel.shared.removePackets(condition: {$0.source == .local})
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
    ListenerModel.shared.removePackets(condition: {$0.source == .smartlink})
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
