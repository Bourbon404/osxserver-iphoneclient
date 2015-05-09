//
//  KMasterViewController.h
//  BkSocket
//
//  Created by Kevin on 13-5-14.
//  Copyright (c) 2013年 Kevin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class KDetailViewController;

@interface KMasterViewController : UITableViewController <NSStreamDelegate>
{
    AVAudioPlayer *audioPlayer;
    NSInputStream* readStream;
    NSOutputStream* writeStream;
}

@property (strong, nonatomic) KDetailViewController *detailViewController;

@end
