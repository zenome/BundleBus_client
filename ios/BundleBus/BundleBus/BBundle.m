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

#import "BBundle.h"
#import "typedef.h"
#import "BStorage.h"
#import "ProtocolUpdate.h"
#import "ProtocolDownload.h"
#import "NSData+IDZGunzip.h"
#import "NSFileManager+Tar.h"
#import "BConfig.h"
#import "DiffMatchPatch.h"

@import Compression;

@implementation BBundle
#pragma mark - Lifecycle
- (id)init
{
    self = [super init];
    
    return self;
}

#pragma mark - Public
- (UpdateResponse)update:(NSString *)paramAppkey storage:(BStorage*)paramStorage {
    UpdateResponse response = bbError;
    
    NSMutableArray* arraybundle = [paramStorage getBundleinfoByAppKey:paramAppkey];
    //NSLog(@"%@", arraybundle);
    
    NSLog(@"---Location ----------------------------------------------------------------");
    NSLog(@"  %@", [BConfig getBasePath]);
    NSLog(@"----------------------------------------------------------------------------");
    
    if([arraybundle count] == 0) {
        NSLog(@"No bundleinfo. Requesting latest version info....");
        
        response = [self updateLatestVersion:paramAppkey
                                  appVersion:@"0.0"
                                   timestamp:@"0"
                                     storage:paramStorage];
    }
    else {
        NSLog(@"Found bundleinfo. Requesting latest version info....");
        NSMutableDictionary *bundleinfo = [arraybundle objectAtIndex:0];
        response = [self updateLatestVersion:paramAppkey
                                  appVersion:[bundleinfo objectForKey:@"appversion"]
                                   timestamp:[bundleinfo objectForKey:@"timestamp"]
                                     storage:paramStorage];
    }
    
    return response;
}

#pragma mark - Private
- (UpdateResponse)updateLatestVersion:(NSString *)paramAppkey appVersion:(NSString *)paramAppversion timestamp:(NSString *)paramTimestamp storage:(BStorage*)paramStorage {
    UpdateResponse response = bbError;
    
    NSMutableDictionary* data_update = [ProtocolUpdate reqUpdate:paramAppkey appVersion:paramAppversion timestamp:paramTimestamp];

    if([data_update objectForKey:@"errro"] != nil) {
        NSLog(@"GET %@ got error.", BUNDLEBUS_BACKEND_API_UPDATE);
    }
    else {
        NSMutableDictionary* dic_info = [data_update objectForKey:@"result"];
        if([[dic_info objectForKey:@"action"] isEqualToString:@"noupdate"]) {
            response = bbUse;
        }
        else if([[dic_info objectForKey:@"action"] isEqualToString:@"download"]) {
            [self unbundle:paramAppkey dicInfo:dic_info storage:paramStorage];
            response = bbDownload;
        }
        else if([[dic_info objectForKey:@"action"] isEqualToString:@"patch"]) {
            [self unbundle:paramAppkey dicInfo:dic_info storage:paramStorage];
            response = bbDownload;
        }
        else {
            NSAssert(true, @"unknown action type");
        }
    }
    
    return response;
}

- (NSError *)unbundle:(NSString *)paramAppkey dicInfo:(NSMutableDictionary *)paramDicInfo storage:(BStorage*)paramStorage {
    NSError *error = nil;
    
    // download
    NSMutableDictionary* data_download = [ProtocolDownload reqDownload:paramAppkey
                                                           downloadKey:[paramDicInfo objectForKey:@"key"]
                                                                   url:[paramDicInfo objectForKey:@"url"]];
    //NSLog(@"%@", data_download);
    
    /////////////////////////////////////////////////////////
    // unzip
    NSData* gunzippedData = [[data_download objectForKey:@"data"] gunzip:&error];
    if(!gunzippedData)
    {
        // Handle error
        NSAssert(false, @"failed to decompress the data.");
    }
    else
    {
        // Success use gunzippedData
        NSString *bundlepath = [[BConfig getBasePath] stringByAppendingPathComponent:paramAppkey];
        bundlepath = [bundlepath stringByAppendingPathComponent:@"tmp"];
        bundlepath = [bundlepath stringByAppendingPathComponent:[paramDicInfo objectForKey:@"action"]];
        bundlepath = [bundlepath stringByAppendingPathComponent:[paramDicInfo objectForKey:@"appversion"]];
        
        // create target folder
        [[NSFileManager defaultManager] createDirectoryAtPath:bundlepath withIntermediateDirectories:YES attributes:nil error:&error];
        
        NSLog(@"save bundle to %@", bundlepath);

        // untar
        [[NSFileManager defaultManager] createFilesAndDirectoriesAtPath:bundlepath withTarData:gunzippedData error:&error progress:nil];
        NSLog(@"untar complete!");
        
        // patch
        if([[paramDicInfo objectForKey:@"action"] isEqualToString:@"patch"]) {
            NSMutableArray* arraybundle = [paramStorage getBundleinfoByAppKey:paramAppkey];
            NSMutableDictionary *old_bundleinfo = [arraybundle objectAtIndex:0];
            
            NSString *oldpath = [[BConfig getBasePath] stringByAppendingPathComponent:paramAppkey];
            oldpath = [oldpath stringByAppendingPathComponent:@"tmp"];
            oldpath = [oldpath stringByAppendingPathComponent:@"download"];
            oldpath = [oldpath stringByAppendingPathComponent:[old_bundleinfo objectForKey:@"appversion"]];
            oldpath = [oldpath stringByAppendingPathComponent:[NSString stringWithFormat:@"build_%@",
                                                               [old_bundleinfo objectForKey:@"timestamp"]]];
            
            NSError *error = nil;
            BOOL bResult = FALSE;
            
            NSString *newpath = [[BConfig getBasePath] stringByAppendingPathComponent:paramAppkey];
            newpath = [newpath stringByAppendingPathComponent:@"tmp"];
            newpath = [newpath stringByAppendingPathComponent:@"download"];
            newpath = [newpath stringByAppendingPathComponent:[paramDicInfo objectForKey:@"appversion"]];
            
            error = nil;
            bResult = [[NSFileManager defaultManager] createDirectoryAtPath:newpath withIntermediateDirectories:YES attributes:nil error:&error];
            if(error) {
                NSLog(@"%@", error);
                //NSAssert(false, @"createDirectoryAtPath:newpath withIntermediateDirectories:YES attributes:nil error:&error];");
            }
            
            newpath = [newpath stringByAppendingPathComponent:[NSString stringWithFormat:@"build_%@",
                                                               [paramDicInfo objectForKey:@"tokey"]]];

            // new version directory
            error = nil;
            bResult = [[NSFileManager defaultManager] copyItemAtPath:oldpath toPath:newpath error:&error];
            if(error) {
                NSLog(@"%@", error);
                //NSAssert(false, @"copyItemAtPath:oldpath toPath:newpath error:&error];");
            }
            
            NSLog(@"-- patch --------------------------------------------------------------------------------------");
            NSString *patchFilePath = [bundlepath stringByAppendingPathComponent:[NSString stringWithFormat:@"patch-from-%@-to-%@", [paramDicInfo objectForKey:@"fromkey"], [paramDicInfo objectForKey:@"tokey"]]];
            patchFilePath = [patchFilePath stringByAppendingPathComponent:@"data.patch"];
            NSString *patchStr = [NSString stringWithContentsOfFile:patchFilePath encoding:NSUTF8StringEncoding error:nil];
            

            DiffMatchPatch *diffmatchpatch = [DiffMatchPatch new];
            
            
            NSString *oldFilePath = [newpath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle", [paramDicInfo objectForKey:@"fromkey"]]];
            NSMutableArray *patchData = [diffmatchpatch patch_fromText:patchStr error:nil];
            NSString *oldData = [NSString stringWithContentsOfFile:oldFilePath encoding:NSUTF8StringEncoding error:nil];
            NSString *patchResult = [[diffmatchpatch patch_apply:patchData toString:oldData] objectAtIndex:0];
            
            NSString *newFilePath = [newpath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle", [paramDicInfo objectForKey:@"tokey"]]];
            error = nil;
            [patchResult writeToFile:newFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            error = nil;
            bResult = [[NSFileManager defaultManager] removeItemAtPath:oldFilePath error:&error];
            if(error) {
                NSLog(@"%@", error);
                NSAssert(false, @"removeItemAtPath:oldFilePath error:&error];");
            }


            NSString *resourceJson = [bundlepath stringByAppendingPathComponent:[NSString stringWithFormat:@"patch-from-%@-to-%@", [paramDicInfo objectForKey:@"fromkey"], [paramDicInfo objectForKey:@"tokey"]]];
            resourceJson = [resourceJson stringByAppendingPathComponent:@"resources.json"];
            NSData *data = [NSData dataWithContentsOfFile:resourceJson];
            NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            
            NSLog(@"resource json : %@", json);
            for(int i=0; i<[json count]; i++) {
                NSMutableDictionary *d = [json objectAtIndex:i];
                if([[d objectForKey:@"state"] isEqualToString:@"add"]) {
                    NSString *itempath = [newpath stringByAppendingString:[d objectForKey:@"contenturi"]];
                    NSRange range = [itempath rangeOfString:@"/" options:NSBackwardsSearch];
                    itempath = [itempath substringToIndex:range.location];
                    NSLog(@"directory to make : %@", itempath);
                    NSError *error = nil;
                    [[NSFileManager defaultManager] createDirectoryAtPath:itempath withIntermediateDirectories:YES attributes:nil error:&error];
                    if(error) {
                        NSLog(@"%@", error);
                    }

                    // copy
                    NSString *patchResourcePath = [bundlepath stringByAppendingPathComponent:[NSString stringWithFormat:@"patch-from-%@-to-%@/build_%@",
                                                                                [paramDicInfo objectForKey:@"fromkey"],
                                                                                [paramDicInfo objectForKey:@"tokey"],
                                                                                [paramDicInfo objectForKey:@"tokey"]]];
                    patchResourcePath = [patchResourcePath stringByAppendingString:[d objectForKey:@"contenturi"]];
                    
                    error = nil;
                    itempath = [newpath stringByAppendingString:[d objectForKey:@"contenturi"]];
                    [[NSFileManager defaultManager] copyItemAtPath:patchResourcePath toPath:itempath error:&error];
                    if(error) {
                        NSLog(@"%@", error);
                    }
                    
                }
                else if([[d objectForKey:@"state"] isEqualToString:@"remove"]) {// unlink
                    NSString *itempath = [newpath stringByAppendingString:[d objectForKey:@"contenturi"]];
                    NSError *error = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:itempath error:&error];
                    if(error) {
                        NSLog(@"%@", error);
                    }
                }
                else {
                }
            }
            
            NSLog(@"patch done!");
            
            // next launch
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"needToInit"];
            [defaults setObject:paramAppkey forKey:@"appkey"];
            [defaults setObject:[NSString stringWithFormat:@"%@", [paramDicInfo objectForKey:@"appversion"]] forKey:@"appversion"];
            [defaults setObject:@"download" forKey:@"action"];
            [defaults setObject:[NSString stringWithFormat:@"%@", [paramDicInfo objectForKey:@"tokey"]] forKey:@"key"];
            [defaults synchronize];
        }
        else {
            // next launch
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"needToInit"];
            [defaults setObject:paramAppkey forKey:@"appkey"];
            [defaults setObject:[NSString stringWithFormat:@"%@", [paramDicInfo objectForKey:@"appversion"]] forKey:@"appversion"];
            [defaults setObject:@"download" forKey:@"action"];
            [defaults setObject:[NSString stringWithFormat:@"%@", [paramDicInfo objectForKey:@"key"]] forKey:@"key"];
            [defaults synchronize];
        }
        

    }
    /////////////////////////////////////////////////////////

    return error;
}

- (void)initLinkAndDatabase:(BStorage*)paramStorage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL bNeedToInit = [defaults objectForKey:@"needToInit"];
    if(bNeedToInit) {
        NSString *appkey = [defaults objectForKey:@"appkey"];
        NSString *appversion = [defaults objectForKey:@"appversion"];
        NSString *action = [defaults objectForKey:@"action"];
        NSString *key = [defaults objectForKey:@"key"];
        
        NSString *srcPath = [[BConfig getBasePath] stringByAppendingPathComponent:appkey];
        srcPath = [srcPath stringByAppendingPathComponent:@"bundle.link"];

        NSError *error = nil;
        NSDictionary *dicResult = [[NSFileManager defaultManager] attributesOfItemAtPath:srcPath error:&error];
        if(error == nil && [[dicResult objectForKey:@"NSFileType"]isEqualToString:NSFileTypeSymbolicLink]) {
            NSMutableArray* arraybundle = [paramStorage getBundleinfoByAppKey:appkey];
            NSMutableDictionary *old_bundleinfo = [arraybundle objectAtIndex:0];
            
            NSString *oldpath = [[BConfig getBasePath] stringByAppendingPathComponent:appkey];
            oldpath = [oldpath stringByAppendingPathComponent:@"tmp"];
            oldpath = [oldpath stringByAppendingPathComponent:@"download"];
            oldpath = [oldpath stringByAppendingPathComponent:[old_bundleinfo objectForKey:@"appversion"]];
            oldpath = [oldpath stringByAppendingPathComponent:[NSString stringWithFormat:@"build_%@",
            
                                                               [old_bundleinfo objectForKey:@"timestamp"]]];
            
            error = nil;
            BOOL bResult = [[NSFileManager defaultManager] removeItemAtPath:oldpath error:&error];
            if(error) {
                NSLog(@"%@", error);
                //NSAssert(false, @"failed to removeItemAtPath:dstResolved error:&error];");
            }
            
            error = nil;
            bResult = [[NSFileManager defaultManager] removeItemAtPath:srcPath error:&error];
            if(error) {
                NSLog(@"%@", error);
                //NSAssert(false, @"failed to removeItemAtPath:srcPath error:&error];");
            }
        }
        
        NSString *dstpath = [[BConfig getBasePath] stringByAppendingPathComponent:appkey];
        dstpath = [dstpath stringByAppendingPathComponent:@"tmp"];
        dstpath = [dstpath stringByAppendingPathComponent:action];
        dstpath = [dstpath stringByAppendingPathComponent:appversion];
        dstpath = [dstpath stringByAppendingPathComponent:[NSString stringWithFormat:@"build_%@", key]];
        dstpath = [dstpath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle", key]];
        
        NSLog(@"src path : %@", srcPath);
        NSLog(@"dst path : %@", dstpath);

        // symbolic link
        error = nil;
        BOOL bResult = [[NSFileManager defaultManager] createSymbolicLinkAtPath:srcPath withDestinationPath:dstpath error:&error];
        if(error) {
            NSLog(@"%@", error);
            //NSAssert(false, @"failed to createSymbolicLinkAtPath:srcPath withDestinationPath:dstpath error:&error];");
        }

        // database
        NSMutableArray* array_bundles = [paramStorage getBundleinfoByAppKey:appkey];
        NSLog(@"%@", array_bundles);
        if([array_bundles count] == 0) {    // insert
            [paramStorage insert:appkey
                         appPath:dstpath
                       timestamp:key
                         version:appversion];
        }
        else {    // update
            [paramStorage update:appkey version:appversion timestamp:key];
        }
        
        // defaults
        [defaults removeObjectForKey:@"needToInit"];
        [defaults removeObjectForKey:@"appkey"];
        [defaults removeObjectForKey:@"appversion"];
        [defaults removeObjectForKey:@"action"];
        [defaults removeObjectForKey:@"key"];
        [defaults synchronize];
    }
}

@end
