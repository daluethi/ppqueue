//
//  PPQueue.h --> a fork from EDQueue
//  ppqueue
//
//  Created by Daniel Luethi 2015
//  Copyright (c) 2015 All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PPQueueResult) {
    PPQueueResultSuccess = 0,
    PPQueueResultFail,
    PPQueueResultCritical
};

typedef void (^PPQueueCompletionBlock)(PPQueueResult result);

extern NSString *const PPQueueDidStart;
extern NSString *const PPQueueDidStop;
extern NSString *const PPQueueJobDidSucceed;
extern NSString *const PPQueueJobDidFail;
extern NSString *const PPQueueDidDrain;

@protocol PPQueueDelegate;
@interface PPQueue : NSObject

+ (PPQueue *)sharedInstance;

@property (nonatomic, weak) id<PPQueueDelegate> delegate;

@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic) NSUInteger retryLimit;

- (void)enqueueWithData:(id)data forTask:(NSString *)task;
- (void)enqueueWithData:(id)data forTask:(NSString *)task withPriority:(NSUInteger)priority;
- (void)start;
- (void)stop;
- (void)empty;

- (void)removeOldJobs:(NSString*)timeInterval;
- (BOOL)jobExistsForTask:(NSString *)task;
- (BOOL)jobIsActiveForTask:(NSString *)task;
- (NSDictionary *)nextJobForTask:(NSString *)task;

@end

@protocol PPQueueDelegate <NSObject>
@optional
- (PPQueueResult)queue:(PPQueue *)queue processJob:(NSDictionary *)job;
- (void)queue:(PPQueue *)queue processJob:(NSDictionary *)job completion:(PPQueueCompletionBlock)block;
@end
