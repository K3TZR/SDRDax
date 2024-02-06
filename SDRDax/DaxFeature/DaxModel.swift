//
//  DaxModel.swift
//  
//
//  Created by Douglas Adams on 12/4/23.
//

import AVFoundation
import DaxRxAudioFeature
import FlexApiFeature

@MainActor
@Observable
final public class DaxModel {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton

  public static var shared = DaxModel()
  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var daxRxAudioPlayer: DaxRxAudioPlayer?
  public var status = "Off"

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _api = ApiModel.shared
  private var _streamId: UInt32 = 0
  
  
  private var _daxMicPlayer: DaxRxAudioPlayer?

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

//  public func startDaxMicAudio() {
//    Task {
//      // request a stream
//      if let streamId = try await _api.requestDaxMicAudioStream().streamId {       // FIXME: use the setting
//        // start player
//        _daxMicPlayer = DaxRxAudioPlayer(0.5)   // FIXNE: Where does volume come from?
//        // finish audio setup
//        _daxMicPlayer!.start(streamId)
//        _api.daxMicAudioStreams[id: streamId]?.delegate = _daxMicPlayer
//      } else {
//        // FAILURE, tell the user it failed
//        //      alertText = "Failed to start a RemoteRxAudioStream"
//        //      showAlert = true
//        fatalError("Failed to start a RemoteRxAudioStream")
//      }
//    }
//  }
//  
//  public func stopDaxMicAudio() {
//    _daxMicPlayer?.stop()
//    if let streamId = _daxMicPlayer?.streamId {
//      // remove player and stream
//      _daxMicPlayer = nil
//      _api.sendRemoveStream(streamId)
//    }
//  }
  
  public func setDevice(_ channelNumber: Int, _ deviceID: AudioDeviceID) {
    daxRxAudioPlayer?.setDevice(deviceID)
  }

  public func setGain(channel: Int, gain: Double) {
    if let streamId = daxRxAudioPlayer?.streamId, let sliceLetter = _api.daxRxAudioStreams[id: streamId]?.sliceLetter {
      print("----->>>>> ", streamId.hex, sliceLetter)
      for slice in _api.slices where slice.sliceLetter == sliceLetter {
        if _api.daxRxAudioStreams[id: streamId]?.clientHandle == slice.clientHandle {
          print("----->>>>> ", "audio stream \(streamId.hex) slice \(slice.id) gain \(Int(gain))")
          _api.sendCommand("audio stream \(streamId.hex) slice \(slice.id) gain \(Int(gain))")
        }
      }
    }
  }

  public func startDaxRxAudio(_ outputDeviceID: AudioDeviceID, _ channelNumber: Int) {
    Task {
      // request a stream
      if let streamId = try await _api.requestDaxRxAudioStream(daxChannel: channelNumber).streamId {
        _streamId = streamId
        // start player
        daxRxAudioPlayer = DaxRxAudioPlayer(outputDeviceID)   // FIXNE: Where does volume come from?
        // finish audio setup
        daxRxAudioPlayer!.start(streamId)
        _api.daxRxAudioStreams[id: streamId]?.delegate = daxRxAudioPlayer
        status = "Streaming"
      } else {
        // FAILURE, tell the user it failed
        //      alertText = "Failed to start a RemoteRxAudioStream"
        //      showAlert = true
        fatalError("Failed to start a RemoteRxAudioStream")
      }
    }
  }
  
  public func stopDaxRxAudio(_ channelNumber: Int) {
    daxRxAudioPlayer?.stop()
    if let streamId = daxRxAudioPlayer?.streamId {
      // remove player and stream
      daxRxAudioPlayer = nil
      _api.sendRemoveStream(streamId)
      status = "Off"
    }
  }
}
