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



#import "BUpdater.h"
#import "BBundle.h"
#import "BResource.h"
#import "BStorage.h"
#import "BConfig.h"

#pragma mark - private
@interface BUpdater()
- (UpdateResponse)update:(NSString *)paramAppkey;
- (void)          updateAsync:(NSString *)paramAppkey
                      successblock:(void (^)(UpdateResponse type))success
                         failblock:(void (^)(UpdateResponseError error))fail;
@property (nonatomic, strong) BBundle *bundle;
@property (nonatomic, strong) BResource *resource;
@property (nonatomic, strong) BStorage *storage;
@property (nonatomic) BOOL bSetupLink;
@end


@implementation BUpdater
@synthesize bundle;
@synthesize resource;
@synthesize storage;
@synthesize bSetupLink;

#pragma mark - Public
- (void)silentUpdate:(NSString *)paramAppkey {
    NSLog(@"%s", __FUNCTION__);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [self update:paramAppkey];
    });
}

- (void)interactiveUpdate:(NSString *)paramAppkey {
    
}

- (NSString *)getBundlePath:(NSString *)paramAppkey {
    NSString *srcPath = [[BConfig getBasePath] stringByAppendingPathComponent:paramAppkey];
    srcPath = [srcPath stringByAppendingPathComponent:@"bundle.link"];
    
    NSMutableArray* array_bundles = [self.storage getBundleinfoByAppKey:paramAppkey];
    NSLog(@"%@", array_bundles);
    if([array_bundles count] == 0) {    // insert
        return nil;
    }
    else {    // update
        if(!bSetupLink) {
            NSMutableDictionary *bundleinfo = [array_bundles objectAtIndex:0];
            NSString *dstpath = [[BConfig getBasePath] stringByAppendingPathComponent:paramAppkey];
            dstpath = [dstpath stringByAppendingPathComponent:@"tmp"];
            dstpath = [dstpath stringByAppendingPathComponent:@"download"];
            dstpath = [dstpath stringByAppendingPathComponent:[bundleinfo objectForKey:@"appversion"]];
            
            dstpath = [dstpath stringByAppendingPathComponent:[NSString stringWithFormat:@"build_%@", [bundleinfo objectForKey:@"timestamp"]]];
            dstpath = [dstpath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle", [bundleinfo objectForKey:@"timestamp"]]];
            
            NSError *error = nil;
            BOOL bResult = [[NSFileManager defaultManager] removeItemAtPath:srcPath error:&error];
            if(error) {
                NSLog(@"%@", error);
                //NSAssert(false, @"failed to createSymbolicLinkAtPath:srcPath withDestinationPath:dstpath error:&error];");
            }
            
            error = nil;
            bResult = [[NSFileManager defaultManager] createSymbolicLinkAtPath:srcPath withDestinationPath:dstpath error:&error];
            if(error) {
                NSLog(@"%@", error);
                //NSAssert(false, @"failed to createSymbolicLinkAtPath:srcPath withDestinationPath:dstpath error:&error];");
            }
            
            bSetupLink = TRUE;
        }
        
        NSError *error = nil;
        NSString *strDst = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:srcPath error:&error];
        if([[NSFileManager defaultManager] fileExistsAtPath:strDst]) {
            return srcPath;
        }
        else {
            return nil;
        }
    }
}

- (NSDictionary *)getInitialProperty:(NSString *)paramAppkey {
    NSMutableDictionary* retDict = [[NSMutableDictionary alloc] init];
    return retDict;
}

- (void)configServerAddressAndPort:(NSString *)paramAddress port:(NSInteger)paramPort {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:paramAddress forKey:@"serverAddress"];
    [defaults setInteger:paramPort forKey:@"serverPort"];
    [defaults synchronize];
}


- (void)configPublishType:(NSString *)paramType {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:paramType forKey:@"publishType"];
    [defaults synchronize];
}

#pragma mark - Private
- (id)init
{
    self = [super init];
    
    self.storage  = [[BStorage alloc] init];
    self.bundle   = [[BBundle alloc] init];
    self.resource = [[BResource alloc] init];
    
    [self.bundle initLinkAndDatabase:self.storage];
    
    // check if database file is available.
    
    // check if tables are available.
    self.bSetupLink = FALSE;
    
    return self;
}

- (UpdateResponse)update:(NSString *)paramAppkey {
    UpdateResponse response = [self.bundle update:paramAppkey storage:self.storage];
    if (response == bbError) {
        NSLog(@"%s : error during update bundle", __FUNCTION__);
        return response;
    }
    
    /*
    // update resources
    response = [self.resource updateResources:paramAppkey];
    if (response == bbError) {
        NSLog(@"%s : error during update resources", __FUNCTION__);
        return response;
    }
     */
    
    return response;
}

- (void)updateAsync:(NSString *)paramAppkey
            successblock:(void (^)(UpdateResponse type))success
               failblock:(void (^)(UpdateResponseError error))fail {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        
        UpdateResponse response = [self update:paramAppkey];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            switch(response) {
                case bbUse :
                    success(bbUse);
                    break;
                case bbDownload :
                    success(bbDownload);
                    break;
                case bbUpdate :
                    success(bbUpdate);
                    break;
                default :
                    fail(bbError0);
            };
        });
    });
}

@end
