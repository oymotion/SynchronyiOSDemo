//
//  sensorProfile.h
//  sensorProfile
//
//  Created by 叶常青 on 2023/12/21.
//
#ifndef sensor_profile_h
#define sensor_profile_h

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <sensor/BLEPeripheral.h>
#import <sensor/defines.h>


typedef void (^onlyResponseCallback)(GF_RET_CODE resp);
typedef void (^getFeatureMapCallback)(GF_RET_CODE resp, int featureBitmap);
typedef void (^getBatteryLevelCallback)(GF_RET_CODE resp, int batteryLevel);
typedef void (^getControllerFirmwareVersionCallback)(GF_RET_CODE resp, NSString* firmwareVersion);
typedef void (^getSensorDataConfigCallback)(GF_RET_CODE resp, int sampleRate, unsigned long long channelMask, int packageSampleCount, int resolutionBits, double conversionK);
typedef void (^getSensorDataCapCallback)(GF_RET_CODE resp, NSArray<NSNumber*>* supportedSampleRates, int maxChannelCount, int maxPackageSampleCount, NSArray<NSNumber*>* supportedResolutionBits);

@protocol SensorDelegate
- (void)onSensorErrorCallback: (NSError*)err;
- (void)onSensorStateChange: (BLEState)newState;
- (void)onSensorScanResult:(NSArray<BLEPeripheral*>*) bleDevices;
- (void)onSensorNotifyData:(NSData*) rawData;

@end

@interface SensorProfile : NSObject
{
    
}
@property (atomic, weak) id<SensorDelegate> delegate;
@property (atomic, assign, readonly) BLEState state;
-(id)init;
-(BOOL)startScan:(NSTimeInterval)timeout;
-(void)stopScan;
-(BOOL)connect:(BLEPeripheral*)peripheral;
-(void)disconnect;
-(BOOL)startDataNotification;
-(BOOL)stopDataNotification;

-(GF_RET_CODE)getFeatureMap:(getFeatureMapCallback)cb timeout:(NSTimeInterval)timeout;
-(GF_RET_CODE)getBatteryLevel:(getBatteryLevelCallback)cb timeout:(NSTimeInterval)timeout;
-(GF_RET_CODE)getControllerFirmwareVersion:(getControllerFirmwareVersionCallback)cb timeout:(NSTimeInterval)timeout;


-(GF_RET_CODE)setDataNotifSwitch:(DataNotifyFlags)flags cb:(onlyResponseCallback)cb timeout:(NSTimeInterval)timeout;

-(GF_RET_CODE)getEegDataConfig:(getSensorDataConfigCallback)cb timeout:(NSTimeInterval)timeout;
-(GF_RET_CODE)getEcgDataConfig:(getSensorDataConfigCallback)cb timeout:(NSTimeInterval)timeout;

-(GF_RET_CODE)getEegDataCap:(getSensorDataCapCallback)cb timeout:(NSTimeInterval)timeout;
-(GF_RET_CODE)getEcgDataCap:(getSensorDataCapCallback)cb timeout:(NSTimeInterval)timeout;

-(GF_RET_CODE)setEegDataConfig:(int)sampleRate channelMask:(unsigned long long)channelMask sampleCount:(int) sampleCount resolutionBits:(int)resolutionBits cb:(onlyResponseCallback)cb timeout:(NSTimeInterval)timeout;
-(GF_RET_CODE)setEcgDataConfig:(int)sampleRate channelMask:(int)channelMask sampleCount:(int) sampleCount resolutionBits:(int)resolutionBits cb:(onlyResponseCallback)cb timeout:(NSTimeInterval)timeout;

@end

#endif
