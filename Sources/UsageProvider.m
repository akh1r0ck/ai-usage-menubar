#import "UsageProvider.h"
#import "ClaudeUsage.h"

@implementation UsageSnapshot
- (instancetype)init { if((self=[super init])){_plan=@"";_model=@"";_updatedAt=[NSDate dateWithTimeIntervalSince1970:0];}return self; }
@end

@interface CodexUsageProvider () @property NSURL *sessionsURL; @end
@implementation CodexUsageProvider
- (instancetype)init { NSURL *url=[NSFileManager.defaultManager.homeDirectoryForCurrentUser URLByAppendingPathComponent:@".codex/sessions" isDirectory:YES];return [self initWithSessionsURL:url]; }
- (instancetype)initWithSessionsURL:(NSURL *)url { if((self=[super init]))_sessionsURL=url;return self; }
- (NSURL *)dataURL { return self.sessionsURL; }
- (UsageSnapshot *)currentSnapshot:(NSError **)error {
    UsageSnapshot *snapshot=[UsageSnapshot new];NSArray *keys=@[NSURLContentModificationDateKey,NSURLIsRegularFileKey];NSDirectoryEnumerator *enumerator=[NSFileManager.defaultManager enumeratorAtURL:self.sessionsURL includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];NSMutableArray *files=[NSMutableArray array];
    for(NSURL *url in enumerator){if(![url.pathExtension isEqualToString:@"jsonl"])continue;NSDate *date=nil;[url getResourceValue:&date forKey:NSURLContentModificationDateKey error:nil];if(date)[files addObject:@{@"url":url,@"date":date}];}
    [files sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){return [b[@"date"] compare:a[@"date"]];}];
    for(NSDictionary *file in [files subarrayWithRange:NSMakeRange(0,MIN(12,files.count))]){NSString *text=[NSString stringWithContentsOfURL:file[@"url"] encoding:NSUTF8StringEncoding error:nil];for(NSString *line in [text componentsSeparatedByString:@"\n"].reverseObjectEnumerator){NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];NSDictionary *event=data.length?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;NSDictionary *payload=event[@"payload"];if(![payload[@"type"] isEqualToString:@"token_count"])continue;NSDictionary *limits=payload[@"rate_limits"]?:@{};NSDictionary *window=limits[@"primary"]?:limits[@"secondary"];if(![window isKindOfClass:NSDictionary.class])continue;snapshot.available=YES;snapshot.primaryPercent=[window[@"used_percent"] doubleValue];snapshot.primaryReset=[window[@"resets_at"] doubleValue];snapshot.windowMinutes=[window[@"window_minutes"] integerValue];snapshot.plan=[limits[@"plan_type"] capitalizedString]?:@"";NSDictionary *info=payload[@"info"]?:@{};snapshot.totalTokens=[info[@"total_token_usage"][@"total_tokens"] longLongValue];snapshot.contextWindow=[info[@"model_context_window"] longLongValue];snapshot.updatedAt=file[@"date"];return snapshot;}}
    return snapshot;
}
@end

@interface ClaudeUsageProvider () @property NSURL *cacheURL; @end
@implementation ClaudeUsageProvider
- (instancetype)init { NSURL *url=[NSFileManager.defaultManager.homeDirectoryForCurrentUser URLByAppendingPathComponent:@".claude/usage-menubar.json"];return [self initWithCacheURL:url]; }
- (instancetype)initWithCacheURL:(NSURL *)url { if((self=[super init]))_cacheURL=url;return self; }
- (NSURL *)dataURL { return self.cacheURL; }
- (UsageSnapshot *)currentSnapshot:(NSError **)error { UsageSnapshot *result=[UsageSnapshot new];NSDate *date=nil;[self.cacheURL getResourceValue:&date forKey:NSURLContentModificationDateKey error:nil];NSData *data=[NSData dataWithContentsOfURL:self.cacheURL options:0 error:error];if(!data)return result;ClaudeUsageSnapshot *snapshot=[ClaudeUsageParser snapshotFromData:data fetchedAt:date?:NSDate.date error:error];if(!snapshot)return result;ClaudeUsageWindow *session=snapshot.sessionWindow,*weekly=snapshot.weeklyWindow;if(!session.usedPercent&&!weekly.usedPercent)return result;result.available=YES;result.hasPrimary=session.usedPercent!=nil;result.primaryPercent=(session.usedPercent?:weekly.usedPercent).doubleValue;result.primaryReset=session.resetsAt.timeIntervalSince1970;result.windowMinutes=session.windowMinutes.integerValue;result.hasSecondary=weekly.usedPercent!=nil;result.secondaryPercent=weekly.usedPercent.doubleValue;result.secondaryReset=weekly.resetsAt.timeIntervalSince1970;result.plan=snapshot.planType?:@"";result.model=snapshot.modelName?:@"";result.updatedAt=snapshot.fetchedAt;return result; }
@end
