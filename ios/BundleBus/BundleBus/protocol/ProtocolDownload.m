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

#import "ProtocolDownload.h"
#import "HTTPProtocol.h"
#import "BConfig.h"

@implementation ProtocolDownload
 
+ (NSMutableDictionary *)reqDownload:(NSString *)paramAppkey downloadKey:(NSString *)paramDownloadKey url:(NSString *)paramUrl {
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:
                                       [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                                             [BConfig serverURL],
                                                             paramUrl]]];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPMethod:@"POST"];
    NSString* body = @"{"
                      @"\"appkey\"     : \"%@\","
                      @"\"key\"         : \"%@\"}";
    body = [NSString stringWithFormat:body, paramAppkey, paramDownloadKey];
    NSLog(@"ProtocolDownload request body\n%@", body);
    
    [urlRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [HTTPProtocol sendRequest:urlRequest];
}

@end