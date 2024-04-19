//
//  SensorController.swift
//  test2
//
//  Created by 叶常青 on 2024/4/19.
//

import Foundation
import sensor

class SensorController : NSObject, SensorDelegate{

    var profile: SensorProfile
    override init() {
        profile = SensorProfile()
        super.init()
        profile.delegate = self
    }
    
    func onSensorErrorCallback(_ err: Error!) {
        
    }
    
    func onSensorStateChange(_ newState: BLEState) {
        
    }
    
    func onSensorScanResult(_ bleDevices: [BLEPeripheral]!) {
        
    }
    
    func onSensorNotify(_ rawData: Data!) {
        
    }
}
