//
//  main.swift
//  onair
//
//  Created by wouter.de.bie on 11/17/19.
//  Copyright © 2019 evenflow. All rights reserved.
//
import Cocoa
import TSCUtility
import TSCBasic
import Logging

let logger = Logger(label: "nl.evenflow.onair")

// Main run loop
// We run the actual CameraChecker in a sub process, since it will
// exit if it encounters added or removed USB devices. This is super
// crude, but it's a simple way of reinitializing all cams whenever
// something changes.

var childArgs: [String]

let parser = ArgumentParser(commandName: "onair",
                            usage: "--on <event> --off <event> --key <key> [--local-url <url>] [--local-string <string>]",
                            overview: "Call an IFTTT webhook if any webcam turns on or of all webcams are off.")
do {
   let onOption = parser.add(option: "--on",
                        kind: String.self, usage: "IFTTT Webhook event to call when a camera turns on")
    let offOption = parser.add(option: "--off",
                        kind: String.self, usage: "IFTTT Webhook event to call when a camera turns off")
    let keyOption = parser.add(option: "--key",
                        kind: String.self, usage: "IFTTT Webhook key")
    let localUrlOption = parser.add(option: "--local-url",
                        kind: String.self, usage: "(optional) URL to call to see if local")
    let localStringOption = parser.add(option: "--local-string",
                              kind: String.self, usage: "(optional) String to look for to see if local")

    let ignoreCameratOption = parser.add(option: "--ignore",
                                         kind: String.self, usage: "(optional) Comma-separated string of camera names to ignore")
    
    let args = Array(CommandLine.arguments.dropFirst())
    let result = try parser.parse(args)

    guard let on = result.get(onOption) else {
        throw ArgumentParserError.expectedArguments(parser, ["on"])
    }

    guard let off = result.get(offOption) else {
        throw ArgumentParserError.expectedArguments(parser, ["off"])
    }

    guard let key = result.get(keyOption) else {
        throw ArgumentParserError.expectedArguments(parser, ["key"])
    }
    
    childArgs = ["--on", on, "--off", off, "--key", key]
    
    let localUrl = result.get(localUrlOption)
    let localString = result.get(localStringOption)
    
    if localUrl != nil && localString == nil {
        throw ArgumentParserError.expectedArguments(parser, ["local-string"])
    }
    
    if localUrl == nil && localString != nil {
        throw ArgumentParserError.expectedArguments(parser, ["local-url"])
    }
    
    if localUrl != nil && localString != nil {
        childArgs += ["--local-url", localUrl!, "--local-string", localString!]
    }
    
    let ignoreCameras = result.get(ignoreCameratOption)
    if ignoreCameras != nil {
        childArgs += ["--ignore", ignoreCameras!]
    }
    
    let processInfo = ProcessInfo.processInfo
    var environment = processInfo.environment
    
    if environment["ONAIR_SPECIAL_VAR"] != nil {
        CameraChecker(onEvent: on,
                      offEvent: off,
                      key: key,
                      localUrl: localUrl,
                      localCheckString: localString,
                      ignore: ignoreCameras).checkCameras()
        
        RunLoop.main.run()
    } else {
        // We're in the parent.
        while (true) {
            environment["ONAIR_SPECIAL_VAR"] = "1"
            
            let child = Process()
            child.launchPath = processInfo.arguments[0]
            child.environment = environment
            child.arguments = childArgs
            child.launch()
            child.waitUntilExit()
        }
    }
    
    
} catch ArgumentParserError.expectedValue(let value) {
    logger.critical("Missing value for argument \(value).")
    exit(1)
} catch ArgumentParserError.expectedArguments(let parser, let stringArray) {
    logger.critical("Missing arguments: \(stringArray.joined()).")
    parser.printUsage(on: stdoutStream)
    exit(1)
} catch {
    print(error.localizedDescription)
    parser.printUsage(on: stdoutStream)
    exit(1)
}





