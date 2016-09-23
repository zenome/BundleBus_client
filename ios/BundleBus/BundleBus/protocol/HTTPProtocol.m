/**
 * Copyright (c) 2016-present ZENOME, Inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "HTTPProtocol.h"

@implementation HTTPProtocol
 
+ (NSMutableDictionary *)sendRequest:(NSURLRequest *)request {
    dispatch_semaphore_t    semaphore;
    __block NSMutableDictionary *result = nil;

    semaphore = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *res, NSError *error) {
                                         if (error) {
                                             result = [NSMutableDictionary dictionary];
                                             [result setObject:error forKey:@"error"];
                                             NSLog(@"%s : %@", __func__, error);
                                         }
                                         else {
                                             result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                         }
                                         
                                         if ([[[(NSHTTPURLResponse*)res allHeaderFields] valueForKey:@"content-type"] isEqualToString:@"application/octet-stream"]) {
                                             NSLog(@"http protocol response content-type : application/octet-stream");
                                             result = [NSMutableDictionary dictionary];
                                             [result setObject:data forKey:@"data"];
                                         }
                                         else {
                                             NSLog(@"http protocol response data : %@", result);
                                         }
                                         
                                         dispatch_semaphore_signal(semaphore);
                                     }] resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return result;  
}

@end
