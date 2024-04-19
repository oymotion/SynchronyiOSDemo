//
//  SensorController.h
//  test
//
//  Created by 叶常青 on 2024/4/19.
//

#import <Foundation/Foundation.h>
#import <sensor/sensor.h>
NS_ASSUME_NONNULL_BEGIN

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

@property (atomic, assign) int dataType;
@property (atomic, assign) int lastPackageIndex;
@property (atomic, assign) int lastPackageCounter;
@property (atomic, assign) int resolutionBits;
@property (atomic, assign) int sampleRate;
@property (atomic, assign) int channelCount;
@property (atomic, assign) unsigned long long channelMask;
@property (atomic, assign) int packageSampleCount;
@property (atomic, assign) double K;
@property (atomic, strong) NSMutableArray<NSMutableArray<Sample*>*>* channelSamples;
-(id)init;
-(void)clear;
-(SensorData*)flushSamples;
@end


@protocol SensorControllerDelegate
- (void)onSensorErrorCallback: (NSError*)err;
- (void)onSensorStateChange: (BLEState)newState;
- (void)onSensorScanResult:(NSArray<BLEPeripheral*>*) bleDevices;
- (void)onSensorNotifyData:(SensorData*) rawData;
@end


@interface SensorController : NSObject
@property (atomic, weak) id<SensorControllerDelegate> delegate;
@property (atomic, assign, readonly) BLEState state;
@property (atomic, retain) NSArray<BLEPeripheral*>* scanDevices;
@property (atomic, retain) SensorProfile* profile;
@property (atomic, strong) BLEPeripheral* device;
@property (atomic, strong) SensorData* eegData;
@property (atomic, strong) SensorData* ecgData;
@property (atomic, strong) SensorData* accData;
@property (atomic, strong) SensorData* gyroData;
@property (atomic, strong) NSMutableArray<NSNumber*>* impedanceData;
@property (atomic, strong) NSMutableArray<NSNumber*>* saturationData;
@property (atomic, assign) int lastImpedanceIndex;
@property (atomic, assign) DataNotifyFlags dataFlag;

-(instancetype)init;
-(BOOL)startScan:(NSTimeInterval)timeout;
-(void)stopScan;
-(BOOL)connect:(BLEPeripheral*)peripheral;
-(void)disconnect;
-(void)initDataNotification:(onlyResponseCallback)cb;
-(BOOL)hasInitDataNotification;
-(BOOL)startDataNotification;
-(BOOL)stopDataNotification;
-(GF_RET_CODE)getFeatureMap:(getFeatureMapCallback)cb timeout:(NSTimeInterval)timeout;
-(GF_RET_CODE)getBatteryLevel:(getBatteryLevelCallback)cb timeout:(NSTimeInterval)timeout;
-(GF_RET_CODE)getControllerFirmwareVersion:(getControllerFirmwareVersionCallback)cb timeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
