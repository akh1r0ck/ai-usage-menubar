#import <Foundation/Foundation.h>
#import "UsageProvider.h"

static void Require(BOOL condition, NSString *message) { if(!condition){NSLog(@"FAILED: %@",message);exit(1);} }

int main(void) { @autoreleasepool {
    NSURL *root=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString] isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:root withIntermediateDirectories:YES attributes:nil error:nil];
    NSURL *session=[root URLByAppendingPathComponent:@"session.jsonl"];
    NSString *line=@"{\"payload\":{\"type\":\"token_count\",\"rate_limits\":{\"plan_type\":\"plus\",\"primary\":{\"used_percent\":61,\"resets_at\":2000000000,\"window_minutes\":300}},\"info\":{\"total_token_usage\":{\"total_tokens\":1200},\"model_context_window\":10000}}}\n";
    [line writeToURL:session atomically:YES encoding:NSUTF8StringEncoding error:nil];
    UsageSnapshot *codex=[[[CodexUsageProvider alloc]initWithSessionsURL:root] currentSnapshot:nil];
    Require(codex.available&&codex.primaryPercent==61&&codex.totalTokens==1200&&codex.windowMinutes==300,@"Codex snapshot");

    NSURL *cache=[root URLByAppendingPathComponent:@"claude.json"];
    NSString *json=@"{\"model\":{\"display_name\":\"Sonnet\"},\"rate_limits\":{\"five_hour\":{\"used_percentage\":32,\"resets_at\":2000000000},\"seven_day\":{\"used_percentage\":47,\"resets_at\":2000100000}}}";
    [json writeToURL:cache atomically:YES encoding:NSUTF8StringEncoding error:nil];
    UsageSnapshot *claude=[[[ClaudeUsageProvider alloc]initWithCacheURL:cache] currentSnapshot:nil];
    Require(claude.available&&claude.hasPrimary&&claude.primaryPercent==32&&claude.hasSecondary&&claude.secondaryPercent==47,@"Claude dual snapshot");
    Require([claude.model isEqualToString:@"Sonnet"],@"Claude model");
    [NSFileManager.defaultManager removeItemAtURL:root error:nil];
} return 0; }
