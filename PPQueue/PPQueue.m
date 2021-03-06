//
//  PPQueue.m --> a fork from EDQueue
//  ppqueue
//
//  Created by Daniel Luethi 2015
//  Copyright (c) 2015 All rights reserved.
//

#import "PPQueue.h"
#import "PPQueueStorageEngine.h"

NSString *const PPQueueDidStart = @"PPQueueDidStart";
NSString *const PPQueueDidStop = @"PPQueueDidStop";
NSString *const PPQueueJobDidSucceed = @"PPQueueJobDidSucceed";
NSString *const PPQueueJobDidFail = @"PPQueueJobDidFail";
NSString *const PPQueueDidDrain = @"PPQueueDidDrain";

@interface PPQueue ()
{
    BOOL _isRunning;
    NSUInteger _retryLimit;
}

@property (nonatomic) PPQueueStorageEngine *engine;
@property (nonatomic, readwrite) NSString *activeTask;
@property dispatch_queue_t jobProcessingQueue;

@end

//

@implementation PPQueue

@synthesize isRunning = _isRunning;
@synthesize retryLimit = _retryLimit;

#pragma mark - Singleton

+ (PPQueue *)sharedInstance
{
    static PPQueue *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        _engine     = [[PPQueueStorageEngine alloc] init];
        _retryLimit = 4;
        _jobProcessingQueue = dispatch_queue_create([[NSString stringWithFormat:@"PPQueue.%p",self] UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    _engine = nil;
}

#pragma mark - Public methods

- (void)enqueueWithData:(id)data forTask:(NSString *)task withPriority:(NSUInteger)priority {
    if (data == nil) data = @{};

    [self.engine createJob:data forTask:task withPriority:priority];
    dispatch_async(_jobProcessingQueue, ^{
        [self tick];
    });
}

- (void)enqueueWithData:(id)data forTask:(NSString *)task {
    [self enqueueWithData:data forTask:task withPriority:0];
}

- (void)removeOldJobs:(NSString*)timeInterval {
    [self.engine removeOldJobs:timeInterval];
}

- (BOOL)jobExistsForTask:(NSString *)task
{
    BOOL jobExists = [self.engine jobExistsForTask:task];
    return jobExists;
}

- (BOOL)jobIsActiveForTask:(NSString *)task
{
    BOOL jobIsActive = [self.activeTask length] > 0 && [self.activeTask isEqualToString:task];
    return jobIsActive;
}

- (NSDictionary *)nextJobForTask:(NSString *)task
{
    NSDictionary *nextJobForTask = [self.engine fetchJobForTask:task];
    return nextJobForTask;
}

- (void)start
{
    if (!self.isRunning) {
        _isRunning = YES;
        dispatch_async(_jobProcessingQueue, ^{
            [self tick];
        });
        [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:PPQueueDidStart, @"name", nil, @"data", nil] waitUntilDone:false];
    }
}

- (void)stop
{
    if (self.isRunning) {
        _isRunning = NO;
        [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:PPQueueDidStop, @"name", nil, @"data", nil] waitUntilDone:false];
    }
}



- (void)empty
{
    [self.engine removeAllJobs];
}


#pragma mark - Private methods

/**
* Checks the queue for available jobs, sends them to the processor delegate, and then handles the response.
*
* @return {void}
*/
- (void)tick
{
    if (self.isRunning && [self.engine fetchJobCount] > 0) {
        // Start job
        id job = [self.engine fetchJob];
        self.activeTask = [(NSDictionary *)job objectForKey:@"task"];

        // Pass job to delegate
        if ([self.delegate respondsToSelector:@selector(queue:processJob:completion:)]) {
            [self.delegate queue:self processJob:job completion:^(PPQueueResult result) {
                [self processJob:job withResult:result];
                self.activeTask = nil;
            }];
        } else {
            PPQueueResult result = [self.delegate queue:self processJob:job];
            [self processJob:job withResult:result];
            self.activeTask = nil;
        }
    }
}

- (void)processJob:(NSDictionary*)job withResult:(PPQueueResult)result
{
    // Check result
    switch (result) {
        case PPQueueResultSuccess:
            [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:PPQueueJobDidSucceed, @"name",
                                                                                                                                 job, @"data", nil] waitUntilDone:false];
            [self.engine removeJob:[job objectForKey:@"id"]];
            break;
        case PPQueueResultFail:
            [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:PPQueueJobDidFail, @"name",
                                                                                                                                 job, @"data", nil] waitUntilDone:true];
            NSUInteger currentAttempt = [[job objectForKey:@"attempts"] intValue] + 1;
            if (currentAttempt < self.retryLimit) {
                [self.engine incrementAttemptForJob:[job objectForKey:@"id"]];
            } else {
                [self.engine removeJob:[job objectForKey:@"id"]];
            }
            break;
        case PPQueueResultCritical:
            [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:PPQueueJobDidFail, @"name",
                                                                                                                                 job, @"data", nil] waitUntilDone:false];
            [self errorWithMessage:@"Critical error. Job canceled."];
            [self.engine removeJob:[job objectForKey:@"id"]];
            break;
    }

    // Drain
    if ([self.engine fetchJobCount] == 0) {
        [self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:PPQueueDidDrain, @"name", nil, @"data", nil] waitUntilDone:false];
    } else {
        dispatch_async(_jobProcessingQueue, ^{
            [self tick];
        });
    }
}

/**
* Posts a notification (used to keep notifications on the main thread).
*
* @param {NSDictionary} Object
*                          - name: Notification name
*                          - data: Data to be attached to notification
*
* @return {void}
*/
- (void)postNotification:(NSDictionary *)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:[object objectForKey:@"name"] object:[object objectForKey:@"data"]];
}

/**
* Writes an error message to the log.
*
* @param {NSString} Message
*
* @return {void}
*/
- (void)errorWithMessage:(NSString *)message
{
    NSLog(@"PPQueue Error: %@", message);
}

@end
