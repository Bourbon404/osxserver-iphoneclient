//
//  KAppDelegate.m
//  MyServer
//
//  Created by Kevin on 13-5-15.
//  Copyright (c) 2013年 Kevin. All rights reserved.
//

#import "KAppDelegate.h"
#import "KServer.h"

@implementation KAppDelegate

- (void)dealloc
{
    [server terminateServer];
    [server release];

    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    index = 0;
    
    server = [[[KServer alloc] init] autorelease];
    [server retain];
    server.delegate = self;
    
    [server createServer];
}


- (void) ShowLog:(NSString *)log
{
    NSString* temp = [NSString stringWithFormat:@"%d %@\n", index, log];
    [[self TextLog] setString:[NSString stringWithFormat:@"%@%@", [self TextLog].string, temp]];
    index++;
}

- (IBAction)BtnClear:(id)sender {
    [[self TextLog] setString:@""];
}

- (IBAction)BtnSend:(id)sender {
    [server SendData:@"test data"];
}

@end
