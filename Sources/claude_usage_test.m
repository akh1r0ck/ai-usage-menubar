#import <Foundation/Foundation.h>
#import "ClaudeUsage.h"

static ClaudeUsageSnapshot *Parse(NSString *json) {
    NSError *error=nil; ClaudeUsageSnapshot *snapshot=[ClaudeUsageParser snapshotFromData:[json dataUsingEncoding:NSUTF8StringEncoding] fetchedAt:[NSDate dateWithTimeIntervalSince1970:100] error:&error];
    NSCAssert(snapshot && !error,@"JSON should parse"); return snapshot;
}
int main(void) { @autoreleasepool {
    ClaudeUsageSnapshot *named=Parse(@"{\"rate_limits\":{\"five_hour\":{\"used_percentage\":59,\"resets_at\":200},\"seven_day\":{\"used_percentage\":85,\"resets_at\":200000}}}");
    NSCAssert(named.sessionWindow.usedPercent.integerValue==59,@"five_hour"); NSCAssert(named.weeklyWindow.usedPercent.integerValue==85,@"seven_day");
    ClaudeUsageSnapshot *aliases=Parse(@"{\"rate_limits\":{\"current_session\":{\"percentage\":60},\"current_week\":{\"used\":84}}}");
    NSCAssert(aliases.sessionWindow.usedPercent.integerValue==60,@"current_session"); NSCAssert(aliases.weeklyWindow.usedPercent.integerValue==84,@"current_week");
    ClaudeUsageSnapshot *generic=Parse(@"{\"rate_limits\":{\"primary\":{\"used_percentage\":20,\"window_minutes\":10080},\"secondary\":{\"used_percentage\":10,\"window_minutes\":300}}}");
    NSCAssert(generic.sessionWindow.usedPercent.integerValue==10,@"shorter window"); NSCAssert(generic.weeklyWindow.usedPercent.integerValue==20,@"longer window");
    ClaudeUsageSnapshot *partial=Parse(@"{\"rate_limits\":{\"week\":{\"used_percentage\":0}}}"); NSCAssert(!partial.sessionWindow && partial.weeklyWindow.usedPercent.integerValue==0,@"missing is not zero");
    ClaudeUsageSnapshot *milliseconds=Parse(@"{\"rate_limits\":{\"session\":{\"used_percentage\":100,\"resets_at\":200000000000}}}"); NSCAssert(milliseconds.sessionWindow.resetsAt.timeIntervalSince1970==200000000,@"milliseconds");
    NSError *error=nil; NSCAssert(![ClaudeUsageParser snapshotFromData:[@"{" dataUsingEncoding:NSUTF8StringEncoding] fetchedAt:NSDate.date error:&error] && error,@"invalid JSON");
    puts("ClaudeUsage parser tests passed");
} return 0; }
