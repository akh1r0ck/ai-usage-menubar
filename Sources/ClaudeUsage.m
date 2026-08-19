#import "ClaudeUsage.h"

@implementation ClaudeUsageWindow
- (NSNumber *)remainingPercent { return self.usedPercent ? @(MAX(0, 100.0-self.usedPercent.doubleValue)) : nil; }
- (BOOL)isStaleAtDate:(NSDate *)date { return [date timeIntervalSinceDate:self.fetchedAt] >= 600; }
@end

@implementation ClaudeUsageSnapshot
@end

@implementation ClaudeUsageParser
+ (NSNumber *)numberIn:(NSDictionary *)dictionary keys:(NSArray<NSString *> *)keys {
    for (NSString *key in keys) {
        id value=dictionary[key];
        if ([value isKindOfClass:NSNumber.class]) return value;
    }
    return nil;
}
+ (NSDate *)dateFromNumber:(NSNumber *)number {
    if (!number) return nil;
    double epoch=number.doubleValue;
    if (epoch > 100000000000.0) epoch/=1000.0;
    return [NSDate dateWithTimeIntervalSince1970:epoch];
}
+ (ClaudeUsageWindow *)windowFrom:(NSDictionary *)dictionary kind:(ClaudeUsageWindowKind)kind fetchedAt:(NSDate *)fetchedAt {
    if (![dictionary isKindOfClass:NSDictionary.class] || dictionary.count==0) return nil;
    NSNumber *used=[self numberIn:dictionary keys:@[@"used_percentage",@"percentage",@"used_percent",@"used"]];
    NSNumber *minutes=[self numberIn:dictionary keys:@[@"window_minutes",@"windowMinutes",@"duration_minutes"]];
    NSNumber *reset=[self numberIn:dictionary keys:@[@"resets_at",@"reset_at",@"reset"]];
    if (!used && !minutes && !reset) return nil;
    ClaudeUsageWindow *window=[ClaudeUsageWindow new];
    window.kind=kind; window.usedPercent=used; window.windowMinutes=minutes;
    window.resetsAt=[self dateFromNumber:reset]; window.fetchedAt=fetchedAt;
    window.source=@"Claude Code statusLine";
    return window;
}
+ (ClaudeUsageWindowKind)kindForName:(NSString *)name dictionary:(NSDictionary *)dictionary fallback:(ClaudeUsageWindowKind)fallback {
    NSString *normalized=name.lowercaseString;
    id explicitKind=dictionary[@"kind"]?:dictionary[@"type"]?:dictionary[@"window"];
    if ([explicitKind isKindOfClass:NSString.class]) normalized=[explicitKind lowercaseString];
    NSSet *sessions=[NSSet setWithArray:@[@"session",@"five_hour",@"current_session"]];
    NSSet *weeks=[NSSet setWithArray:@[@"weekly",@"week",@"seven_day",@"current_week"]];
    if ([sessions containsObject:normalized]) return ClaudeUsageWindowKindSession;
    if ([weeks containsObject:normalized]) return ClaudeUsageWindowKindWeekly;
    return fallback;
}
+ (ClaudeUsageSnapshot *)snapshotFromData:(NSData *)data fetchedAt:(NSDate *)fetchedAt error:(NSError **)error {
    id root=[NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![root isKindOfClass:NSDictionary.class]) return nil;
    NSDictionary *document=root, *limits=document[@"rate_limits"];
    if (![limits isKindOfClass:NSDictionary.class]) limits=@{};
    ClaudeUsageSnapshot *snapshot=[ClaudeUsageSnapshot new];
    snapshot.fetchedAt=fetchedAt?:NSDate.date; snapshot.source=ClaudeUsageSourceStatusLine;
    snapshot.planType=[document[@"plan_type"] isKindOfClass:NSString.class]?document[@"plan_type"]:document[@"plan"];
    snapshot.modelName=[document valueForKeyPath:@"model.display_name"];
    NSArray *sessionKeys=@[@"session",@"five_hour",@"current_session"];
    NSArray *weeklyKeys=@[@"weekly",@"week",@"seven_day",@"current_week"];
    for (NSString *key in sessionKeys) if (!snapshot.sessionWindow && [limits[key] isKindOfClass:NSDictionary.class]) snapshot.sessionWindow=[self windowFrom:limits[key] kind:ClaudeUsageWindowKindSession fetchedAt:snapshot.fetchedAt];
    for (NSString *key in weeklyKeys) if (!snapshot.weeklyWindow && [limits[key] isKindOfClass:NSDictionary.class]) snapshot.weeklyWindow=[self windowFrom:limits[key] kind:ClaudeUsageWindowKindWeekly fetchedAt:snapshot.fetchedAt];
    NSMutableArray<NSDictionary *> *generic=[NSMutableArray array];
    for (NSString *key in @[@"primary",@"secondary"]) if ([limits[key] isKindOfClass:NSDictionary.class]) [generic addObject:@{ @"name":key, @"value":limits[key] }];
    [generic sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSNumber *am=[self numberIn:a[@"value"] keys:@[@"window_minutes",@"windowMinutes",@"duration_minutes"]]?:@(NSIntegerMax);
        NSNumber *bm=[self numberIn:b[@"value"] keys:@[@"window_minutes",@"windowMinutes",@"duration_minutes"]]?:@(NSIntegerMax);
        return [am compare:bm];
    }];
    for (NSUInteger index=0; index<generic.count; index++) {
        NSDictionary *entry=generic[index], *value=entry[@"value"];
        ClaudeUsageWindowKind fallback=index==0?ClaudeUsageWindowKindSession:ClaudeUsageWindowKindWeekly;
        ClaudeUsageWindowKind kind=[self kindForName:entry[@"name"] dictionary:value fallback:fallback];
        ClaudeUsageWindow *window=[self windowFrom:value kind:kind fetchedAt:snapshot.fetchedAt];
        if (kind==ClaudeUsageWindowKindSession && !snapshot.sessionWindow) snapshot.sessionWindow=window;
        if (kind==ClaudeUsageWindowKindWeekly && !snapshot.weeklyWindow) snapshot.weeklyWindow=window;
    }
    return snapshot;
}
@end
