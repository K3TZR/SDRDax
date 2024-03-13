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
import SharedFeature

enum DaxStatus: String {
  case noSlice = "No Slice"
  case off = "Off"
  case streaming = "Streaming"
}

final class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {
    // disable tab view
    NSWindow.allowsAutomaticWindowTabbing = false
    // disable restoring windows
    UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows" : false])
  }
    
  func applicationWillTerminate(_ notification: Notification) {
    ApiModel.shared.disconnect()
    log("SDRDax: application terminated", .debug, #function, #file, #line)
    // pause to allow the log messages through
    sleep(1)
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@main
struct SDRDaxApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  var appDelegate
  
  @State var apiModel = ApiModel.shared
  @State var listenerModel = ListenerModel.shared
  
  var body: some Scene {
    WindowGroup("SDRDax  (v" + Version().string + ")") {
      SDRDaxView(store: Store(initialState: SDRDaxCore.State()) {
        SDRDaxCore()
      })
      .frame(minWidth: 370, maxWidth: 370)
      .padding(10)
      .environment(apiModel)
      .environment(listenerModel)
    }
    .windowStyle(.titleBar)
    .windowResizability(.contentSize)
  }
}
