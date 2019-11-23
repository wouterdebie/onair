//
//  UsbWatcher.swift
//  onair2
//
//  Created by wouter.de.bie on 11/21/19.
//  Copyright © 2019 evenflow. All rights reserved.
//

import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib

public protocol USBWatcherDelegate: class {
    /// Called on the main thread when a device is connected.
    func deviceAdded(_ device: io_object_t)
    
    /// Called on the main thread when a device is disconnected.
    func deviceRemoved(_ device: io_object_t)
}

/// An object which observes USB devices added and removed from the system.
/// Abstracts away most of the ugliness of IOKit APIs.
public class USBWatcher {
    private weak var delegate: USBWatcherDelegate?
    private let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    
    public init(delegate: USBWatcherDelegate) {
        self.delegate = delegate
        
        func handleNotification(instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
            let watcher = Unmanaged<USBWatcher>.fromOpaque(instance!).takeUnretainedValue()
            let handler: ((io_iterator_t) -> Void)?
            switch iterator {
                case watcher.addedIterator: handler = watcher.delegate?.deviceAdded
                case watcher.removedIterator: handler = watcher.delegate?.deviceRemoved
                default: assertionFailure("received unexpected IOIterator"); return
            }
            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                handler?(device)
                IOObjectRelease(device)
            }
        }
        
        let query = IOServiceMatching(kIOUSBDeviceClassName)
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()
        
        // Watch for connected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOMatchedNotification, query,
            handleNotification, opaqueSelf, &addedIterator)
        
        handleNotification(instance: opaqueSelf, addedIterator)
        
        // Watch for disconnected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOTerminatedNotification, query,
            handleNotification, opaqueSelf, &removedIterator)
        
        handleNotification(instance: opaqueSelf, removedIterator)
        
        // Add the notification to the main run loop to receive future updates.
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
            .commonModes)
    }
    
    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(notificationPort)
    }
}
