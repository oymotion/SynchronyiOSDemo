//
//  SensorController.m
//  test
//
//  Created by 叶常青 on 2024/4/19.
//

#import "SensorController.h"


const int TIMEOUT = 5; //5 seconds

@interface SensorController()<SensorDelegate>
{
    dispatch_queue_t        _methodQueue;
    dispatch_queue_t        _senderQueue;
    bool hasEEG;
    bool hasECG;
}
@end

@implementation SensorController

-(BLEState) state{
    return self.profile.state;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.profile = [[SensorProfile alloc] init];
        self.profile.delegate = self;
        hasEEG = hasECG = FALSE;
        _methodQueue = dispatch_queue_create("SensorSDK", DISPATCH_QUEUE_SERIAL);
        _senderQueue = dispatch_queue_create("SensorSDK_data", DISPATCH_QUEUE_SERIAL);
        self.dataFlag = (DataNotifyFlags)(DNF_ACCELERATE  |DNF_IMPEDANCE);
        [self _initACC_GYRO];
    }
    return self;
}

-(void)clearSamples{
    [self.eegData clear];
    [self.ecgData clear];
    [self.accData clear];
    [self.gyroData clear];
    self.impedanceData = [[NSMutableArray alloc] init];
    self.saturationData = [[NSMutableArray alloc] init];
}

-(void)_initACC_GYRO{
    self.accData = [[SensorData alloc] init];
    SensorData* data = self.accData;
    data.dataType = NTF_ACC_DATA;
    data.sampleRate = 50;
    data.channelMask = 255;
    data.channelCount = 3;
    data.resolutionBits = 16;
    data.packageSampleCount = 1;
    data.K = 1 / 8192.0;
    [data clear];
    
    self.gyroData = [[SensorData alloc] init];
    data = self.gyroData;
    data.dataType = NTF_GYO_DATA;
    data.sampleRate = 50;
    data.channelMask = 255;
    data.channelCount = 3;
    data.resolutionBits = 16;
    data.packageSampleCount = 1;
    data.K = 1 / 16.4;
    [data clear];
}


-(BOOL)startScan:(NSTimeInterval)timeout{
    [self clearSamples];
    return [self.profile startScan:timeout];
}

-(void)stopScan{
    [self.profile stopScan];
}

-(BOOL)connect:(BLEPeripheral*)peripheral{
    return [self.profile connect:peripheral];
}

-(void)disconnect{
    [self.profile disconnect];
}

-(BOOL)hasInitDataNotification{
    return (hasEEG || hasECG);
}

-(void)initDataNotification:(onlyResponseCallback)cb{
    const int PACKAGE_COUNT = 10;
    [self _initEEG:PACKAGE_COUNT callback:^(GF_RET_CODE resp) {
        if (resp == GF_SUCCESS){
            hasEEG = TRUE;
        }
        [self _initECG:PACKAGE_COUNT callback:^(GF_RET_CODE resp) {
            if (resp == GF_SUCCESS){
                hasECG = TRUE;
            }
            if (hasEEG || hasECG){
                [self.profile setDataNotifSwitch:self.dataFlag cb:^(GF_RET_CODE resp) {
                    if (resp == GF_SUCCESS){
                        cb(GF_SUCCESS);
                    }else{
                        cb(GF_ERROR_BAD_STATE);
                    }
                } timeout:TIMEOUT];
            }
        }];
    }];

}

- (void)_initEEG:(int)inPackageSampleCount callback:(onlyResponseCallback)cb{
    if (self.profile.state != BLEStateRunning){
        NSLog(@"initEEG, device not connected");
        cb(GF_ERROR_BAD_STATE);
        return;
    }
    [self.profile getEegDataConfig:^(GF_RET_CODE resp, int sampleRate, unsigned long long channelMask, int packageSampleCount, int resolutionBits, double conversionK) {
        if (resp == GF_SUCCESS){
            self.eegData = [[SensorData alloc] init];
            SensorData* data = self.eegData;
            data.dataType = NTF_EEG;
            data.sampleRate = sampleRate;
            data.channelMask = channelMask;
            data.resolutionBits = resolutionBits;
            data.packageSampleCount = packageSampleCount;
            data.K = conversionK;
            [data clear];
            
            [self.profile getEegDataCap:^(GF_RET_CODE resp, NSArray *supportedSampleRates, int maxChannelCount, int maxPackageSampleCount, NSArray *supportedResolutionBits) {
                
                if (resp == GF_SUCCESS){
                    SensorData* data = self.eegData;
                    data.channelCount = maxChannelCount;
                    self.dataFlag = (DataNotifyFlags)(self.dataFlag | DNF_EEG);
                    //            NSLog(@"got eegData info: %d %d %llu %d", data.sampleRate, data.channelCount, data.channelMask, data.packageSampleCount);
                    if (inPackageSampleCount <= 0){
                        cb(GF_ERROR_BAD_STATE);
                        return;
                    }
                    [self.profile setEegDataConfig:data.sampleRate channelMask:data.channelMask sampleCount:inPackageSampleCount resolutionBits:data.resolutionBits cb:^(GF_RET_CODE resp) {
                        if (resp == GF_SUCCESS){
                            data.packageSampleCount = inPackageSampleCount;
                            cb(GF_SUCCESS);
                        }else{
                            NSString* err = [NSString stringWithFormat:@"device return error: %ld", (long)resp];
                            NSLog(err);
                            cb(GF_ERROR_BAD_STATE);
                            return;
                        }
                    } timeout:TIMEOUT];
                }else{
                    NSString* err = [NSString stringWithFormat:@"device return error: %ld", (long)resp];
                    NSLog(err);
                    cb(GF_ERROR_BAD_STATE);
                    return;
                }
            } timeout:TIMEOUT];
        }else{
            NSString* err = [NSString stringWithFormat:@"device return error: %ld", (long)resp];
            NSLog(err);
            cb(GF_ERROR_BAD_STATE);
            return;
        }
    } timeout:TIMEOUT];
}


-(void)_initECG:(int)inPackageSampleCount callback:(onlyResponseCallback)cb{
    if (self.profile.state != BLEStateRunning){
        NSLog(@"initECG, device not connected", nil);
        cb(GF_ERROR_BAD_STATE);
        return;
    }
    [self.profile getEcgDataConfig:^(GF_RET_CODE resp, int sampleRate, unsigned long long channelMask, int packageSampleCount, int resolutionBits, double conversionK) {
        if (resp == GF_SUCCESS){
            self.ecgData = [[SensorData alloc] init];
            SensorData* data = self.ecgData;
            data.dataType = NTF_ECG;
            data.sampleRate = sampleRate;
            data.channelMask = channelMask;
            data.resolutionBits = resolutionBits;
            data.packageSampleCount = packageSampleCount;
            data.K = conversionK;
            [data clear];
            
            [self.profile getEcgDataCap:^(GF_RET_CODE resp, NSArray *supportedSampleRates, int maxChannelCount, int maxPackageSampleCount, NSArray *supportedResolutionBits) {
                
                if (resp == GF_SUCCESS){
                    SensorData* data = self.ecgData;
                    data.channelCount = maxChannelCount;
                    self.dataFlag = (DataNotifyFlags)(self.dataFlag | DNF_ECG);
                    //            NSLog(@"got ecgData info: %d %d %llu %d", data.sampleRate, data.channelCount, data.channelMask, data.packageSampleCount);
                    if (inPackageSampleCount <= 0){
                        cb(GF_ERROR_BAD_STATE);
                        return;
                    }
                    [self.profile setEcgDataConfig:data.sampleRate channelMask:data.channelMask sampleCount:inPackageSampleCount resolutionBits:data.resolutionBits cb:^(GF_RET_CODE resp) {
                        if (resp == GF_SUCCESS){
                            data.packageSampleCount = inPackageSampleCount;
                            cb(GF_SUCCESS);
                        }else{
                            NSString* err = [NSString stringWithFormat:@"device return error: %ld", (long)resp];
                            NSLog(err);
                            cb(GF_ERROR_BAD_STATE);
                            return;
                        }
                    } timeout:TIMEOUT];
                }else{
                    NSString* err = [NSString stringWithFormat:@"device return error: %ld", (long)resp];
                    NSLog(err);
                    cb(GF_ERROR_BAD_STATE);
                    return;
                }
            } timeout:TIMEOUT];
        }else{
            NSString* err = [NSString stringWithFormat:@"device return error: %ld", (long)resp];
            NSLog(err);
            cb(GF_ERROR_BAD_STATE);
            return;
        }
    } timeout:TIMEOUT];
}

-(BOOL)startDataNotification{
    return [self.profile startDataNotification];
}

-(BOOL)stopDataNotification{
    return [self.profile stopDataNotification];
}

-(GF_RET_CODE)getFeatureMap:(getFeatureMapCallback)cb timeout:(NSTimeInterval)timeout{
    return [self.profile getFeatureMap:cb timeout:timeout];
}

-(GF_RET_CODE)getBatteryLevel:(getBatteryLevelCallback)cb timeout:(NSTimeInterval)timeout{
    return [self.profile getBatteryLevel:cb timeout:timeout];
}

-(GF_RET_CODE)getControllerFirmwareVersion:(getControllerFirmwareVersionCallback)cb timeout:(NSTimeInterval)timeout{
    return [self.profile getControllerFirmwareVersion:cb timeout:timeout];
}

- (void)onSensorErrorCallback:(NSError *)err {
    [self.delegate onSensorErrorCallback:err];
}

- (void)onSensorScanResult:(NSArray<BLEPeripheral *> *)bleDevices {
    [self.delegate onSensorScanResult:bleDevices];
}

- (void)onSensorStateChange:(BLEState)newState {
    if (newState == BLEStateUnConnected){
        self.dataFlag = (DataNotifyFlags)(DNF_ACCELERATE  |DNF_IMPEDANCE);
        hasEEG = hasECG = FALSE;
        [self clearSamples];
    }
    [self.delegate onSensorStateChange:newState];
}


- (void)onSensorNotifyData:(NSData *)rawData {
    dispatch_async(_senderQueue, ^{
        
        if (rawData.length > 1){
            unsigned char* result = (unsigned char*)rawData.bytes;

            if (result[0] == NTF_EEG){
                SensorData* sensorData = self.eegData;
                if ([self checkReadSamples:result sensorData:sensorData dataOffset:3])
                    [self sendSamples:sensorData];
            }
            else if (result[0] == NTF_ECG){
                SensorData* sensorData = self.ecgData;
                if ([self checkReadSamples:result sensorData:sensorData dataOffset:3])
                    [self sendSamples:sensorData];
            }else if (result[0] == NTF_ACC_DATA){
                SensorData* sensorData = self.accData;
                if ([self checkReadSamples:result sensorData:sensorData dataOffset:3])
                    [self sendSamples:sensorData];
                
                sensorData = self.gyroData;
                if ([self checkReadSamples:result sensorData:sensorData dataOffset:9])
                    [self sendSamples:sensorData];
            }
            else if (result[0] == NTF_IMPEDANCE){
                NSMutableArray* impedanceData = [[NSMutableArray alloc] init];
                NSMutableArray* railData = [[NSMutableArray alloc] init];

                int dataCount = (rawData.length - 3) / 4 / 2;
                int counter = (result[2] << 8) | result[1];
    //                NSLog(@"got impedance data : %d %d", dataCount, counter);
                int offset = 3;
                for (int index = 0;index < dataCount;++index, offset += 4){
                    unsigned char bytes[4];
                    bytes[0] = result[offset];
                    bytes[1] = result[offset + 1];
                    bytes[2] = result[offset + 2];
                    bytes[3] = result[offset + 3];
        
                    float data = *((float*)(bytes));
                    [impedanceData addObject:[NSNumber numberWithFloat:data]];
                }
                
                for (int index = 0;index < dataCount;++index, offset += 4){
                    unsigned char bytes[4];
                    bytes[0] = result[offset];
                    bytes[1] = result[offset + 1];
                    bytes[2] = result[offset + 2];
                    bytes[3] = result[offset + 3];
        
                    float data = (*((float*)(bytes))) / 10; //firmware value range 0-1000
                    [railData addObject:[NSNumber numberWithFloat:data]];
                }
                
                self.impedanceData = impedanceData;
                self.saturationData = railData;
            }
        }

    });
}


- (BOOL)checkReadSamples:(unsigned char *)result sensorData:(SensorData*) sensorData dataOffset:(int)dataOffset{
    int readOffset = 1;

    @try {
        int packageIndex = *((unsigned short*)(result + readOffset));
        readOffset += 2;
        int newPackageIndex = packageIndex;
//                NSLog(@"packageindex: %d", packageIndex);
        int lastPackageIndex = sensorData.lastPackageIndex;
        
        if (packageIndex < lastPackageIndex){
            packageIndex += 65536;
        }else if (packageIndex == lastPackageIndex){
            //same index is not right
//                    NSLog(@"Repeat index: %d", packageIndex);
            return FALSE;
        }
        int deltaPackageIndex = packageIndex - lastPackageIndex;
        if (deltaPackageIndex > 1){
            int lostSampleCount = sensorData.packageSampleCount * (deltaPackageIndex - 1);
//                    NSLog(@"lost samples: %d", lostSampleCount);
            [self readSamples:result sensorData:sensorData offset:0 lostSampleCount:lostSampleCount];
            if (newPackageIndex == 0){
                sensorData.lastPackageIndex = 65535;
            }else{
                sensorData.lastPackageIndex = newPackageIndex - 1;
            }
            sensorData.lastPackageCounter += (deltaPackageIndex - 1);
        }
        [self readSamples:result sensorData:sensorData offset:dataOffset lostSampleCount:0];
        sensorData.lastPackageIndex = newPackageIndex;
        sensorData.lastPackageCounter++;
    } @catch (NSException *exception) {
        NSLog(@"Error: %@", [exception description]);
        return FALSE;
    } @finally {
        
    }
    return TRUE;
}

- (void)readSamples:(unsigned char *)data sensorData:(SensorData*) sensorData offset:(int)offset lostSampleCount:(int)lostSampleCount{
    
    int sampleCount = sensorData.packageSampleCount;
    int sampleInterval = 1000 / sensorData.sampleRate; // sample rate should be less than 1000
    if (lostSampleCount > 0)
        sampleCount = lostSampleCount;
    
    double K = sensorData.K;
    int lastSampleIndex = sensorData.lastPackageCounter * sensorData.packageSampleCount;
    
    NSMutableArray* impedanceData = self.impedanceData;
    NSMutableArray* saturationData = self.saturationData;
    NSMutableArray<NSMutableArray<Sample*>*>* channelSamples = [sensorData.channelSamples copy];
    if (channelSamples == nil){
        channelSamples = [NSMutableArray new];
        for (int channelIndex = 0; channelIndex < sensorData.channelCount; ++ channelIndex){
            [channelSamples addObject:[NSMutableArray new]];
        }
    }

    for (int sampleIndex = 0;sampleIndex < sampleCount; ++sampleIndex, ++lastSampleIndex){
        for (int channelIndex = 0, impedanceChannelIndex = 0; channelIndex < sensorData.channelCount; ++channelIndex){
            if ((sensorData.channelMask & (1 << channelIndex)) > 0){
                NSMutableArray<Sample*>* samples = [channelSamples objectAtIndex:channelIndex];
                float impedance = 0;
                float saturation = 0;
                if (sensorData.dataType == NTF_ECG){
                    impedanceChannelIndex = self.eegData.channelCount;
                }
                if ((impedanceChannelIndex >= 0) && (impedanceChannelIndex < [impedanceData count])){
                    impedance = [[impedanceData objectAtIndex:impedanceChannelIndex] floatValue];
                    saturation = [[saturationData objectAtIndex:impedanceChannelIndex] floatValue];
                }
                ++impedanceChannelIndex;
                
                Sample* sample = [[Sample alloc] init];
                sample.channelIndex = channelIndex;
                sample.sampleIndex = lastSampleIndex;
                sample.timeStampInMs = lastSampleIndex * sampleInterval;
                if (lostSampleCount > 0){
                    //add missing samples with 0
                    sample.rawData = 0;
                    sample.convertData = 0;
                    sample.impedance = impedance;
                    sample.saturation = saturation;
                    sample.isLost = TRUE;
                }else{
                    if (sensorData.resolutionBits == 8){
                        int rawData = data[offset];
                        rawData -= 128;
                        offset += 1;
                        sample.rawData = rawData;
                    }else if (sensorData.resolutionBits == 16){
                        int rawData = *((short*)(data + offset));
                        offset += 2;
                        sample.rawData = rawData;
                    }else if (sensorData.resolutionBits == 24){
                        int rawData = (data[offset] << 16) | (data[offset + 1] << 8) | (data[offset + 2]);
                        rawData -= 8388608;
                        offset += 3;
                        sample.rawData = rawData;
                    }
                    sample.convertData = sample.rawData * K;
                    sample.impedance = impedance;
                    sample.saturation = saturation;
                    sample.isLost = FALSE;
                }
                [samples addObject:sample];
            }
        }
    }
    
    sensorData.channelSamples = channelSamples;
}

- (void)sendSamples:(SensorData*) sensorData{
    
    SensorData* sampleResult = [sensorData flushSamples];
    if (sampleResult != nil){
        [self.delegate onSensorNotifyData:sampleResult];
    }

}
@end


@implementation Sample
@end

@implementation SensorData
-(id)init{
    if (self = [super init]) {

    }
    return self;
}

-(void)clear{
    self.lastPackageIndex = 0;
    self.lastPackageCounter = 0;
}


-(SensorData*)flushSamples{
    SensorData* result = [[SensorData alloc] init];
    result.dataType = self.dataType;
    result.resolutionBits = self.resolutionBits;
    result.sampleRate = self.sampleRate;
    result.channelCount = self.channelCount;
    result.channelMask = self.channelMask;
    result.channelSamples = self.channelSamples;
    
    self.channelSamples = nil;
    
    return result;
}
@end

