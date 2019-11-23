//
//  Camera.swift
//  
//
//  Created by wouter.de.bie on 11/21/19.
//
import AVFoundation
import CoreMediaIO

class Camera: CustomStringConvertible {
    private var id: CMIOObjectID
    private var captureDevice: AVCaptureDevice
    private var STATUS_PA = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
    )
    private var listener: CMIOObjectPropertyListenerBlock
    
    init(captureDevice: AVCaptureDevice, onChange: @escaping () -> Void){
        self.captureDevice = captureDevice
        self.id = captureDevice.value(forKey: "_connectionID")! as! CMIOObjectID
        
        // Register the onChange callback to a change in the "running" status of the camera.
        // We'll let the onChange callback figure out what the status of the camera is,
        // rather than passing in the status, since all statuses have to be concidered.
        listener = {
            (_, _) -> Void in
            onChange()
        }
        CMIOObjectAddPropertyListenerBlock(id, &STATUS_PA, DispatchQueue.main, listener)
    }
    
    func isOn() -> Bool {
        // Test if the device is on through some magic. If the pointee is > 0, the device is active.
        var (dataSize, dataUsed) = (UInt32(0), UInt32(0))
        if CMIOObjectGetPropertyDataSize(id, &STATUS_PA, 0, nil, &dataSize) == OSStatus(kCMIOHardwareNoError) {
            if let data = malloc(Int(dataSize)) {
                CMIOObjectGetPropertyData(id, &STATUS_PA, 0, nil, dataSize, &dataUsed, data)
                return data.assumingMemoryBound(to: UInt8.self).pointee > 0
            }
        }
        return false
    }
    
    public var description: String { return "\(captureDevice.manufacturer)/\(captureDevice.localizedName)" }
}
