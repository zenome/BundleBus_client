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

#import "BundleBus.h"
#import "BUpdater.h"
#import "BBundle.h"
#import "BResource.h"
#import "BStorage.h"

@implementation BundleBus
@synthesize updater;

- (id)init
{
    self = [super init];
    
    self.updater  = [[BUpdater alloc] init];
    
    return self;
}

#pragma mark - Public
- (void)silentUpdate:(NSString *)paramAppkey {
    [self.updater silentUpdate:paramAppkey];
}

- (NSURL *)bundleUrl:(NSString *)paramAppKey {
    return [NSURL URLWithString:[self.updater getBundlePath:paramAppKey]];
}

- (void)configServerAddressAndPort:(NSString *)paramAddress port:(NSInteger)paramPort {
    [self.updater configServerAddressAndPort:paramAddress port:paramPort];
}

- (void)configPublishType:(NSString *)paramType {
    [self.updater configPublishType:paramType];
}

#pragma mark - RCT_EXPORT_MODULE
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(init:(NSString*)paramAppKey
                  version:(NSString*)paramVersion)
{
    NSLog(@"%s", __func__);
}

RCT_EXPORT_METHOD(checkUpdate:(NSString*)paramAppKey
                  success:(RCTResponseSenderBlock)success
                  fail:(RCTResponseSenderBlock)fail)
{
    NSLog(@"%s", __func__);
    success(@[]);
}

RCT_EXPORT_METHOD(update:(NSString*)paramAppKey
                  success:(RCTResponseSenderBlock)success
                  fail:(RCTResponseSenderBlock)fail)
{
    NSLog(@"%s", __func__);
    success(@[]);
}

RCT_EXPORT_METHOD(silentUpdate:(NSString*)paramAppKey
                  success:(RCTResponseSenderBlock)success
                  fail:(RCTResponseSenderBlock)fail)
{
    NSLog(@"%s", __func__);
    success(@[]);
}

@end
