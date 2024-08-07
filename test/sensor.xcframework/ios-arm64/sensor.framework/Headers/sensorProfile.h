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

@interface DeviceInfo : NSObject
@property (atomic, assign) int MTUSize;
@property (atomic, strong) NSString* deviceName;
@property (atomic, strong) NSString* modelName;
@property (atomic, strong) NSString* hardwareVersion;
@property (atomic, strong) NSString* firmwareVersion;
@end

@interface Sample : NSObject
@property (atomic, assign) int timeStampInMs;
@property (atomic, assign) int sampleIndex;
@property (atomic, assign) int channelIndex;
@property (atomic, assign) BOOL isLost;
@property (atomic, assign) float rawData;
@property (atomic, assign) float convertData;
@property (atomic, assign) float impedance;
@property (atomic, assign) float saturation;
@end

@interface SensorData : NSObject

@property (atomic, assign) NotifyDataType dataType;
@property (atomic, assign) int lastPackageIndex;
@property (atomic, assign) int lastPackageCounter;
@property (atomic, assign) int resolutionBits;
@property (atomic, assign) int sampleRate;
@property (atomic, assign) int channelCount;
@property (atomic, assign) unsigned long long channelMask;
@property (atomic, assign) int packageSampleCount;
@property (atomic, assign) int minPackageSampleCount;
@property (atomic, assign) double K;
@property (atomic, strong) NSArray<NSArray<Sample*>*>* channelSamples;
-(id)init;
-(void)clear;
-(SensorData*)flushSamples;
@end

@protocol SensorProfileDelegate
- (void)onSensorErrorCallback: (NSError*)err;
- (void)onSensorStateChange: (BLEState)newState;
- (void)onSensorNotifyData:(SensorData*) rawData;
@end

@interface SensorProfile : NSObject
{
    
}
@property (atomic, weak) id<SensorProfileDelegate> delegate;
@property (atomic, assign, readonly) BLEState state;
@property (atomic, readonly) NSString* stateString;
@property (atomic, strong, readonly) BLEPeripheral* device;
@property (atomic, assign, readonly) bool hasEEG;
@property (atomic, assign, readonly) bool hasECG;
@property (atomic, assign, readonly) bool hasInit;
@property (atomic, assign, readonly) bool isMTUFine;
@property (atomic, assign, readonly) int EEGChannelCount;
@property (atomic, assign, readonly) int ECGChannelCount;
@property (atomic, assign, readonly) int AccChannelCount;
@property (atomic, assign, readonly) int GyroChannelCount;
@property (atomic, assign, readonly) bool hasStartDataNotification;


-(BOOL)connect;
-(void)disconnect;
-(BOOL)startDataNotification;
-(BOOL)stopDataNotification;

- (void)initAll:(int)packageCount timeout:(NSTimeInterval)timeout completion:(void (^)(BOOL success))completionHandler;
- (void)initEEG:(int)packageCount timeout:(NSTimeInterval)timeout completion:(void (^)(BOOL success))completionHandler;
- (void)initECG:(int)packageCount timeout:(NSTimeInterval)timeout completion:(void (^)(BOOL success))completionHandler;
- (void)initIMU:(int)packageCount timeout:(NSTimeInterval)timeout completion:(void (^)(BOOL success))completionHandler;
- (void)initDataTransfer:(BOOL)isGetFeature  timeout:(NSTimeInterval)timeout completion:(void (^)(int flag))completionHandler;
- (void)getBattery:(NSTimeInterval)timeout completion:(void (^)(int battery))completionHandler;
- (void)getDeviceInfo:(BOOL)onlyMTU timeout:(NSTimeInterval)timeout completion:(void (^)(DeviceInfo* deviceInfo))completionHandler;
- (void)startDataNotification:(NSTimeInterval)timeout completion:(void (^)(BOOL success))completionHandler;
- (void)stopDataNotification:(NSTimeInterval)timeout completion:(void (^)(BOOL success))completionHandler;

@end

#endif
