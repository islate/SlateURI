//
//  SlateURI.h
//  SlateCore
//
//  Created by linyize on 14/12/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SlateURIHandler <NSObject>
@required
- (NSString *)scheme;
- (void)unknownURI:(NSURL *)uri;
- (void)unknownCommand:(NSString *)command params:(NSString *)params paramsArray:(NSArray *)paramsArray;

@end

@interface SlateURI : NSObject

+ (void)registerURIHandler:(id<SlateURIHandler>)handler;
+ (id<SlateURIHandler>)handler;
+ (BOOL)canOpenURI:(NSURL *)uri;
+ (void)openURI:(NSURL *)uri;

@end
