//
//  ViewController.h
//  test
//
//  Created by 叶常青 on 2023/11/23.
//

#import <UIKit/UIKit.h>
#import <synchrony/synchrony.h>

const int TIMEOUT = 5;
const int MAX_SAMPLE_COUNT = 256;
const int MAX_CHANNEL_COUNT = 8;


@interface SynchronySample : NSObject
@property (atomic, assign) int rawDataSampleIndex;
@property (atomic, assign) int rawData;
@property (atomic, assign) float convertData;
@end


@interface SynchronyData : NSObject
{
    NSMutableArray* samples[MAX_CHANNEL_COUNT];
}
@property (atomic, assign) int lastPackageIndex;
@property (atomic, assign) int resolutionBits;
@property (atomic, assign) int sampleRate;
@property (atomic, assign) int channelCount;
@property (atomic, assign) int channelMask;
@property (atomic, assign) int packageSampleCount;
@property (atomic, assign) double K;
-(id)init;
-(void)addSample:(SynchronySample*)sample channelIndex:(int)channelIndex;
@end


@interface ViewController : UIViewController
{

}
@property (nonatomic, retain) IBOutlet UIButton *scanButton;
@property (nonatomic, retain) IBOutlet UIButton *connectButton;
@property (nonatomic, retain) IBOutlet UIButton *versionButton;

@property (nonatomic, retain) IBOutlet UILabel *deviceText;
@property (nonatomic, retain) IBOutlet UILabel *statusText;
@property (nonatomic, retain) IBOutlet UILabel *versionText;

- (IBAction)onScan:(id)sender;
- (IBAction)onConnect:(id)sender;
- (IBAction)onVersion:(id)sender;
@end

