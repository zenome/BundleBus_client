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

#import "BStorage.h"
#import <sqlite3.h>
#import "BConfig.h"

@interface BStorage()
@property (nonatomic) sqlite3 *db;
@end

@implementation BStorage

- (id)init
{
    self = [super init];
    
    [self createDatabase];
    
    [self createTables];
    
    return self;
}

- (void)createDatabase {
    sqlite3 *db = NULL;
    
    
    int rc = 0;
    
    NSString *dbPath = [self getDbFilePath];
    NSLog(@"Opening database connection...");
    rc = sqlite3_open_v2([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK != rc) {
        NSLog(@"%s", __func__);
        NSLog(@"  Failed to open db connection.");
        NSLog(@"  Result code:%d", rc);
    }
    else {
        self.db = db;
        NSLog(@"  succeeded.");
    }
}

- (NSString *)getDbFilePath {
    NSError * error = nil;
    NSString *strBasePath = [BConfig getBasePath];
    
    NSLog(@"Creating directory for database at %@ ...", strBasePath);
    [[NSFileManager defaultManager] createDirectoryAtPath:strBasePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    
    if(error) {
        NSLog(@"%s", __func__);
        NSLog(@"  failed:%@", error);
    }
    else {
        NSLog(@"  succeeded.");
    }
    
    return [NSString stringWithFormat:@"%@/bundlebus.db", strBasePath];
}


- (void)createTables {
    int rc = 0;

    NSLog(@"Creating table for applications...");
    char *query ="CREATE TABLE bundle ( id INTEGER PRIMARY KEY AUTOINCREMENT, appkey TEXT, apppath TEXT, timestamp TEXT, appversion TEXT )";
    char *errMsg;
    rc = sqlite3_exec(self.db, query, NULL, NULL, &errMsg);

    if(SQLITE_OK != rc) {
        NSLog(@"%s", __func__);
        NSLog(@"  Failed to create table bundle.");
        NSLog(@"  Result code:%d", rc);
        NSLog(@"  Message : %s", errMsg);
    }
    else {
        NSLog(@"  Succeeded to create tables.");
    }
}

#pragma mark - Public
- (NSArray *)getBundleinfoByAppKey:(NSString *)paramAppkey {
    NSMutableArray *bundleinfo =[[NSMutableArray alloc] init];
    sqlite3_stmt *stmt =NULL;
    int rc = 0;
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM bundle WHERE appkey=\"%@\" ORDER BY id DESC LIMIT 1", paramAppkey];
    rc = sqlite3_prepare_v2(self.db, [query UTF8String], -1, &stmt, NULL);
    if(rc == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSString *appkey    = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)];
            NSString *buildid   = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 2)];
            NSString *timestamp = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 3)];
            NSString *version   = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 4)];
            
            NSDictionary *bundle =[NSDictionary dictionaryWithObjectsAndKeys:
                                   appkey, @"appkey",
                                   buildid,@"apppath",
                                   timestamp,@"timestamp",
                                   version, @"appversion",nil];
            
            [bundleinfo addObject:bundle];
            NSLog(@"%s", __func__);
            NSLog(@" app info : %@, \n  buildid(installed path) : %@, \n  timestamp : %@, \n  appversion : %@", appkey, buildid, timestamp, version);
        }
        sqlite3_finalize(stmt);
    } else {
        NSLog(@"Failed to prepare statement with rc:%d", rc);
    }
    
    return bundleinfo;
}

- (BOOL)insert:(NSString *)paramAppKey appPath:(NSString *)paramAppPath timestamp:(NSString *)paramTimestamp version:(NSString *)paramVersion {
    int rc = 0;
    NSString * query  = [NSString stringWithFormat:@"INSERT INTO bundle (appkey,apppath,timestamp,appversion) VALUES (\"%@\",\"%@\",\"%@\",\"%@\")",
                         paramAppKey, paramAppPath, paramTimestamp, paramVersion];
    char * errMsg;
    rc = sqlite3_exec(self.db, [query UTF8String], NULL, NULL, &errMsg);
    if(SQLITE_OK != rc) {
        NSLog(@"Failed to insert record  rc:%d, msg=%s", rc, errMsg);
    }
    return (rc == SQLITE_OK);
}


- (BOOL)update:(NSString *)paramAppKey version:(NSString*)paramVersion timestamp:(NSString *)paramTimestamp {
    int rc = 0;
    NSString *query  = [NSString stringWithFormat:@"UPDATE bundle SET appversion=\"%@\", timestamp=\"%@\" where appkey=\"%@\"",
                        paramVersion, paramTimestamp, paramAppKey];
    char *errMsg;
    rc = sqlite3_exec(self.db, [query UTF8String], NULL, NULL, &errMsg);
    if(SQLITE_OK != rc) {
        NSLog(@"Failed to update record  rc:%d, msg=%s", rc, errMsg);
    }
    
    return (rc == SQLITE_OK);
}

@end
