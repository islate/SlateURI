//
//  SlateURI.m
//  Slate
//
//  Created by yize lin on 16-6-16.
//  Copyright (c) 2016年 islate. All rights reserved.
//

#import "SlateURI.h"

#import "SlateUtils.h"

@interface SlateURI ()

@property (nonatomic, strong) NSMutableArray<id<SlateURIHandler>> *handlers;
@property (nonatomic, strong) NSString *scheme;

+ (instancetype)sharedURI;

- (void)addHandlers:(NSArray<id<SlateURIHandler>>*)handlers;
- (void)setPriorHandler:(id<SlateURIHandler>)handler;

- (id<SlateURIHandler>)handlerForCommandSelector:(SEL)commandSelector;
- (BOOL)canOpenURI:(NSURL *)uri;
- (void)openURI:(NSURL *)uri completion:(SlateURICompletionBlock)completion;
- (void)openURIInMainThread:(NSURL *)uri completion:(SlateURICompletionBlock)completion;
- (void)handleURICommand:(NSString *)command params:(NSString *)params paramsArray:(NSArray *)paramsArray completion:(SlateURICompletionBlock)completion;

@end

@implementation SlateURI

+ (instancetype)sharedURI
{
    static id _sharedInstance = nil;
    static dispatch_once_t  once = 0;
    
    dispatch_once(&once, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

+ (void)addHandlers:(NSArray<id<SlateURIHandler>>*)handlers
{
    [[SlateURI sharedURI] addHandlers:handlers];
}

+ (void)setPriorHandler:(id<SlateURIHandler>)handler
{
    [[SlateURI sharedURI] setPriorHandler:handler];
}

+ (void)setScheme:(NSString *)scheme
{
    [SlateURI sharedURI].scheme = scheme;
}

+ (BOOL)canOpenURI:(NSURL *)uri
{
    return [[SlateURI sharedURI] canOpenURI:uri];
}

+ (void)openURI:(NSURL *)uri
{
    [[SlateURI sharedURI] openURI:uri completion:nil];
}

+ (void)openURI:(NSURL *)uri location:(NSString *)location
{
    [[SlateURI sharedURI] openURI:uri completion:nil];
}

+ (void)openURI:(NSURL *)uri completion:(SlateURICompletionBlock)completion
{
    [[SlateURI sharedURI] openURI:uri completion:completion];
}

+ (void)handleURICommand:(NSString *)command params:(NSString *)params paramsArray:(NSArray *)paramsArray completion:(SlateURICompletionBlock)completion
{
    [[SlateURI sharedURI] handleURICommand:command params:params paramsArray:paramsArray completion:completion];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _handlers = [NSMutableArray new];
        _scheme = @"slate";
    }
    return self;
}

- (void)addHandlers:(NSArray<id<SlateURIHandler>>*)handlers
{
    [_handlers addObjectsFromArray:handlers];
}

- (void)setPriorHandler:(id<SlateURIHandler>)handler
{
    [_handlers insertObject:handler atIndex:0];
}

- (id<SlateURIHandler>)handlerForCommandSelector:(SEL)commandSelector
{
    for (id handler in _handlers)
    {
        if ([handler respondsToSelector:commandSelector])
        {
            return handler;
        }
    }
    return nil;
}

- (BOOL)canOpenURI:(NSURL *)url
{
    return [url.scheme.lowercaseString isEqualToString:_scheme];
}

// 例子:     url=@"slate://article/4/12/238/"
//          command=@"article"
//          params=@"/4/12/238"
- (void)openURI:(NSURL *)uri completion:(SlateURICompletionBlock)completion
{
    NSLog(@" --openURI-- %@ ", uri.absoluteString);

    if (uri == nil)
    {
        return;
    }
    
    if ([NSThread isMainThread])
    {
        [self openURIInMainThread:uri completion:completion];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self openURIInMainThread:uri completion:completion];
        });
    }
}

- (void)openURIInMainThread:(NSURL *)uri completion:(SlateURICompletionBlock)completion
{
    NSString *command = uri.host;
    NSUInteger from = [_scheme length] + command.length + 4;
    NSString *params = nil;
    if (uri.absoluteString.length > from)
    {
        params = [uri.absoluteString substringFromIndex:from];
    }
    
    NSMutableArray *paramsArray = [NSMutableArray arrayWithArray:[params componentsSeparatedByString:@"/"]];
    NSMutableArray *newParamsArray = [NSMutableArray new];
    for (NSString *param in paramsArray)
    {
        if (param.length > 0)
        {
            NSString *unescapedParam = [param stringUnescapedAsURIComponent];
            if (!unescapedParam)
            {
                unescapedParam = @"";
            }
            [newParamsArray addObject:unescapedParam];
        }
    }
    
    if (params.length > 0)
    {
        NSString *unescapedParams = [params stringUnescapedAsURIComponent];
        if (!unescapedParams)
        {
            unescapedParams = @"";
        }
        params = unescapedParams;
    }

    [self handleURICommand:command params:params paramsArray:newParamsArray completion:completion];
}

- (void)handleURICommand:(NSString *)command params:(NSString *)params paramsArray:(NSArray *)paramsArray completion:(SlateURICompletionBlock)completion
{
    NSString *commandSelectorString = [NSString stringWithFormat:@"%@Command:params:paramsArray:completion:",command];
    SEL commandSelector = NSSelectorFromString (commandSelectorString);
    
    id handler = [self handlerForCommandSelector:commandSelector];
    if (handler == nil)
    {
        NSLog(@"SlateURI doesn't know how to handle command: %@", command);
        
        if (completion)
        {
            NSError* error = nil;
            NSMutableDictionary* errorDetail = [[NSMutableDictionary alloc] init];
            [errorDetail setValue:@"no handler" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"SlateURIError" code:1000 userInfo:errorDetail];
            completion(nil, error);
        }
        return;
    }
    
    if ([handler respondsToSelector:@selector(willHandleCommand:params:paramsArray:)])
    {
        [handler willHandleCommand:command params:params paramsArray:paramsArray];
    }
    
    NSMethodSignature *signature = [[handler class] instanceMethodSignatureForSelector:commandSelector];
    NSInvocation *invocation = nil;
    
    if (signature)
    {
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation retainArguments];
        invocation.selector = commandSelector;
        invocation.target = handler;
        [invocation setArgument:&command atIndex:2];
        [invocation setArgument:&params atIndex:3];
        [invocation setArgument:&paramsArray atIndex:4];
        [invocation setArgument:&completion atIndex:5];
    }
    
    if (invocation && [handler respondsToSelector:commandSelector])
    {
        @try {
            [invocation invoke];
        }
        @catch(NSException *exception) {
            NSLog (@"NSInvocation exception on %@ %@", handler, commandSelectorString);
            NSLog (@"%@ %@", [exception name], [exception reason]);
            NSLog (@"%@", [[exception callStackSymbols] componentsJoinedByString:@"\n"]);
            
            if (completion)
            {
                NSError* error = nil;
                NSMutableDictionary* errorDetail = [[NSMutableDictionary alloc] init];
                [errorDetail setValue:@"throw exception" forKey:NSLocalizedDescriptionKey];
                error = [NSError errorWithDomain:@"SlateURIError" code:1001 userInfo:errorDetail];
                completion(nil, error);
            }
        }
    }
    
    if ([handler respondsToSelector:@selector(didHandleCommand:params:paramsArray:)])
    {
        [handler didHandleCommand:command params:params paramsArray:paramsArray];
    }
}

@end
