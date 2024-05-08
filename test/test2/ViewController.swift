//
//  ViewController.swift
//  test2
//
//  Created by 叶常青 on 2024/4/19.
//

import UIKit
import sensor

let PACKAGE_COUNT = 10

class ViewController: UIViewController, SensorControllerDelegate {
    private var profile: SensorController?
    private var device: BLEPeripheral?
    private var hasStartDataTransfer = false


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        profile = SensorController()
        profile?.delegate = self
    }

    @IBAction func onScan(_ sender: Any) {
//        deviceText.text = "scaning"
        profile?.startScan(5)
    }

    @IBAction func onConnect(_ sender: Any) {
        if profile?.state == BLEState.running {
            profile?.disconnect()
        } else if let device {
            profile?.connect(device)
        }
    }

    @IBAction func onVersion(_ sender: Any) {
        profile?.initDataNotification(Int32(PACKAGE_COUNT), cb: { [self] resp in
            if resp == GF_RET_CODE.SUCCESS {
                profile?.getFirmwareVersion({ [self] resp, firmwareVersion in
                    DispatchQueue.main.async(execute: { [self] in
//                        self.versionText.text = firmwareVersion
                    })

                }, timeout: 5)
            } else {
                DispatchQueue.main.async {
//                    self.versionText.text = @"Init fail";
                }
            }
        })

    }
    
    func onSensorErrorCallback(_ err: Error) {
        print(err.localizedDescription)
    }
    
    func onSensorStateChange(_ newState: BLEState) {
        print(newState)
    }
    
    func onSensorScanResult(_ bleDevices: [BLEPeripheral]) {
        print(bleDevices)
    }
    
    func onSensorNotify(_ rawData: SensorData) {
        print(rawData.channelSamples[0][0].rawData)
    }
}

