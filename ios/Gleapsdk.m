#import "Gleapsdk.h"

#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>

static NSString *const RCTShowDevMenuNotification = @"RCTShowDevMenuNotification";

#if !RCT_DEV

@implementation UIWindow (RNShakeEvent)

- (void)handleShakeEvent:(__unused UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeMotionShake) {
        [[NSNotificationCenter defaultCenter] postNotificationName: RCTShowDevMenuNotification object:nil];
    }
}

@end

#endif

@implementation Gleapsdk
{
    BOOL _hasListeners;
}

RCT_EXPORT_MODULE()

- (void)initSDK {
    Gleap.sharedInstance.delegate = self;
    [Gleap setApplicationType: REACTNATIVE];
}

RCT_EXPORT_METHOD(initialize:(NSString *)token)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initSDK];
        [Gleap setAutoActivationMethodsDisabled];
        [Gleap initializeWithToken: token];
    });
}

- (void)configLoaded:(NSDictionary *)config {
    // Hook up shake gesture recognizer.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(motionEnded:)
                                                     name: RCTShowDevMenuNotification
                                                object: nil];
    
    #if !RCT_DEV
        RCTSwapInstanceMethods([UIWindow class], @selector(motionEnded:withEvent:), @selector(handleShakeEvent:withEvent:));
    #endif

    // Add screenshot gesture recognizer
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification
                                                          object:nil
                                                           queue:mainQueue
                                                      usingBlock:^(NSNotification *note) {
        if ([[Gleap sharedInstance] isActivationMethodActive: SCREENSHOT]) {
            [Gleap startFeedbackFlow];
        }
    }];

    NSMutableArray *activationMethods = [[NSMutableArray alloc] init];
    if ([config objectForKey: @"activationMethodShake"] != nil && [[config objectForKey: @"activationMethodShake"] boolValue] == YES) {
        [activationMethods addObject: @(SHAKE)];
    }
    if ([config objectForKey: @"activationMethodScreenshotGesture"] != nil && [[config objectForKey: @"activationMethodScreenshotGesture"] boolValue] == YES) {
        [activationMethods addObject: @(SCREENSHOT)];
    }
    
    [[Gleap sharedInstance] setActivationMethods: activationMethods];
    
    if (_hasListeners) {
        [self sendEventWithName:@"configLoaded" body: config];
    }
}

- (void)motionEnded:(NSNotification *)notification
{
    if ([[Gleap sharedInstance] isActivationMethodActive: SHAKE]) {
        [Gleap startFeedbackFlow];
    }
}

- (void)feedbackWillBeSent {
    if (_hasListeners) {
        [self sendEventWithName:@"feedbackWillBeSent" body:@{}];
    }
}

- (void)feedbackSendingFailed {
    if (_hasListeners) {
        [self sendEventWithName:@"feedbackSendingFailed" body:@{}];
    }
}

- (void)feedbackSent:(NSDictionary *)data {
    if (_hasListeners) {
        [self sendEventWithName:@"feedbackSent" body: data];
    }
}

- (void)customActionCalled:(NSString *)customAction {
    if (_hasListeners) {
        [self sendEventWithName:@"customActionTriggered" body:@{
            @"name": customAction
        }];
    }
}

- (void)startObserving
{
  _hasListeners = YES;
}

- (void)stopObserving
{
  _hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"feedbackSent", @"feedbackWillBeSent", @"feedbackSendingFailed", @"configLoaded", @"customActionTriggered"];
}

RCT_EXPORT_METHOD(sendSilentBugReport:(NSString *)description andSeverity:(NSString *)priority)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        GleapBugSeverity prio = MEDIUM;
        if ([priority isEqualToString: @"LOW"]) {
            prio = LOW;
        }
        if ([priority isEqualToString: @"HIGH"]) {
            prio = HIGH;
        }
        [Gleap sendSilentBugReportWith: description andSeverity: prio];
    });
}

RCT_EXPORT_METHOD(attachNetworkLog:(NSArray *)networkLogs)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap attachData: @{ @"networkLogs": networkLogs }];
    });
}


RCT_EXPORT_METHOD(setActivationMethods:(NSArray *)activationMethods)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *internalActivationMethods = [[NSMutableArray alloc] init];
        for (int i = 0; i < activationMethods.count; i++) {
            if ([[activationMethods objectAtIndex: i] isEqualToString: @"SHAKE"]) {
                [internalActivationMethods addObject: @(SHAKE)];
            }
            if ([[activationMethods objectAtIndex: i] isEqualToString: @"SCREENSHOT"]) {
                [internalActivationMethods addObject: @(SCREENSHOT)];
            }
        }
        
        [Gleap setActivationMethods: internalActivationMethods];
    });
}

RCT_EXPORT_METHOD(startFeedbackFlow:(NSString *)feedbackFlow)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap startFeedbackFlow: feedbackFlow];
    });
}

RCT_EXPORT_METHOD(enableDebugConsoleLog)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap enableDebugConsoleLog];
    });
}

RCT_EXPORT_METHOD(open)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap open];
    });
}

RCT_EXPORT_METHOD(setLanguage:(NSString *)language)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap setLanguage: language];
    });
}

RCT_EXPORT_METHOD(clearIdentity)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap clearIdentity];
    });
}

RCT_EXPORT_METHOD(identify:(NSString *)userId withUserProperties: (NSDictionary *)userProperties)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        GleapUserProperty *userProperty = [[GleapUserProperty alloc] init];
        if (userProperties != nil && [userProperties objectForKey: @"name"] != nil) {
            userProperty.name = [userProperties objectForKey: @"name"];
        }
        if (userProperties != nil && [userProperties objectForKey: @"email"] != nil) {
            userProperty.email = [userProperties objectForKey: @"email"];
        }
        
        [Gleap identifyUserWith: userId andData: userProperty];
    });
}

RCT_EXPORT_METHOD(attachCustomData:(NSDictionary *)customData)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap attachCustomData: customData];
    });
}

RCT_EXPORT_METHOD(setCustomData:(NSString *)key andData:(NSString *)value)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap setCustomData: value forKey: key];
    });
}

RCT_EXPORT_METHOD(removeCustomDataForKey:(NSString *)key)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap removeCustomDataForKey: key];
    });
}

RCT_EXPORT_METHOD(clearCustomData)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap clearCustomData];
    });
}

RCT_EXPORT_METHOD(setApiUrl: (NSString *)apiUrl)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap setApiUrl: apiUrl];
    });
}

RCT_EXPORT_METHOD(setWidgetUrl: (NSString *)apiUrl)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap setWidgetUrl: apiUrl];
    });
}

RCT_EXPORT_METHOD(logEvent:(NSString *)name andData:(NSDictionary *)data)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap logEvent: name withData: data];
    });
}

RCT_EXPORT_METHOD(removeAllAttachments)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [Gleap removeAllAttachments];
    });
}

RCT_EXPORT_METHOD(addAttachment:(NSString *)base64file withFileName:(NSString *)fileName)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *dataParts = [base64file componentsSeparatedByString: @";base64,"];
        NSData *fileData = [[NSData alloc] initWithBase64EncodedString: [dataParts lastObject] options:0];
        if (fileData != nil) {
            [Gleap addAttachmentWithData: fileData andName: fileName];
        } else {
            NSLog(@"[Gleap]: Invalid base64 string passed.");
        }
    });
}

- (void)dealloc
{
    @try{
       [[NSNotificationCenter defaultCenter] removeObserver: self];
    } @catch(id anException) {}
}

@end

