//
//  SDRDaxApp.swift
//  SDRDax
//
//  Created by Douglas Adams on 1/30/24.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import ListenerFeature
import SharedFeature      // FIXME: replace with LogFeatures package

// ----------------------------------------------------------------------------
// MARK: - Main

@main
struct SDRDaxApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  var appDelegate
  
  // persistent
  @Shared(.appStorage("autoStartEnabled")) var autoStartEnabled: Bool = false
  @Shared(.appStorage("reducedBandwidth")) var reducedBandwidth: Bool = false
  @Shared(.appStorage("smartlinkEnabled")) var smartlinkEnabled: Bool = false
  
  @Shared(.appStorage("iqEnabled")) var iqEnabled: Bool = true
  @Shared(.appStorage("micEnabled")) var micEnabled: Bool = true
  @Shared(.appStorage("rxEnabled")) var rxEnabled: Bool = true
  @Shared(.appStorage("txEnabled")) var txEnabled: Bool = true
  
  @State var apiModel = ApiModel.shared
  @State var listenerModel = ListenerModel.shared
  
  var body: some Scene {
    WindowGroup("SDRDax  (v" + Version().string + ")") {
      SDRDaxView(store: Store(initialState: SDRDaxCore.State(iqEnabled: $iqEnabled, 
                                                             micEnabled: $micEnabled,
                                                             rxEnabled: $rxEnabled,
                                                             txEnabled: $txEnabled,
                                                             autoStartEnabled: $autoStartEnabled,
                                                             reducedBandwidth: $reducedBandwidth,
                                                             smartlinkEnabled: $smartlinkEnabled)) {
        SDRDaxCore()
      })
      .frame(minWidth: 370, maxWidth: 370)
      .padding(10)
      .environment(apiModel)
      .environment(listenerModel)
    }
    .windowStyle(.titleBar)
    .windowResizability(.contentSize)
    
    
    // Settings window
    Settings {
      SDRDaxSettingsView(store: Store(initialState: SDRDaxSettingsCore.State(iqEnabled: $iqEnabled, 
                                                                             micEnabled: $micEnabled,
                                                                             rxEnabled: $rxEnabled,
                                                                             txEnabled: $txEnabled)) {
        SDRDaxSettingsCore()
      })
      .frame(width: 300, height: 140)
      .padding()
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(WindowResizability.contentSize)
    .defaultPosition(.bottomLeading)

  }
}

// ----------------------------------------------------------------------------
// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {
    // disable tab view
    NSWindow.allowsAutomaticWindowTabbing = false
    // disable restoring windows
    UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows" : false])
  }
    
  func applicationWillTerminate(_ notification: Notification) {
    ApiModel.shared.disconnect()
    closeAuxiliaryWindows()
    log("SDRDax: application terminated", .debug, #function, #file, #line)
    // pause to allow the log messages through
    sleep(1)
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@MainActor func closeAuxiliaryWindows() {
  for window in NSApplication.shared.windows {
    if window.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" { window.close() }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Globals

/// Struct to hold a Semantic Version number
public struct Version {
  public var major: Int = 1
  public var minor: Int = 0
  public var build: Int = 0
  
  // can be used directly in packages
  public init(_ versionString: String = "1.0.0") {
    let components = versionString.components(separatedBy: ".")
      major = Int(components[0]) ?? 1
      minor = Int(components[1]) ?? 0
      build = Int(components[2]) ?? 0
  }
  
  // only useful for Apps & Frameworks (which have a Bundle), not Packages
  public init() {
    let versions = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "?"
    let build   = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as? String ?? "?"
    self.init(versions + ".\(build)")
  }
  
  public var string: String { "\(major).\(minor).\(build)" }
}

enum StreamStatus: String {
  case off = "Off"
  case streaming = "Streaming"
}

enum SliceStatus: String {
  case sliceNotFound = "No Slice"
  case sliceFound = "Slice "
  case waiting = "Waiting"
}

