//
//  AppDelegate.h
//  test
//
//  Created by 叶常青 on 2023/11/23.
//

#import <UIKit/UIKit.h>

#import <synchrony/synchrony.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{

}
@property (atomic, retain) SynchronyProfile* profile;
@end

