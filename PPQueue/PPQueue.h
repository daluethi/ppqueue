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

#pragma mark Singleton
///----------------
/// @name Singleton
///----------------

/**
* Returns the shared instance of the receiver class, creating it if necessary.
*
* You shoudn't override this method in your subclasses.
* @return Shared instance of the receiver class.
*/
+ (PPQueue *)sharedInstance;

#pragma mark Properties
///----------------
/// @name Properties
///----------------

/**
* Lets you set a delegate which is called
*/
@property (nonatomic, weak) id<PPQueueDelegate> delegate;

/**
* Number of times a failed job should be retried
*/
@property (nonatomic, readonly) BOOL isRunning;

/**
* Number of times a failed job should be retried
*/
@property (nonatomic) NSUInteger retryLimit;

#pragma mark Methods
///----------------
/// @name Methods
///----------------

/**
* Adds a new job to the queue with priority 0
*
* @param {id} Data
* @param {NSString} Task label
*
* @return {void}
*/
- (void)enqueueWithData:(id)data forTask:(NSString *)task;

/**
* Adds a new job to the queue.
*
* @param {id} Data
* @param {NSString} Task label
* @param {NSUInteger} Priority of job. 0 = highest priority
*
* @return {void}
*/
- (void)enqueueWithData:(id)data forTask:(NSString *)task withPriority:(NSUInteger)priority;

/**
* Starts the queue.
*
* @return {void}
*/
- (void)start;

/**
* Stops the queue.
* @note Jobs that have already started will continue to process even after stop has been called.
*
* @return {void}
*/
- (void)stop;

/**
* Empties the queue.
* @note Jobs that have already started will continue to process even after empty has been called.
*
* @return {void}
*/
- (void)empty;

/**
* Removes all jobs older than the time interval.
*
* @param {NSString} a sqlite time interval (e.g '-1 day' or '-3 months')
*
* @return {void}
*/
- (void)removeOldJobs:(NSString*)timeInterval;

/**
* Returns true if a job exists for this task.
*
* @param {NSString} Task label
*
* @return {Boolean}
*/
- (BOOL)jobExistsForTask:(NSString *)task;

/**
* Returns true if the active job if for this task.
*
* @param {NSString} Task label
*
* @return {Boolean}
*/
- (BOOL)jobIsActiveForTask:(NSString *)task;

/**
* Returns the list of jobs for this
*
* @param {NSString} Task label
*
* @return {NSArray}
*/
- (NSDictionary *)nextJobForTask:(NSString *)task;

@end

/**
* The PPQueueDelegate protocol defines methods that are called to process a job
*/
@protocol PPQueueDelegate <NSObject>

@optional

/**
* Processes a job
*
* @param {PPQueue} the queue
*
* @param {NSDictionary} a dictionary with the job infos
*
* @return returns if the job successed of failed
*/
- (PPQueueResult)queue:(PPQueue *)queue processJob:(NSDictionary *)job;

/**
* Processes a job with a completion block for asynchronous processing
*
* @param {PPQueue} the queue
*
* @param {NSDictionary} a dictionary with the job infos
*
* @param {PPQueueCompletionBlock} a block to pass the result of the job
*/
- (void)queue:(PPQueue *)queue processJob:(NSDictionary *)job completion:(PPQueueCompletionBlock)block;
@end
