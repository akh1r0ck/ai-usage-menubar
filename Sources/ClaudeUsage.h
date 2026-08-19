#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ClaudeUsageWindowKind) {
    ClaudeUsageWindowKindSession,
    ClaudeUsageWindowKindWeekly,
};

typedef NS_ENUM(NSInteger, ClaudeUsageSource) {
    ClaudeUsageSourceStatusLine,
    ClaudeUsageSourceCache,
    ClaudeUsageSourceUnavailable,
};

@interface ClaudeUsageWindow : NSObject
@property ClaudeUsageWindowKind kind;
@property(nullable) NSNumber *usedPercent;
@property(nullable) NSNumber *windowMinutes;
@property(nullable) NSDate *resetsAt;
@property NSDate *fetchedAt;
@property NSString *source;
@property(readonly, nullable) NSNumber *remainingPercent;
- (BOOL)isStaleAtDate:(NSDate *)date;
@end

@interface ClaudeUsageSnapshot : NSObject
@property(nullable) ClaudeUsageWindow *sessionWindow;
@property(nullable) ClaudeUsageWindow *weeklyWindow;
@property(nullable) NSString *planType;
@property(nullable) NSString *modelName;
@property NSDate *fetchedAt;
@property ClaudeUsageSource source;
@end

@interface ClaudeUsageParser : NSObject
+ (nullable ClaudeUsageSnapshot *)snapshotFromData:(NSData *)data
                                         fetchedAt:(nullable NSDate *)fetchedAt
                                             error:(NSError * _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
