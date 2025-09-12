//
//  Log.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

// Utilities/Log.swift
enum Log {
  #if DEBUG
  static func d(_ message: @autoclosure () -> String) { print("🐛 " + message()) }
  #else
  static func d(_ message: @autoclosure () -> String) { }
  #endif
}
