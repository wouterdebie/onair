//
//  CameraChecker.swift
//  
//
//  Created by wouter.de.bie on 11/21/19.
//
import AVFoundation

class CameraChecker: NSObject, USBWatcherDelegate, URLSessionDelegate {
    private var cameras: [Camera] = []
    private var onEvent: String
    private var offEvent: String
    private var key: String
    private var localUrl: String?
    private var localCheckString: String?
    private var templateURL = "https://maker.ifttt.com/trigger/%@/with/key/%@"
    private var usbWatcher: USBWatcher!
    private var isInitialized: Bool = false
    private var localCheck = true
    
    
    init(onEvent: String, offEvent: String, key: String, localUrl: String?, localCheckString: String?){
        
        self.onEvent = onEvent
        self.offEvent = offEvent
        self.key = key
        self.localUrl = localUrl
        self.localCheckString = localCheckString
        
        super.init()
        if localUrl == nil {
            print("Local checking disabled!")
            localCheck = false
        }
        
        usbWatcher = USBWatcher(delegate: self)
        initCameras()
        isInitialized =  true
    }
    
    func initCameras() {
        print("Camera(s) found:")
        for device in AVCaptureDevice.devices(for: AVMediaType.video) {
            let camera = Camera(captureDevice: device, onChange: self.checkCameras)
            print("  - \(camera)")
            cameras.append(camera)
        }
    }
    
    func checkCameras() {
        let event: String
        let message: String
        
        if localCheck {
            if !isLocal() {
                print("Location is not local. Skipping..")
                return
            } else {
                print("Location is local!")
            }
        }
        
        if(cameras.contains{$0.isOn()}){
            let cameraString = cameras.filter{$0.isOn()}.map{$0.description}.joined(separator: ", ")
            message = "Camera(s) \(cameraString) are on"
            event = onEvent
        } else {
            message = "All cameras off"
            event = offEvent
        }
        
        let url = URL(string: String(format: templateURL, event, key))!
        let session = URLSession.shared
        let task = session.dataTask(with: url) {(data, response, error) in
            if error == nil {
                print("IFTTT \(event) called successfully")
            }
        }
        
        task.resume()
        createNotification(message: message)
        print(message)
    }
    
    func createNotification(message: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", "display notification \"\(message)\" with title \"Camera\" sound name \"Purr\""]
        task.launch()
        task.waitUntilExit()
    }
    
    func isLocal() -> Bool{
        var local: Bool = false
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 2.0
        sessionConfig.timeoutIntervalForResource = 4.0
        
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: URL(string: localUrl!)!){(data, response, error) in
            guard let data = data else {
                semaphore.signal()
                return
            }

            local = String(data: data, encoding: .utf8)!.contains(self.localCheckString!)
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return local
    }
    
    // URLSession delegate method to ignore SSL certificate validity
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        //Trust the certificate even if not valid
        let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        
        completionHandler(.useCredential, urlCredential)
    }
    
    // If we're initialized and a device is added or removed, we crudely exit.
    // Since we're running in a sub process, everything will be reinitalized
    // anyway and we don't need to worry about removing listeners, traversing
    // devices, etc.
    func deviceAdded(_ device: io_object_t) {
        if isInitialized {
            print("Device added: \(device.name() ?? "<unknown>")")
            exit(0)
        }
    }
    
    func deviceRemoved(_ device: io_object_t) {
        if isInitialized {
            print("Device removed: \(device.name() ?? "<unknown>")")
            exit(0)
        }
    }
}

extension io_object_t {
    /// - Returns: The device's name.
    func name() -> String? {
        let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        defer { buf.deallocate() }
        return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
            if IORegistryEntryGetName(self, $0) == KERN_SUCCESS {
                return String(cString: $0)
            }
            return nil
        }
    }
}
