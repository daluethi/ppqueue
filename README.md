## PPQueue
#### A priorized persistent background job queue for iOS (a fork from PPQueue).

While `NSOperation` and `NSOperationQueue` work well for some repetitive problems and `NSInvocation` for others, iOS doesn't really include a set of tools for managing large collections of arbitrary background tasks easily. **PPQueue provides a high-level interface for implementing a threaded job queue using [GCD](http://developer.apple.com/library/ios/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) and [SQLLite3](http://www.sqlite.org/). All you need to do is handle the jobs within the provided delegate method and PPQueue handles the rest.**

### Getting Started
The easiest way to get going with PPQueue is to take a look at the included example application. The XCode project file can be found in `PPQueueDemo > PPQueueDemo.xcodeproj`.

### Setup
PPQueue needs both `libsqlite3.0.dylib` and [FMDB](https://github.com/ccgus/fmdb) for the storage engine. As always, the quickest way to take care of all those details is to use [CocoaPods](http://cocoapods.org/). PPQueue is implemented as a singleton as to allow jobs to be created from anywhere throughout an application. However, tasks are all processed through a single delegate method and thus it often makes the most sense to setup PPQueue within the application delegate:

YourAppDelegate.h
```objective-c
#import "PPQueue.h"
```
```objective-c
@interface YourAppDelegate : UIResponder <UIApplicationDelegate, PPQueueDelegate>
```

YourAppDelegate.m
```objective-c
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [PPQueue sharedInstance].delegate = self;
    [PPQueue sharedInstance].retryLimit = 3; // or what ever you need
    [[PPQueue sharedInstance] start];

}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[PPQueue sharedInstance] stop];
}

- (PPQueueResult)queue:(PPQueue *)queue processJob:(NSDictionary *)job
{
    // demonstrate a failing task (eg. sending some data to server fails
    if ([@"myFailingTask" isEqualToString:job[@"task"]]) {
        NSLog(@"myFailingTask: %@", job[@"data"]);

        // Process your data
        // ...

        //Optionally stop the queue processing and then restart it when network connection is ok
        //[[PPQueue sharedInstance] stop];
        return PPQueueResultFail;

    }
    else {
        NSLog(@"%@: %@", job[@"task"], job[@"data"]);

        // Process your data
        // ...

    }
    return PPQueueResultSuccess;
}
```

SomewhereElse.m
```objective-c
    NSDictionary *data1 = @{ @"key": @"data1", @"value": @(1)};
    NSDictionary *data2 = @{ @"key": @"data2", @"value": @(2)};
    NSDictionary *data3 = @{ @"key": @"data3", @"value": @(3)};

	// enqueue some data
    [[PPQueue sharedInstance] enqueueWithData:data1 forTask:@"myTask" withPriority:2];
    [[PPQueue sharedInstance] enqueueWithData:data2 forTask:@"myFailingTask" withPriority:2];
    [[PPQueue sharedInstance] enqueueWithData:data3 forTask:@"myHighPrioTask" withPriority:1];
```

In order to keep things simple, the delegate method expects a return type of `PPQueueResult` which permits three distinct states:
- `PPQueueResultSuccess`: Used to indicate that a job has completed successfully
- `PPQueueResultFail`: Used to indicate that a job has failed and should be retried (up to the specified `retryLimit`)
- `PPQueueResultCritical`: Used to indicate that a job has failed critically and should not be attempted again

### Handling Async Jobs
PPQueue includes a delegate method suited for handling asyncronous jobs such as HTTP requests or Disk I/O:

```objective-c
- (void)queue:(PPQueue *)queue processJob:(NSDictionary *)job completion:(void (^)(PPQueueResult))block
{
    @try {
        if ([[job objectForKey:@"task"] isEqualToString:@"success"]) {
            block(PPQueueResultSuccess);
        } else if ([[job objectForKey:@"task"] isEqualToString:@"fail"]) {
            block(PPQueueResultFail);
        } else {
            block(PPQueueResultCritical);
        }
    }
    @catch (NSException *exception) {
        block(PPQueueResultCritical);
    }
}
```

### Introspection
PPQueue includes a collection of methods to aid in queue introspection specific to each task:
```objective-c
- (Boolean)jobExistsForTask:(NSString *)task;
- (Boolean)jobIsActiveForTask:(NSString *)task;
- (NSDictionary *)nextJobForTask:(NSString *)task;
```

---

### Methods
```objective-c
- (void)enqueueWithData:(id)data forTask:(NSString *)task;
- (void)enqueueWithData:(id)data forTask:(NSString *)task withPriority:(NSUInteger)priority;

- (void)start;
- (void)stop;
- (void)empty;

- (Boolean)jobExistsForTask:(NSString *)task;
- (Boolean)jobIsActiveForTask:(NSString *)task;
- (NSDictionary *)nextJobForTask:(NSString *)task;
/**
* Removes all jobs older than the time interval.
*
* @param {NSString} a sqlite time interval (e.g '-1 day' or '-3 months')
*
* @return {void}
*/
- (void)removeOldJobs:(NSString*)timeInterval;
```

### Delegate Methods
```objective-c
- (PPQueueResult)queue:(PPQueue *)queue processJob:(NSDictionary *)job;
- (void)queue:(PPQueue *)queue processJob:(NSDictionary *)job completion:(void (^)(PPQueueResult result))block;
```

### Result Types
```objective-c
PPQueueResultSuccess
PPQueueResultFail
PPQueueResultCritical
```

### Properties
```objective-c
@property (weak) id<PPQueueDelegate> delegate;
@property (readonly) Boolean isRunning;
@property (readonly) Boolean isActive;
@property NSUInteger retryLimit;
```

### Notifications
```objective-c
PPQueueDidStart
PPQueueDidStop
PPQueueDidDrain
PPQueueJobDidSucceed
PPQueueJobDidFail
```

---

### iOS Support
PPQueue is designed for iOS 5 and up.

### ARC
PPQueue is built using ARC. If you are including PPQueue in a project that **does not** use [Automatic Reference Counting (ARC)](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html), you will need to set the `-fobjc-arc` compiler flag on all of the PPQueue source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all PPQueue source files, press Enter, insert `-fobjc-arc` and then "Done" to enable ARC for PPQueue.

