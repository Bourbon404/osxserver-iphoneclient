//
//  KDetailViewController.h
//  BkSocket
//
//  Created by Kevin on 13-5-14.
//  Copyright (c) 2013年 Kevin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
