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

#import "BConfig.h"

#define BUNDLEBUS @"bundlebus"
@implementation BConfig

+ (NSString *)getBasePath {
    NSString *retString = [NSString stringWithFormat:@"%@/%@",
                           NSSearchPathForDirectoriesInDomains (NSCachesDirectory, NSUserDomainMask, YES)[0],
                           BUNDLEBUS];
    return retString;      
}

+ (NSString *)serverURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *serverAddress = [defaults objectForKey:@"serverAddress"];
    NSInteger serverPort = [[defaults objectForKey:@"serverPort"] integerValue];
    if(serverAddress) {
        serverAddress = [serverAddress stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        return [NSString stringWithFormat:@"http://%@:%ld", serverAddress, (long)serverPort];
    }
    else {
        return @"http://localhost:3000";
    }
}

+ (NSString *)publish {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *publishType = [defaults objectForKey:@"publishType"];
    if(publishType) {
        return publishType;
    }
    else {
        return @"deploy";
    }
}

@end
