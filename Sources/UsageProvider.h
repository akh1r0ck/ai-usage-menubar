#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UsageSnapshot : NSObject
@property BOOL available;
@property double primaryPercent;
@property BOOL hasPrimary;
@property double secondaryPercent;
@property BOOL hasSecondary;
@property NSTimeInterval primaryReset;
@property NSTimeInterval secondaryReset;
@property NSInteger windowMinutes;
@property long long totalTokens;
@property long long contextWindow;
@property (copy) NSString *plan;
@property (copy) NSString *model;
@property NSDate *updatedAt;
@end

@protocol UsageProvider <NSObject>
- (UsageSnapshot *)currentSnapshot:(NSError **)error;
- (NSURL *)dataURL;
@end

@interface CodexUsageProvider : NSObject <UsageProvider>
- (instancetype)initWithSessionsURL:(NSURL *)url;
@end

@interface ClaudeUsageProvider : NSObject <UsageProvider>
- (instancetype)initWithCacheURL:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
