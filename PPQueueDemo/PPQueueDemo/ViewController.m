//
//  ViewController.m
//  PPQueueDemo
//
//  Created by Daniel Luethi 2015
//
//

#import "ViewController.h"
#import "PPQueue.h"

@interface ViewController () <PPQueueDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSDictionary *data1 = @{ @"key": @"data1", @"value": @(1)};
    NSDictionary *data2 = @{ @"key": @"data2", @"value": @(2)};
    NSDictionary *data3 = @{ @"key": @"data3", @"value": @(3)};

    [PPQueue sharedInstance].delegate = self;
    [PPQueue sharedInstance].retryLimit = 3;

    [[PPQueue sharedInstance] enqueueWithData:data1 forTask:@"myTask" withPriority:2];
    [[PPQueue sharedInstance] enqueueWithData:data2 forTask:@"myFailingTask" withPriority:2];
    [[PPQueue sharedInstance] enqueueWithData:data3 forTask:@"myHighPrioTask" withPriority:1];

    [[PPQueue sharedInstance] start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark PPQueueDelegate

- (void)queue:(PPQueue *)queue processJob:(NSDictionary *)job completion:(PPQueueCompletionBlock)result {

    // demonstrate a failing task (eg. send some data to server fails
    if ([@"myFailingTask" isEqualToString:job[@"task"]]) {
        NSLog(@"myFailingTask: %@", job[@"data"]);

        // Process your data
        // ...

        result(PPQueueResultFail);

        //Optionally stop the queue processing and then restart it when network connection is ok
        //[[PPQueue sharedInstance] stop];
    }
    else {
        NSLog(@"%@: %@", job[@"task"], job[@"data"]);

        // Process your data
        // ...

        result(PPQueueResultSuccess);
    }
}

@end
