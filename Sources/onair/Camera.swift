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

        func report() -> Void{
        logger.info("Report:")
        logger.info("\(self)")
        let props = ["kCMIODevicePropertyPlugIn": kCMIODevicePropertyPlugIn,
        "kCMIODevicePropertyDeviceUID": kCMIODevicePropertyDeviceUID,
        "kCMIODevicePropertyModelUID": kCMIODevicePropertyModelUID,
        "kCMIODevicePropertyTransportType": kCMIODevicePropertyTransportType,
        "kCMIODevicePropertyDeviceIsAlive": kCMIODevicePropertyDeviceIsAlive,
        "kCMIODevicePropertyDeviceHasChanged": kCMIODevicePropertyDeviceHasChanged,
        "kCMIODevicePropertyDeviceIsRunning": kCMIODevicePropertyDeviceIsRunning,
        "kCMIODevicePropertyDeviceIsRunningSomewhere": kCMIODevicePropertyDeviceIsRunningSomewhere,
        "kCMIODevicePropertyDeviceCanBeDefaultDevice": kCMIODevicePropertyDeviceCanBeDefaultDevice,
        "kCMIODevicePropertyHogMode": kCMIODevicePropertyHogMode,
        "kCMIODevicePropertyLatency": kCMIODevicePropertyLatency,
        "kCMIODevicePropertyStreams": kCMIODevicePropertyStreams,
        "kCMIODevicePropertyStreamConfiguration": kCMIODevicePropertyStreamConfiguration,
        "kCMIODevicePropertyDeviceMaster": kCMIODevicePropertyDeviceMaster,
        "kCMIODevicePropertyExcludeNonDALAccess": kCMIODevicePropertyExcludeNonDALAccess,
        "kCMIODevicePropertyClientSyncDiscontinuity": kCMIODevicePropertyClientSyncDiscontinuity,
        "kCMIODevicePropertySMPTETimeCallback": kCMIODevicePropertySMPTETimeCallback,
        "kCMIODevicePropertyCanProcessAVCCommand": kCMIODevicePropertyCanProcessAVCCommand,
        "kCMIODevicePropertyAVCDeviceType": kCMIODevicePropertyAVCDeviceType,
        "kCMIODevicePropertyAVCDeviceSignalMode": kCMIODevicePropertyAVCDeviceSignalMode,
        "kCMIODevicePropertyCanProcessRS422Command": kCMIODevicePropertyCanProcessRS422Command,
        "kCMIODevicePropertyLinkedCoreAudioDeviceUID": kCMIODevicePropertyLinkedCoreAudioDeviceUID,
        "kCMIODevicePropertyVideoDigitizerComponents": kCMIODevicePropertyVideoDigitizerComponents,
        "kCMIODevicePropertySuspendedByUser": kCMIODevicePropertySuspendedByUser,
        "kCMIODevicePropertyLinkedAndSyncedCoreAudioDeviceUID": kCMIODevicePropertyLinkedAndSyncedCoreAudioDeviceUID,
        "kCMIODevicePropertyIIDCInitialUnitSpace": kCMIODevicePropertyIIDCInitialUnitSpace,
        "kCMIODevicePropertyIIDCCSRData": kCMIODevicePropertyIIDCCSRData,
        "kCMIODevicePropertyCanSwitchFrameRatesWithoutFrameDrops": kCMIODevicePropertyCanSwitchFrameRatesWithoutFrameDrops,
        "kCMIODevicePropertyLocation": kCMIODevicePropertyLocation,
        "kCMIODevicePropertyDeviceHasStreamingError": kCMIODevicePropertyDeviceHasStreamingError]
        for (propName, prop) in props {
            var pa = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(prop),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
            )
            var (dataSize, dataUsed) = (UInt32(0), UInt32(0))
            if CMIOObjectGetPropertyDataSize(id, &pa, 0, nil, &dataSize) == OSStatus(kCMIOHardwareNoError) {
                if let data = malloc(Int(dataSize)) {
                    CMIOObjectGetPropertyData(id, &pa, 0, nil, dataSize, &dataUsed, data)
                    logger.info("  \(propName): \(data.assumingMemoryBound(to: UInt8.self).pointee)")
                }
            }
        }
        logger.info("")
    }

    public var description: String { return "\(captureDevice.manufacturer)/\(captureDevice.localizedName)" }
}
