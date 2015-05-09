//
//  KServer.h
//  MyServer
//
//  Created by Kevin on 13-5-15.
//  Copyright (c) 2013年 Kevin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KServer : NSObject
{
    uint16_t port;
    CFSocketRef listeningSocket;
    NSString *status;

    NSMutableArray* m_AllClients;
}

@property(nonatomic, assign) id delegate;

- (BOOL)createServer;
- (void) terminateServer;

- (void) SendData: (NSString*)data;

- (void) ShowLog: (NSString*)log;

@end

@interface ClientSocket : NSObject

@property(nonatomic, assign) CFSocketNativeHandle sock;

@end
