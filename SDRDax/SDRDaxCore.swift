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
        
    var daxIqs: IdentifiedArrayOf<DaxIqCore.State> = [
      DaxIqCore.State(
        id: UUID(),
        enabled: false,
        channel: 0,
        deviceID:  nil,
        gain: 0.5,
        status: "off",
        sampleRate: 24_000
      ),
      DaxIqCore.State(
        id: UUID(),
        enabled: false,
        channel: 1,
        deviceID: nil,
        gain: 0.8,
        status: "off",
        sampleRate: 48_000
      ),
      DaxIqCore.State(
        id: UUID(),
        enabled: false,
        channel: 2,
        deviceID: nil,
        gain: 0.8,
        status: "off",
        sampleRate: 96_000
      ),
      DaxIqCore.State(
        id: UUID(),
        enabled: false,
        channel: 3,
        deviceID: nil,
        gain: 0.8,
        status: "off",
        sampleRate: 192_000
      ),

    ]
    var daxMic = DaxDevice(channel: 0)
    var daxRxs: IdentifiedArrayOf<DaxRxCore.State> = [
      DaxRxCore.State(
        id: UUID(),
        enabled: false,
        channel: 0,
        deviceID:  nil,
        gain: 0.5,
        status: "off",
        sampleRate: 24_000
      ),
      DaxRxCore.State(
        id: UUID(),
        enabled: false,
        channel: 1,
        deviceID: nil,
        gain: 0.8,
        status: "off",
        sampleRate: 24_000
      ),
      DaxRxCore.State(
        id: UUID(),
        enabled: false,
        channel: 2,
        deviceID: nil,
        gain: 0.8,
        status: "off",
        sampleRate: 24_000
      ),
      DaxRxCore.State(
        id: UUID(),
        enabled: false,
        channel: 3,
        deviceID: nil,
        gain: 0.8,
        status: "off",
        sampleRate: 24_000
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
    
    case connectButtonTapped
    
    // subview actions
    case daxIqs(IdentifiedActionOf<DaxIqCore>)
    case daxRxs(IdentifiedActionOf<DaxRxCore>)
    
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
      .forEach(\.daxRxs, action: \.daxRxs) {
        DaxRxCore()
      }

    EmptyReducer()
      .forEach(\.daxIqs, action: \.daxIqs) {
        DaxIqCore()
      }

    Reduce { state, action in
      switch action {
        
        // ----------------------------------------------------------------------------
        // MARK: - Root Actions
        
      case .onAppear:
        // perform initialization
        return initState(&state)
        
      case .connectButtonTapped:
        // attempt to connect to the selected radio
        return connectionStartStop(state)
                
//      case let .daxRxChannelChanged(newValue):
//        state.daxRxSetting.channel = newValue
//        print("----->>>>> daxRxChannel = \(newValue)")
//        return .none
//        
//      case let .daxRxGainChanged(newValue):
//        state.daxRxSetting.gain = newValue
//        print("----->>>>> daxRxGain = \(newValue)")
//        return .run {[state] _ in
//          await DaxModel.shared.setGain(channel: state.daxRxSetting.channel, gain: state.daxRxSetting.gain)
//        }
//
//      case let .daxRxDeviceIDChanged(newValue):
//        state.daxRxSetting.deviceID = newValue
//        print("----->>>>> daxRxDeviceID = \(newValue)")
//        return .run {[state] _ in
//          if newValue != nil {
//            print("----->>>>> New AudioDeviceID", newValue!)
//            await DaxModel.shared.setDevice(state.daxRxSetting.channel, newValue!)
//            
//          } else {
//            print("----->>>>> New AudioDeviceID", "none")
//          }
//        }
//
//      case let .daxRxEnabledChanged(newValue):
//        state.daxRxSetting.enabled = newValue
//        print("----->>>>> daxRxEnabled = \(newValue)")
//        return .run {[state] _ in
//          if newValue {
//            await DaxModel.shared.startDaxRxAudio(state.daxRxSetting.deviceID!, state.daxRxSetting.channel)
//          } else {
//            await DaxModel.shared.stopDaxRxAudio(state.daxRxSetting.channel)
//          }
//        }
        
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
        return listenerStartStop(&state)
        
      case .binding(\.smartlinkEnabled):
        state.directEnabled = false
        return listenerStartStop(&state)
        
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
        return multiflexStatus(state, selection)
        
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
        
      case let .daxRxs(.element(x, .binding(\.channel))):
        print("----->>>>> .daxRxs, channel = \(state.daxRxs[id: x]?.channel)")
        return .none

      case let .daxRxs(.element(x, .binding(\.deviceID))):
        print("----->>>>> .daxRxs, deviceID = \(state.daxRxs[id: x]?.deviceID)")
        return .none

      case let .daxRxs(.element(x, .binding(\.enabled))):
        print("----->>>>> .daxRxs, enabled = \(state.daxRxs[id: x]?.enabled)")
        return .none

      case let .daxRxs(.element(x, .binding(\.gain))):
        print("----->>>>> .daxRxs, gain = \(state.daxRxs[id: x]?.gain)")
        return .none

      case .daxRxs(_):
        print("----->>>>> .daxRxs ????")
        return .none
              
        // ----------------------------------------------------------------------------
        // MARK: - Dax RX Actions
        
      case let .daxIqs(.element(x, .binding(\.channel))):
        print("----->>>>> .daxRxs, channel = \(state.daxIqs[id: x]?.channel)")
        return .none

      case let .daxIqs(.element(x, .binding(\.deviceID))):
        print("----->>>>> .daxRxs, deviceID = \(state.daxIqs[id: x]?.deviceID)")
        return .none

      case let .daxIqs(.element(x, .binding(\.enabled))):
        print("----->>>>> .daxRxs, enabled = \(state.daxIqs[id: x]?.enabled)")
        return .none

      case let .daxIqs(.element(x, .binding(\.gain))):
        print("----->>>>> .daxRxs, gain = \(state.daxIqs[id: x]?.gain)")
        return .none

      case let .daxIqs(.element(x, .binding(\.sampleRate))):
        print("----->>>>> .daxRxs, gain = \(state.daxIqs[id: x]?.sampleRate)")
        return .none

      case .daxIqs(_):
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
  // MARK: - Private effect methods
  
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
  
  private func connectionStartStop(_ state: State) -> Effect<SDRDaxCore.Action> {
    if state.connectionState == .connected {
      // ----- STOPPING -----
      //      MessagesModel.shared.stop(state.clearOnStop)
      return .run {
        //        if state.remoteRxAudioEnabled { await remoteRxAudioStop(state) }
        await ApiModel.shared.disconnect()
        await $0(.connectionStatus(.disconnected))
      }
      
    } else {
      // ----- STARTING -----
      //      MessagesModel.shared.start(state.clearOnStart)
      if state.directEnabled {
        // DIRECT Mode
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
        
      } else {
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
              // NO, invalid default
              await $0(.showPickerSheet)
            }
          } else {
            // default not in use, open the Picker
            await $0(.showPickerSheet)
          }
        }
      }
    }
  }
  
  private func connectionStatus(_ state: inout State, _ status: ConnectionState) -> Effect<SDRDaxCore.Action> {
    
    switch status {
    case .connected:
      state.connectionState = .connected
      
    case .errorOnConnect:
      state.connectionState = .disconnected
      return .run {
        await $0(.showAlert(.connectFailed, ""))
      }
    case .disconnected:
      state.connectionState = .disconnected
      
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
    return .none
  }
  
  private func initState(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    if state.initialized == false {
      
//      state.alertOnError = UserDefaults.standard.bool(forKey: "alertOnError")
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
      
      return listenerStartStop(&state)
    }
    return .none
  }
  
  // start/stop listener, as needed
  private func listenerStartStop(_ state: inout State) -> Effect<SDRDaxCore.Action> {
    // start/stop local mode
    ListenerModel.shared.localMode(state.localEnabled)
    
    // start smartlink mode?
    if state.smartlinkEnabled {
      
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
    } else {
      ListenerModel.shared.removePackets(condition: {$0.source == .smartlink})
      return .none
    }
  }
  
  private func multiflexStatus(_ state: State, _ selection: String) -> Effect<SDRDaxCore.Action> {
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
  
  private func smartlinkUserLogin(_ state: inout State, _ user: String, _ password: String) -> Effect<SDRDaxCore.Action> {
    state.smartlinkUser = user
    return .run {
      let tokens = await ListenerModel.shared.smartlinkStart(user, password)
      await $0(.saveTokens(tokens))
    }
  }
  
//  private func subscribeToLogAlerts() ->  Effect<SDRDaxCore.Action>  {
//    return .run {
//      for await logEntry in logAlerts {
//        // a Warning or Error has been logged.
//        await $0(.showLogAlert(logEntry))
//      }
//    }
//  }
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
