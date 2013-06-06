#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface AFHTTPClientFake : NSObject<AFHTTPClient>

- (NSUInteger)pendingRequestCount;
- (void)invokeLastSuccessBlockWithResponse:(NSString *)responseString;
- (void)invokeLastFailureBlockWithError:(NSError *)error;
- (NSURLRequest *)lastRequest;
- (NSString *)lastURLString;
- (NSString *)lastRequestBody;

@end
