/*
Copyright 2022 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

#import <React/RCTConvert.h>
#import "RCTAEPCore.h"
@import AEPCore;
#import "RCTAEPCoreDataBridge.h"

@implementation RCTAEPCore

RCT_EXPORT_MODULE(AEPCore);

static NSString* const EXTENSION_NAME = @"AEPCore";
static NSString* const FAILED_TO_CONVERT_EVENT_MESSAGE = @"Failed to convert dictionary to Event";

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (void) initialize {
    [super initialize];
    [AEPMobileCore setWrapperType:AEPWrapperTypeReactNative];
}

- (NSData *)dataFromHexString:(NSString *)string {
    NSMutableData *result = [[NSMutableData alloc] init];

    for (int i = 0; i + 2 <= string.length; i += 2) {
        NSRange range = NSMakeRange(i, 2);
        NSString* hexStr = [string substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        unsigned char uc = (unsigned char) intValue;
        [result appendBytes:&uc length:1];
    }

    return [NSData dataWithData:result];
}

RCT_EXPORT_METHOD(extensionVersion: (RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock)reject) {
    resolve([AEPMobileCore extensionVersion]);
}

RCT_EXPORT_METHOD(configureWithAppId:(NSString* __nullable) appId) {
    [AEPMobileCore configureWithAppId:appId];
}

RCT_EXPORT_METHOD(updateConfiguration: (NSDictionary* __nullable) config) {
    [AEPMobileCore updateConfiguration:config];
}

RCT_EXPORT_METHOD(clearUpdatedConfiguration) {
     [AEPMobileCore clearUpdatedConfiguration];
}

RCT_EXPORT_METHOD(setLogLevel: (NSString *) logLevelString) {
    [AEPMobileCore setLogLevel:[RCTAEPCoreDataBridge logLevelFromString:logLevelString]];
}

RCT_EXPORT_METHOD(getLogLevel: (RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *logLevelString = [RCTAEPCoreDataBridge stringFromLogLevel:[AEPLog logFilter]];
    resolve(logLevelString);
}

RCT_EXPORT_METHOD(getPrivacyStatus: (RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock)reject) {
    [AEPMobileCore getPrivacyStatus:^(enum AEPPrivacyStatus status) {
        resolve([RCTAEPCoreDataBridge stringFromPrivacyStatus:status]);
    }];
}

RCT_EXPORT_METHOD(setPrivacyStatus: (NSString *) statusString) {
    [AEPMobileCore setPrivacyStatus:[RCTAEPCoreDataBridge privacyStatusFromString:statusString]];
}

RCT_EXPORT_METHOD(getSdkIdentities: (RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock)reject) {
    [AEPMobileCore getSdkIdentities:^(NSString * _Nullable content, NSError * _Nullable error) {
        if (error) {
            [self handleError:error rejecter:reject errorLocation:@"getSdkIdentities"];
        } else {
            resolve(content);
        }
    }];
}

RCT_EXPORT_METHOD(setAppGroup: (nullable NSString*) appGroup) {
    [AEPMobileCore setAppGroup:appGroup];
}

#pragma mark - Generic methods

RCT_EXPORT_METHOD(collectPii: (nonnull NSDictionary*) data) {
    [AEPMobileCore collectPii:[RCTAEPCoreDataBridge sanitizeDictionaryToContainClass:[NSString class] WithDictionary:data]];
}

RCT_EXPORT_METHOD(setAdvertisingIdentifier: (nullable NSString*) adId) {
    [AEPMobileCore setAdvertisingIdentifier:adId];
}

RCT_EXPORT_METHOD(setPushIdentifier: (nullable NSString*) deviceToken) {
    [AEPMobileCore setPushIdentifier:[self dataFromHexString:deviceToken]];
}

RCT_EXPORT_METHOD(trackAction: (nullable NSString*) action data: (nullable NSDictionary*) data) {
    [AEPMobileCore trackAction:action data:data];
}

RCT_EXPORT_METHOD(trackState: (nullable NSString*) state data: (nullable NSDictionary*) data) {
    [AEPMobileCore trackState:state data:data];
}

RCT_EXPORT_METHOD(dispatchEvent: (nonnull NSDictionary*) eventDict resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
     AEPEvent *event = [RCTAEPCoreDataBridge eventFromDictionary:eventDict];
     if (!event) {
         reject(EXTENSION_NAME, FAILED_TO_CONVERT_EVENT_MESSAGE, nil);
         return;
     }
     [AEPMobileCore dispatch:event];
 }

RCT_EXPORT_METHOD(dispatchEventWithResponseCallback: (nonnull NSDictionary*) requestEventDict timeoutDuration:(nonnull NSNumber*) timeoutNumber resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    
    AEPEvent *requestEvent = [RCTAEPCoreDataBridge eventFromDictionary:requestEventDict];
    if (!requestEvent) {
        reject(EXTENSION_NAME, FAILED_TO_CONVERT_EVENT_MESSAGE, nil);
        return;
    }
    
    if (![timeoutNumber respondsToSelector:@selector(intValue)]) {
            reject(EXTENSION_NAME, @"Invalid timeout value", nil);
           return;
    }
    
    double timeout = [timeoutNumber intValue] / 1000.0;

    [AEPMobileCore dispatch:requestEvent timeout:timeout responseCallback:^(AEPEvent * _Nullable responseEvent) {
         if (responseEvent == nil) {
             reject(EXTENSION_NAME, @"general.callback.timeout", nil);
         } else {
             resolve([RCTAEPCoreDataBridge dictionaryFromEvent:responseEvent]);
         }
        
    }];
}

RCT_EXPORT_METHOD(setSmallIconResourceID: (NSInteger) resourceID) {
    [AEPLog debugWithLabel:EXTENSION_NAME message:@"setSm`allIconResourceID is not suppported on iOS"];
}

RCT_EXPORT_METHOD(setLargeIconResourceID: (NSInteger) resourceID) {
    [AEPLog debugWithLabel:EXTENSION_NAME message:@"setSmallIconResourceID is not suppported on iOS"];
}


RCT_EXPORT_METHOD(resetIdentities) {
     [AEPMobileCore resetIdentities];
}

#pragma mark - Helper methods

- (void) handleError:(NSError *) error rejecter:(RCTPromiseRejectBlock) reject {
    if (!error || !reject) {
        return;
    }

    NSDictionary *userInfo = [error userInfo];
    NSString *errorString = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];

    reject([NSString stringWithFormat: @"%lu", (long)error.code],
           errorString,
           error);
}

- (void) handleError:(NSError *) error rejecter:(RCTPromiseRejectBlock) reject errorLocation:(NSString *) location {
    NSString *errorTimeOut = [NSString stringWithFormat:@"%@ call timed out", location];
    NSString *errorUnexpected = [NSString stringWithFormat:@"%@ call returned an unexpected error", location];

    if (!error || !reject) {
        return;
    }

    if (error && error.code != AEPErrorNone) {
        if (error.code == AEPErrorCallbackTimeout) {
        reject(EXTENSION_NAME, errorTimeOut, error);
        }
    } else {
        reject(EXTENSION_NAME, errorUnexpected, error);
    }

}

@end
