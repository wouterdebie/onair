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
import Foundation
import ArgumentParser

let logger = Logger(label: "nl.evenflow.onair")

// We run the actual CameraChecker in a sub process, since it will
// exit if it encounters added or removed USB devices. This is super
// crude, but it's a simple way of reinitializing all cams whenever
// something changes.

var child: Foundation.Process?

// Setup SIGINT and SIGTERM to terminate both the parent and child process.
signal(SIGINT, SIG_IGN)
signal(SIGTERM, SIG_IGN)

let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
let sigtermSrc = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)

func die() {
    logger.info("Terminating..")
    child?.terminate()
    exit(0)
}

sigintSrc.setEventHandler(handler: die)
sigintSrc.resume()

sigtermSrc.setEventHandler(handler: die)
sigtermSrc.resume()

struct OnAir : ParsableCommand {
    @Option(help: ArgumentHelp("IFTTT Webhook event to call when a camera turns on", valueName: "event"))
    var on: String

    @Option(help: ArgumentHelp("IFTTT Webhook event to call when a camera turns off", valueName: "event"))
    var off: String

    @Option(help: ArgumentHelp("IFTTT Webhook key", valueName: "key"))
    var key: String

    @Option(help: ArgumentHelp("(optional) URL to call to see if local", valueName: "url"))
    var localUrl: String?

    @Option(help: ArgumentHelp("(optional) String to look for to see if local", valueName: "string"))
    var localString: String?

    @Option(help: ArgumentHelp("(optional) Comma-separated list of camera names to ignore", valueName: "list"))
    var ignore: String?

    @Flag(help: ArgumentHelp("Show extra debug information"))
    var debug = false

    mutating func validate() throws {
        if localUrl != nil && localString == nil {
            throw ValidationError("--local-string required when using --local-url")
        }

        if localUrl == nil && localString != nil {
            throw ValidationError("--local-url required when using --local-string")
        }
    }

    mutating func run() throws {
        var childArgs = ["--on", on, "--off", off, "--key", key]

        if localUrl != nil && localString != nil {
            childArgs += ["--local-url", localUrl!, "--local-string", localString!]
        }

        if ignore != nil {
            childArgs += ["--ignore", ignore!]
        }

        if debug {
            childArgs += ["--debug"]
        }

        let processInfo = ProcessInfo.processInfo
        var environment = processInfo.environment

        if environment["ONAIR_SPECIAL_VAR"] != nil {
            logger.info("Debug in child: \(debug)")
            CameraChecker(onEvent: on,
                          offEvent: off,
                          key: key,
                          localUrl: localUrl,
                          localCheckString: localString,
                          ignore: ignore,
                          debug: debug).checkCameras()
            RunLoop.main.run()
        } else {
            // We're in the parent.
            while (true) {
                environment["ONAIR_SPECIAL_VAR"] = "1"

                child = Process()
                child!.launchPath = processInfo.arguments[0]
                child!.environment = environment
                child!.arguments = childArgs
                child!.launch()
                child!.waitUntilExit()
            }
        }
    }
}

OnAir.main()
