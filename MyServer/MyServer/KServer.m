//
//  KServer.m
//  MyServer
//
//  Created by Kevin on 13-5-15.
//  Copyright (c) 2013年 Kevin. All rights reserved.
//

#import "KServer.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>
#import "KAppDelegate.h"
#include <arpa/inet.h>

@implementation ClientSocket



@end

@implementation KServer

- (id) init
{
    self = [super init];
    if (self) {
   //     [self createServer];
        m_AllClients = [NSMutableArray arrayWithCapacity:0];
        [m_AllClients retain];
    }
    
    return self;
}

- (void) dealloc
{
    [m_AllClients release];
    [super dealloc];
}

// 读取数据
void readStream(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
    UInt8 buff[255];
    CFReadStreamRead(stream, buff, 20);
  //  printf("received: %s", buff);
    KServer* context = (KServer*)clientCallBackInfo;
    [context ShowLog:[NSString stringWithFormat:@"recv: %s", buff]];
}

void writeStream (CFWriteStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {

    UInt8 buf[255] = "welcome CFSocket";
    int len = strlen(buf);
    CFWriteStreamWrite(stream, buf, len);
    
    KServer* context = (KServer*)clientCallBackInfo;
    [context ShowLog:[NSString stringWithFormat:@"Send data: %s", buf]];
}

#pragma mark Callbacks

// Handle new connections
- (void)handleNewNativeSocket:(CFSocketNativeHandle)nativeSocketHandle {
    ClientSocket* c = [[[ClientSocket alloc] init] autorelease];
    c.sock = nativeSocketHandle;
    [m_AllClients addObject:c];
    
    uint8_t name[SOCK_MAXADDRLEN];
    socklen_t nameLen = sizeof(name);
    if (0 != getpeername(nativeSocketHandle, (struct sockaddr *)name, &nameLen)) {
        NSLog(@"error");
        exit(1);
    }
    
    KAppDelegate* d = (KAppDelegate*)[self delegate];
    struct sockaddr_in* addr = (struct sockaddr_in *)name;
    [d ShowLog:[NSString stringWithFormat:@"connected, client: %s, %d", inet_ntoa(addr->sin_addr), ntohs(addr->sin_port)]];
    
    //写一些数据给客户端
    CFReadStreamRef iStream;
    CFWriteStreamRef oStream;
    // 创建一个可读写的socket连接
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &iStream, &oStream);
    if (iStream && oStream) {
        CFStreamClientContext streamContext = {0, self, NULL, NULL};
        if (!CFReadStreamSetClient(iStream, kCFStreamEventHasBytesAvailable,
                                   readStream, // 回调函数，当有可读的数据时调用
                                   &streamContext)){
            exit(1);
        }
        
        if (!CFWriteStreamSetClient(oStream, kCFStreamEventCanAcceptBytes, writeStream, &streamContext)){
            exit(1);
        }
        
        CFReadStreamScheduleWithRunLoop(iStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
   //     CFWriteStreamScheduleWithRunLoop(oStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamOpen(iStream);
   //     CFWriteStreamOpen(oStream);
        
        NSString *stringTosend = @"Welcome CFSocker server";
        [self SendData:stringTosend];
    } else {
        close(nativeSocketHandle);
    }
}

- (void) SendData:(NSString *)data
{
    const char *szData = [data UTF8String];

    for (ClientSocket* s in m_AllClients) {
        
        size_t len = strlen(szData);
        size_t sent = send(s.sock, szData, len, 0);
        
        [self ShowLog:[NSString stringWithFormat:@"Send data: %s, count: %d", szData, sent]];
    }
}

// This function will be used as a callback while creating our listening socket via 'CFSocketCreate'
static void serverAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    
    // We can only process "connection accepted" calls here
    if ( type != kCFSocketAcceptCallBack ) {
    	return;
    }
    
    // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
    CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data;
    
    KServer *server = (KServer*)info;
    [server handleNewNativeSocket:nativeSocketHandle];
}

- (void)ShowLog:(NSString *)log
{
    KAppDelegate* d = (KAppDelegate*)[self delegate];
    
    [d ShowLog:log];
}

- (BOOL)createServer
{
    //// PART 1: Create a socket that can accept connections
    
    // Socket context
    //  struct CFSocketContext {
    //   CFIndex version;
    //   void *info;
    //   CFAllocatorRetainCallBack retain;
    //   CFAllocatorReleaseCallBack release;
    //   CFAllocatorCopyDescriptionCallBack copyDescription;
    //  };
    CFSocketContext socketContext = {0, self, NULL, NULL, NULL};
    
    listeningSocket = CFSocketCreate(
    								 kCFAllocatorDefault,
    								 PF_INET,        // The protocol family for the socket
    								 SOCK_STREAM,    // The socket type to create
    								 IPPROTO_TCP,    // The protocol for the socket. TCP vs UDP.
    								 kCFSocketAcceptCallBack,  // New connections will be automatically accepted and the callback is called with the data argument being a pointer to a CFSocketNativeHandle of the child socket.
    								 (CFSocketCallBack)&serverAcceptCallback,
    								 &socketContext );
    
    // Previous call might have failed
    if ( listeningSocket == NULL ) {
    	status = @"listeningSocket Not Created";
    	return FALSE;
    }
    else {
    	status = @"listeningSocket Created";
    	int existingValue = 1;
        
        // Make sure that same listening socket address gets reused after every connection
        setsockopt( CFSocketGetNative(listeningSocket),
                   SOL_SOCKET, SO_REUSEADDR, (void *)&existingValue,
                   sizeof(existingValue));
        
        
        //// PART 2: Bind our socket to an endpoint.
        // We will be listening on all available interfaces/addresses.
        // Port will be assigned automatically by kernel.
        struct sockaddr_in socketAddress;
        memset(&socketAddress, 0, sizeof(socketAddress));
        socketAddress.sin_len = sizeof(socketAddress);
        socketAddress.sin_family = AF_INET;   // Address family (IPv4 vs IPv6)
        socketAddress.sin_port = 0;           // Actual port will get assigned automatically by kernel
        socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);    // We must use "network byte order" format (big-endian) for the value here
        
        // Convert the endpoint data structure into something that CFSocket can use
        NSData *socketAddressData =
        [NSData dataWithBytes:&socketAddress length:sizeof(socketAddress)];
        
        // Bind our socket to the endpoint. Check if successful.
        if ( CFSocketSetAddress(listeningSocket, (CFDataRef)socketAddressData) != kCFSocketSuccess ) {
            // Cleanup
            if ( listeningSocket != NULL ) {
                status = @"Socket Not Binded";
                CFRelease(listeningSocket);
                listeningSocket = NULL;
            }
            
            return FALSE;
        }
        status = @"Socket Binded";
        
        //// PART 3: Find out what port kernel assigned to our socket
        // We need it to advertise our service via Bonjour
        NSData *socketAddressActualData = [(NSData *)CFSocketCopyAddress(listeningSocket) autorelease];
        
        // Convert socket data into a usable structure
        struct sockaddr_in socketAddressActual;
        memcpy(&socketAddressActual, [socketAddressActualData bytes],
               [socketAddressActualData length]);
        
        port = ntohs(socketAddressActual.sin_port);
        
   //     char* ip = inet_ntoa(socketAddressActual.sin_addr);
        
        
        //// PART 4: Hook up our socket to the current run loop
        CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
        CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, listeningSocket, 0);
        CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
        
        KAppDelegate* d = (KAppDelegate*)[self delegate];
        [d ShowLog:[NSString stringWithFormat:@"Create server socket successfully, port: %d", port]];

        
        return TRUE;
    }
}

- (void) terminateServer {
    if ( listeningSocket != nil ) {
    	CFSocketInvalidate(listeningSocket);
    	CFRelease(listeningSocket);
    	listeningSocket = nil;
    }
}

@end
