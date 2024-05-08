//
//  ViewController.m
//  test
//
//  Created by 叶常青 on 2023/11/23.
//

#import "ViewController.h"
#import <sensor/sensor.h>



@interface ViewController ()<SensorControllerDelegate>
@property (atomic, retain) SensorController* profile;
@property (atomic, strong) BLEPeripheral* device;
@property (atomic, assign) BOOL hasStartDataTransfer;
@end

const int PACKAGE_COUNT = 10;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.profile = [[SensorController alloc] init];
    self.profile.delegate = self;
}

- (IBAction)onScan:(id)sender{
    self.deviceText.text = @"scaning";
    [self.profile startScan:5];
}

- (IBAction)onConnect:(id)sender{
    if (self.profile.state >= BLEStateConnected){
        [self.profile disconnect];
    }else if (self.device != nil){
        [self.profile connect:self.device];
    }
}

- (IBAction)onVersion:(id)sender{
    [self.profile initDataNotification:PACKAGE_COUNT cb:^(GF_RET_CODE resp) {
        if (resp == GF_SUCCESS){
            [self.profile getControllerFirmwareVersion:^(GF_RET_CODE resp, NSString *firmwareVersion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.versionText.text = firmwareVersion;
                });
                
            } timeout:5];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.versionText.text = @"Init fail";
            });
        }
    }];
}

- (IBAction)onDataAction:(id)sender{
    if (self.profile.state >= BLEStateConnected && self.hasStartDataTransfer){
        [self stopDataTransfer];
    }else if (self.device != nil  && !self.hasStartDataTransfer){
        [self startDataTransfer];
    }
}

-(void)startDataTransfer{
    if (![self.profile hasInitDataNotification]){
        self.dataText.text = @"please get version first";
        return;
    }
    [self.profile startDataNotification];
    self.hasStartDataTransfer = TRUE;
}

-(void)stopDataTransfer{
    [self.profile stopDataNotification];
    self.hasStartDataTransfer = FALSE;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataText.text = @"data transfer stoped";
    });
}


#pragma mark - SynchronyDelegate
- (void)onSensorErrorCallback: (NSError*)err{
    NSLog(@"got gforce error %@", err);
}

- (void)onSensorStateChange: (BLEState)newState{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (newState >= BLEStateConnected){
            self.statusText.text = @"Connected";
        }else{
            self.statusText.text = @"Not Connected";
            self.hasStartDataTransfer = FALSE;
        }
    });
}

- (void)onSensorScanResult:(NSArray *)bleDevices{
    int maxRSSI = -1000;
    BLEPeripheral* bleDeviceMax = nil;
    for (BLEPeripheral* bleDevice in bleDevices) {
        NSLog(@"Found device: %@, mac: %@, rssi: %@", bleDevice.peripheralName, bleDevice.macAddress, bleDevice.rssi);
        if ([bleDevice.rssi intValue] > maxRSSI){
            maxRSSI = [bleDevice.rssi intValue];
            bleDeviceMax = bleDevice;
        }
    }
    if (bleDeviceMax != nil){
        self.deviceText.text = [NSString stringWithFormat:@"name: %@\n mac: %@\n rssi: %@", bleDeviceMax.peripheralName, bleDeviceMax.macAddress, bleDeviceMax.rssi];
        self.device = bleDeviceMax;
    }else{
        self.deviceText.text = @"scan finish";
    }
}

- (void)onSensorNotifyData:(SensorData *)sensorData {
    NSLog(@"got data: %d", sensorData.dataType);
    NSLog(@"%@", sensorData.channelSamples);
}

@end
