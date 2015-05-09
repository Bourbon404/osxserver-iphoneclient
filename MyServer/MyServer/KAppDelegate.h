//
//  KAppDelegate.h
//  MyServer
//
//  Created by Kevin on 13-5-15.
//  Copyright (c) 2013年 Kevin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KServer.h"

@interface KAppDelegate : NSObject <NSApplicationDelegate>
{
    KServer* server;
    int index;
}

@property (assign) IBOutlet NSWindow *window;
- (IBAction)BtnSend:(id)sender;


- (void) ShowLog: (NSString*)log;
- (IBAction)BtnClear:(id)sender;
@property (assign) IBOutlet NSTextView *TextLog;

@end
