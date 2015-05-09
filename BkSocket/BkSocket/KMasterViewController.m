//
//  KMasterViewController.m
//  BkSocket
//
//  Created by Kevin on 13-5-14.
//  Copyright (c) 2013年 Kevin. All rights reserved.
//

#import "KMasterViewController.h"

#import "KDetailViewController.h"

@implementation NSStream(StreamsToHost)

+ (void)getStreamsToHostNamed:(NSString *)hostName
                         port:(NSInteger)port
                  inputStream:(out NSInputStream **)inputStreamPtr
                 outputStream:(out NSOutputStream **)outputStreamPtr
{
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    assert(hostName != nil);
    assert( (port > 0) && (port < 65536) );
    assert( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) );
    
    readStream = NULL;
    writeStream = NULL;
    
    CFStreamCreatePairWithSocketToHost(
                                       NULL,
                                       (__bridge CFStringRef) hostName,
                                       port,
                                       ((inputStreamPtr  != NULL) ? &readStream : NULL),
                                       ((outputStreamPtr != NULL) ? &writeStream : NULL)
                                       );
    
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
}

@end

@interface KMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation KMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Master", @"Master");
        
        
  //      [self PlayMP3];
        
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@", @"10.86.35.157", @"58555"]];
//        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@", @"192.168.1.97", @"53438"]];
        
        [NSThread detachNewThreadSelector:@selector(Work_Thread:) toTarget:self withObject:url];
    }
    return self;
}

- (void) PlayMP3
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    NSString *musicPath = [[NSBundle mainBundle] pathForResource:@"Music"
                                                          ofType:@"mp3"];
    if (musicPath) {
        NSURL *musicURL = [NSURL fileURLWithPath:musicPath];
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL
                                                             error:nil];
        //      [audioPlayer setDelegate:self];
        [audioPlayer play];
    }
}
- (void) timerFired: (id)p
{
    NSLog(@"send heart beat");
    
    uint8_t sentData[20] = {0};
    memcpy(sentData, "heartbeat", 9);
    
    //这个没啥用，当切到后台后，程序会被挂起，这个代码也就不会被调用了。当服务器那边有数据发过来的时候，这个iphone客户端才会被唤醒，
    //运行一小段时间后，再次被挂起
 //   [writeStream write:sentData maxLength:20];
    
}

- (void)Work_Thread:(NSURL *)url
{
    NSString* strHost = [url host];
    int port = [[url port] integerValue];
    
    [NSStream getStreamsToHostNamed:strHost port: port inputStream:&readStream outputStream:&writeStream];
    
    [readStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    [writeStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    [readStream setDelegate:self];
    [readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [readStream open];
    NSLog(@"VOIP stream, %x", readStream);
    
    [writeStream open];
    
    uint8_t sentData[20] = {0};
    memcpy(sentData, "hello", 5);
    [writeStream write:sentData maxLength:20];
    
    NSTimer *myTimer = [NSTimer  timerWithTimeInterval: 3 target:self selector:@selector(timerFired:)userInfo:nil repeats:YES];
    
    [[NSRunLoop  currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
    


    NSInputStream* iStream;
    [NSStream getStreamsToHostNamed:strHost port:port inputStream:&iStream outputStream:nil];
    [iStream setDelegate: self];
    [iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [iStream open];
    NSLog(@"normal stream: %x", iStream);

    [[NSRunLoop currentRunLoop] run];

}

- (void)dealloc
{
    [_detailViewController release];
    [_objects release];
    [super dealloc];
}

- (void) working_thread
{
    for (int i = 0; i < 100; i++) {
        NSLog(@"index: %d", i);
        [NSThread sleepForTimeInterval:1];
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@" >> NSStreamDelegate in Thread %@", [NSThread currentThread]);
    
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable: {
            
            
            uint8_t buf[100] = {0};
            int numBytesRead = [(NSInputStream *)stream read:buf maxLength:100];
            
            NSString* str = [NSString stringWithFormat:@"recv: %s", buf];
            
            UILocalNotification* n = [[[UILocalNotification alloc] init] autorelease];
            [n setAlertBody:[NSString stringWithFormat:@"notify: %@, %x", str, stream]];
            [[UIApplication sharedApplication] presentLocalNotificationNow:n];
            break;
        }
            
        case NSStreamEventErrorOccurred: {
            
            break;
        }
            
        case NSStreamEventEndEncountered: {
            
            
            break;
        }
            
        default:
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    
    
    [NSThread detachNewThreadSelector:@selector(working_thread) toTarget:self withObject:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)] autorelease];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }


    NSDate *object = _objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.detailViewController) {
        self.detailViewController = [[[KDetailViewController alloc] initWithNibName:@"KDetailViewController" bundle:nil] autorelease];
    }
    NSDate *object = _objects[indexPath.row];
    self.detailViewController.detailItem = object;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

@end
