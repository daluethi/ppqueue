//
//  PPQueueStorageEngine.h
//  ppqueue
//
//  Created by Daniel Luethi 2015
//  Copyright (c) 2015 All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;
@interface PPQueueStorageEngine : NSObject

@property (retain) FMDatabaseQueue *queue;

- (void)createJob:(id)data forTask:(id)task withPriority:(NSUInteger)priority;
- (BOOL)jobExistsForTask:(id)task;
- (void)incrementAttemptForJob:(NSNumber *)jid;
- (void)removeOldJobs:(NSString*)timeInterval;
- (void)removeJob:(NSNumber *)jid;
- (void)removeAllJobs;
- (NSUInteger)fetchJobCount;
- (NSDictionary *)fetchJob;
- (NSDictionary *)fetchJobForTask:(id)task;

@end