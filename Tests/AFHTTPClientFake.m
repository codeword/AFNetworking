#import "AFHTTPClientFake.h"

@interface AFHTTPClientFake ()
@property (strong, nonatomic) NSMutableArray *httpOperations;
@property (strong, nonatomic) AFHTTPClient *real;
@end

@implementation AFHTTPClientFake
- (id)init
{
    self = [super init];
    if (self) {
        self.real = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.example.com/"]];
        self.real.parameterEncoding = AFJSONParameterEncoding;
        [self.real registerHTTPOperationClass:[AFJSONRequestOperation class]];
        self.httpOperations = [NSMutableArray array];
    }
    return self;
}

#pragma mark - AFHTTPClientish implementations
- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation
{
    [self.httpOperations insertObject:operation atIndex:0];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters {
    return [self.real requestWithMethod:method path:path parameters:parameters];
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    return [self.real HTTPRequestOperationWithRequest:urlRequest success:success failure:failure];
}


#pragma mark - Fakes helper methods
- (NSUInteger)pendingRequestCount {
    return self.httpOperations.count;
}

- (void)invokeLastSuccessBlockWithResponse:(NSString *)responseString {
    NSAssert(self.pendingRequestCount, @"%@: cannot be called while there are no queued requests", NSStringFromSelector(_cmd));

    NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    AFHTTPRequestOperation *operation = [self.httpOperations lastObject];
    [self.httpOperations removeLastObject];
    NSURLResponse *response = nil;
    response = [[NSURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://example.com/foo.bar"]
                                         MIMEType:@"application/json"
                            expectedContentLength:0
                                 textEncodingName:@"application/json"];
    [operation connection:nil didReceiveResponse:response];
    [operation connection:nil didReceiveData:responseData];
    //You must override the AFOperation class to return YES for isFinished to have this work correctly
    //[operation start];
    [operation connectionDidFinishLoading:nil];
    void (^completionBlock)(void) = [operation completionBlock];
    NSAssert(completionBlock, @"Completion block was nil! It's a bad operation");
    completionBlock();
}

- (void)invokeLastFailureBlockWithError:(NSError *)error {
    NSAssert(self.pendingRequestCount, @"%@: cannot be called while there are no queued requests", NSStringFromSelector(_cmd));
    AFHTTPRequestOperation *operation = [self.httpOperations lastObject];
    [self.httpOperations removeLastObject];
    [operation connection:nil didFailWithError:error];
    void (^completionBlock)(void) = [operation completionBlock];
    NSAssert(completionBlock, @"Completion block was nil! It's a bad operation");
    completionBlock();
}

- (NSURLRequest *)lastRequest {
    NSAssert(self.pendingRequestCount, @"%@: cannot be called while there are no queued requests", NSStringFromSelector(_cmd));
    AFHTTPRequestOperation *operation = [self.httpOperations lastObject];
    return operation.request;
}

- (NSString *)lastURLString {
    return [[[self lastRequest] URL] relativePath];
}

- (NSString *)lastRequestBody {
    NSURLRequest *request = [self lastRequest];
    NSString *HTTPBodyString = nil;
    if (request) {
        HTTPBodyString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    }
    return HTTPBodyString;
}
@end
