//
//  SlateURI.h
//  Slate
//
//  Created by yize lin on 16-6-16.
//  Copyright (c) 2016年 islate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^SlateURICompletionBlock)(id result, NSError *error);

@protocol SlateURIHandler <NSObject>
@optional
- (void)willHandleCommand:(NSString *)command params:(NSString *)params paramsArray:(NSArray *)paramsArray;
- (void)didHandleCommand:(NSString *)command params:(NSString *)params paramsArray:(NSArray *)paramsArray;

@end

/**
 *  URI抽象接口
 */
@interface SlateURI : NSObject

+ (void)addHandlers:(NSArray<id<SlateURIHandler>>*)handlers;
+ (void)setPriorHandler:(id<SlateURIHandler>)handler;

+ (void)setScheme:(NSString *)scheme;
+ (BOOL)canOpenURI:(NSURL *)uri;
+ (void)openURI:(NSURL *)uri;
+ (void)openURI:(NSURL *)uri location:(NSString *)location;
+ (void)openURI:(NSURL *)uri completion:(SlateURICompletionBlock)completion;
+ (void)handleURICommand:(NSString *)command params:(NSString *)params paramsArray:(NSArray *)paramsArray completion:(SlateURICompletionBlock)completion;

@end
