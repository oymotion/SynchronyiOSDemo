//
//  ViewController.m
//  test
//
//  Created by 叶常青 on 2023/11/23.
//

#import "ViewController.h"
#import "AppDelegate.h"



@implementation SynchronySample
@end

@implementation SynchronyData
-(id)init{
    if (self = [super init]) {
        for (int index = 0;index < MAX_CHANNEL_COUNT;++index){
            samples[index] = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

-(void)addSample:(SynchronySample*)sample channelIndex:(int)channelIndex{
    [samples[channelIndex] addObject:sample];
    if (samples[channelIndex].count > MAX_SAMPLE_COUNT){
        [samples[channelIndex] removeObjectAtIndex:0];
    }
}
@end

@interface ViewController ()<SynchronyDelegate>

@property (atomic, weak) SynchronyProfile* profile;
@property (atomic, strong) BLEPeripheral* device;
@property (atomic, strong) SynchronyData* eegData;
@property (atomic, strong) SynchronyData* ecgData;
@property (atomic, strong) SynchronyData* impedanceData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.profile = delegate.profile;
    self.profile.delegate = self;
}

- (IBAction)onScan:(id)sender{
    self.deviceText.text = @"scaning";
    [self.profile startScan];
}

- (IBAction)onConnect:(id)sender{
    if (self.profile.state == BLEStateConnected || self.profile.state == BLEStateRuning){
        [self.profile disconnect];
    }else if (self.device != nil){
        [self.profile connect:self.device];
    }
}

- (IBAction)onVersion:(id)sender{
    [self.profile getControllerFirmwareVersion:^(GF_RET_CODE resp, NSString *firmwareVersion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.versionText.text = firmwareVersion;
        });
        
    } timeout:TIMEOUT];

    [self getEEG];
    [self getECG];
    [self getImpedance];
    
    [self.profile setDataNotifSwitch: (DNF_EEG | DNF_ECG | DNF_IMPEDANCE) cb:^(GF_RET_CODE resp) {
        NSLog(@"got set data notify response %ld", (long)resp);
        if (resp == GF_SUCCESS){
            [self.profile startDataNotification];
        }
    } timeout:TIMEOUT];
}

-(void)getEEG{
    [self.profile getEegDataConfig:^(GF_RET_CODE resp, int sampleRate, int channelMask, int packageSampleCount, int resolutionBits, double conversionK) {
        if (resp == GF_SUCCESS){
            self.eegData = [[SynchronyData alloc] init];
            SynchronyData* data = self.eegData;
            data.sampleRate = sampleRate;
            data.channelMask = channelMask;
            data.resolutionBits = resolutionBits;
            data.packageSampleCount = packageSampleCount;
            data.K = conversionK;
            data.lastPackageIndex = 0;
        }

    } timeout:TIMEOUT];
    
    [self.profile getEegDataCap:^(GF_RET_CODE resp, NSArray *supportedSampleRates, int maxChannelCount, int maxPackageSampleCount, NSArray *supportedResolutionBits) {
        
        if (resp == GF_SUCCESS){
            self.eegData.channelCount = maxChannelCount;
        }
    } timeout:TIMEOUT];
}

-(void)getECG{
    [self.profile getEcgDataConfig:^(GF_RET_CODE resp, int sampleRate, int channelMask, int packageSampleCount, int resolutionBits, double conversionK) {
        if (resp == GF_SUCCESS){
            self.ecgData = [[SynchronyData alloc] init];
            SynchronyData* data = self.ecgData;
            data.sampleRate = sampleRate;
            data.channelMask = channelMask;
            data.resolutionBits = resolutionBits;
            data.packageSampleCount = packageSampleCount;
            data.K = conversionK;
            data.lastPackageIndex = 0;
        }

    } timeout:TIMEOUT];
    
    [self.profile getEcgDataCap:^(GF_RET_CODE resp, NSArray *supportedSampleRates, int maxChannelCount, int maxPackageSampleCount, NSArray *supportedResolutionBits) {
        
        if (resp == GF_SUCCESS){
            self.ecgData.channelCount = maxChannelCount;
        }
    } timeout:TIMEOUT];
}

-(void)getImpedance{
    [self.profile getImpedanceDataConfig:^(GF_RET_CODE resp, int sampleRate, int channelMask, int packageSampleCount, int resolutionBits, double conversionK) {
        if (resp == GF_SUCCESS){
            self.impedanceData = [[SynchronyData alloc] init];
            SynchronyData* data = self.impedanceData;
            data.sampleRate = sampleRate;
            data.channelMask = channelMask;
            data.resolutionBits = resolutionBits;
            data.packageSampleCount = packageSampleCount;
            data.K = conversionK;
            data.lastPackageIndex = 0;
        }

    } timeout:TIMEOUT];
    
    [self.profile getImpedanceDataCap:^(GF_RET_CODE resp, NSArray *supportedSampleRates, int maxChannelCount, int maxPackageSampleCount, NSArray *supportedResolutionBits) {
        
        if (resp == GF_SUCCESS){
            self.impedanceData.channelCount = maxChannelCount;
        }
    } timeout:TIMEOUT];
}

#pragma mark - SynchronyDelegate
- (void)onSynchronyErrorCallback: (NSError*)err{
    NSLog(@"got gforce error %@", err);
}
- (void)onSynchronyStateChange: (BLEState)newState{
    if (newState == BLEStateConnected){
        self.statusText.text = @"Connected";
    }else if (newState == BLEStateRuning){
        self.statusText.text = @"Running";
    }else{
        self.statusText.text = @"Not Connected";
    }
}

- (void)onSynchronyScanResult:(NSArray *)bleDevices{

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


- (void)onSynchronyNotifyData:(NSData *)rawData {
    if (rawData.length > 1){
        unsigned char* result = (unsigned char*)rawData.bytes;
        if (result[0] == NTF_EEG || result[0] == NTF_ECG || result[0] == NTF_IMPEDANCE){
            SynchronyData* synchronyData = nil;
            if (result[0] == NTF_EEG)
                synchronyData = self.eegData;
            else if (result[0] == NTF_ECG)
                synchronyData = self.ecgData;
            else if (result[0] == NTF_IMPEDANCE)
                synchronyData = self.impedanceData;
            
            int readOffset = 1;

            @try {
                int packageIndex = *((unsigned short*)(result + readOffset));
                readOffset += 2;
                int newPackageIndex = packageIndex;
                int lastPackageIndex = synchronyData.lastPackageIndex;
                
                if (packageIndex < lastPackageIndex){
                    packageIndex += 65536;
                }
                int deltaPackageIndex = packageIndex - lastPackageIndex;
                if (deltaPackageIndex > 1){
                    int lostSampleCount = synchronyData.packageSampleCount * (deltaPackageIndex - 1);
                    NSLog(@"lost samples: %d", lostSampleCount);
                    [self readSamples:result synchronyData:synchronyData offset:0 lostSampleCount:lostSampleCount];
                    if (newPackageIndex == 0){
                        synchronyData.lastPackageIndex = 65535;
                    }else{
                        synchronyData.lastPackageIndex = newPackageIndex - 1;
                    }
                    [self readSamples:result synchronyData:synchronyData offset:readOffset lostSampleCount:0];
                    synchronyData.lastPackageIndex = newPackageIndex;
                }
            } @catch (NSException *exception) {
                NSLog(@"Error: %@", [exception description]);
            } @finally {
                
            }

        }
    }
}


- (void)readSamples:(unsigned char *)data synchronyData:(SynchronyData*) synchronyData offset:(int)offset lostSampleCount:(int)lostSampleCount{
    
    int sampleCount = synchronyData.packageSampleCount;
    if (lostSampleCount > 0)
        sampleCount = lostSampleCount;
    
    double K = synchronyData.K;
    int lastSampleIndex = synchronyData.lastPackageIndex * synchronyData.packageSampleCount;
    
    for (int sampleIndex = 0;sampleIndex < sampleCount; ++sampleIndex, ++lastSampleIndex){
        for (int channelIndex = 0; channelIndex < synchronyData.channelCount; ++channelIndex){
            if ((synchronyData.channelMask & (1 << channelIndex)) > 0){
                SynchronySample* sample = [[SynchronySample alloc] init];
                sample.rawDataSampleIndex = lastSampleIndex;
                if (lostSampleCount > 0){
                    //add missing samples with 0
                    sample.rawData = 0;
                    sample.convertData = 0;
                }else{
                    int rawData = 0;
                    if (synchronyData.resolutionBits == 8){
                        rawData = data[offset];
                        rawData -= 128;
                        offset += 1;
                    }else if (synchronyData.resolutionBits == 16){
                        rawData = (data[offset] << 8) | (data[offset + 1]);
                        rawData -= 32768;
                        offset += 2;
                    }else if (synchronyData.resolutionBits == 24){
                        rawData = (data[offset] << 16) | (data[offset + 1] << 8) | (data[offset + 2]);
                        rawData -= 8388608;
                        offset += 3;
                    }
                    float converted = (float)(rawData * K);
                    sample.rawData = rawData;
                    sample.convertData = converted;
                }
                [synchronyData addSample:sample channelIndex:channelIndex];

            }
        }
    }
}

@end
