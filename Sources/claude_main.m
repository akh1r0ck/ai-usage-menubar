#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>
#import "ClaudeUsage.h"
#import "UsageUI.h"
#import "UsageProvider.h"

static NSString *RelativeReset(NSDate *reset, NSDate *now) {
    if (!reset) return @"リセット時刻を取得できません";
    NSTimeInterval seconds=[reset timeIntervalSinceDate:now];
    if (seconds<0) return @"データを再取得中";
    NSInteger minutes=(NSInteger)floor(seconds/60.0);
    if (minutes<1) return @"まもなくリセット";
    if (minutes<60) return [NSString stringWithFormat:@"あと%ld分",minutes];
    NSInteger hours=minutes/60;
    if (hours<24) return [NSString stringWithFormat:@"あと%ld時間%ld分",hours,minutes%60];
    return [NSString stringWithFormat:@"あと%ld日%ld時間",hours/24,hours%24];
}
static NSString *UsageState(double percent) { return percent<60?@"余裕あり":(percent<85?@"注意":@"上限間近"); }

@interface ClaudeUsageCard : NSBox
@property NSTextField *nameLabel, *valueLabel, *remainingLabel, *relativeLabel, *resetLabel, *warningLabel;
@property UsageBar *bar;
- (instancetype)initWithName:(NSString *)name;
- (void)displayWindow:(ClaudeUsageWindow *)window now:(NSDate *)now;
@end

@implementation ClaudeUsageCard
- (instancetype)initWithName:(NSString *)name {
    if ((self=[super init])) {
        self.boxType=NSBoxCustom; self.cornerRadius=10; self.fillColor=NSColor.controlBackgroundColor; self.borderColor=NSColor.separatorColor;
        self.nameLabel=[NSTextField labelWithString:name]; self.nameLabel.font=UsageDetailFont(14,NSFontWeightSemibold);
        self.valueLabel=[NSTextField labelWithString:@"--% 使用"]; self.valueLabel.font=UsageDetailFont(19,NSFontWeightBold);
        self.remainingLabel=[NSTextField labelWithString:@"残り--%"]; self.remainingLabel.textColor=NSColor.secondaryLabelColor;
        NSStackView *valueRow=[NSStackView stackViewWithViews:@[self.valueLabel,self.remainingLabel]]; valueRow.distribution=NSStackViewDistributionFill; valueRow.alignment=NSLayoutAttributeFirstBaseline;
        self.bar=[UsageBar new]; self.bar.translatesAutoresizingMaskIntoConstraints=NO; [self.bar.heightAnchor constraintEqualToConstant:16].active=YES; [self.bar.widthAnchor constraintEqualToConstant:276].active=YES;
        self.relativeLabel=[NSTextField labelWithString:@"リセット時刻を取得できません"];
        self.resetLabel=[NSTextField labelWithString:@""]; self.resetLabel.textColor=NSColor.secondaryLabelColor;
        self.warningLabel=[NSTextField labelWithString:@""]; self.warningLabel.textColor=NSColor.systemOrangeColor; self.warningLabel.hidden=YES;
        NSStackView *stack=[NSStackView stackViewWithViews:@[self.nameLabel,valueRow,self.bar,self.relativeLabel,self.resetLabel,self.warningLabel]];
        stack.orientation=NSUserInterfaceLayoutOrientationVertical; stack.spacing=5; stack.edgeInsets=NSEdgeInsetsMake(11,11,11,11); stack.translatesAutoresizingMaskIntoConstraints=NO;
        [self addSubview:stack]; [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],[stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],[stack.topAnchor constraintEqualToAnchor:self.topAnchor],[stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]]];
    }
    return self;
}
- (void)displayWindow:(ClaudeUsageWindow *)window now:(NSDate *)now {
    NSNumber *used=window.usedPercent;
    if (!used) {
        self.valueLabel.stringValue=@"使用率を取得できません"; self.valueLabel.textColor=NSColor.secondaryLabelColor;
        self.remainingLabel.stringValue=@""; self.bar.value=0; self.bar.alphaValue=.35; self.relativeLabel.stringValue=@"リセット時刻を取得できません"; self.resetLabel.stringValue=@""; self.warningLabel.hidden=YES;
        self.accessibilityLabel=[NSString stringWithFormat:@"Claude%@使用率、取得できません",self.nameLabel.stringValue]; return;
    }
    double percent=MAX(0,MIN(100,used.doubleValue)); NSString *state=UsageState(percent);
    self.valueLabel.stringValue=[NSString stringWithFormat:@"%.0f%% 使用",percent]; self.valueLabel.textColor=UsageColor(percent);
    self.remainingLabel.stringValue=[NSString stringWithFormat:@"残り%.0f%%",100-percent]; self.bar.value=percent; self.bar.alphaValue=1;
    self.relativeLabel.stringValue=percent>=100?@"利用枠のリセット待ち":RelativeReset(window.resetsAt,now);
    if (window.resetsAt) self.resetLabel.stringValue=[NSString stringWithFormat:@"%@ にリセット",UsageFormattedDate(window.resetsAt,NO)]; else self.resetLabel.stringValue=@"";
    BOOL stale=[window isStaleAtDate:now]; self.warningLabel.hidden=!stale; self.warningLabel.stringValue=stale?@"⚠ 現在の使用率と異なる可能性があります":@"";
    self.accessibilityLabel=[NSString stringWithFormat:@"Claude%@使用率%.0fパーセント、%@、%@%@",self.nameLabel.stringValue,percent,state,self.relativeLabel.stringValue,stale?@"、古いデータ":@""];
}
@end

@interface ClaudeDelegate : NSObject <NSApplicationDelegate>
@property NSStatusItem *item; @property NSPopover *popover; @property ClaudeUsageCard *sessionCard, *weeklyCard;
@property NSTextField *planLabel, *updatedLabel; @property NSTimer *timer;
@property UsageSettingsWindowController *settingsWindow; @property UsageNotificationController *notificationController; @property id<UsageProvider> provider;
@end

@implementation ClaudeDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    UsageApplyTheme();
    self.provider=[ClaudeUsageProvider new]; self.notificationController=[[UsageNotificationController alloc]initWithService:UsageServiceClaude];
    UNUserNotificationCenter.currentNotificationCenter.delegate=(id)self.notificationController;
    self.item=[NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength]; self.item.button.target=self; self.item.button.action=@selector(toggle:); self.item.button.toolTip=@"Claude共有利用枠";
    [self buildPopover]; [self refresh]; [self restartTimer];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(settingsChanged:) name:UsageSettingsDidChangeNotification object:nil];
    [NSDistributedNotificationCenter.defaultCenter addObserver:self selector:@selector(settingsChanged:) name:UsageSettingsDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(screensChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
}
- (NSAttributedString *)menuTitleForSession:(ClaudeUsageWindow *)session weekly:(ClaudeUsageWindow *)weekly stale:(BOOL)stale {
    UsageSettingsStore *settings=UsageSettingsStore.sharedStore; NSFont *font=UsageFont(settings.menuBarFontSize,NSFontWeightBold);
    NSString *prefix=settings.showServiceName?@"Claude ":@"";NSMutableAttributedString *title=[[NSMutableAttributedString alloc]initWithString:prefix attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[settings accentColorForService:UsageServiceClaude]}];
    NSString *sessionText=session.usedPercent?UsageMenuValue(session.usedPercent.doubleValue):@"--%";
    NSString *weeklyText=weekly.usedPercent?[NSString stringWithFormat:@" · W%@",UsageMenuValue(weekly.usedPercent.doubleValue)]:@" · W--%";
    [title appendAttributedString:[[NSAttributedString alloc]initWithString:sessionText attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:session.usedPercent?UsageColor(session.usedPercent.doubleValue):NSColor.secondaryLabelColor}]];
    [title appendAttributedString:[[NSAttributedString alloc]initWithString:weeklyText attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:weekly.usedPercent?UsageColor(weekly.usedPercent.doubleValue):NSColor.secondaryLabelColor}]];
    if (stale) [title appendAttributedString:[[NSAttributedString alloc]initWithString:@" ⚠" attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:NSColor.systemOrangeColor}]];
    return title;
}
- (void)buildPopover {
    NSTextField *title=[NSTextField labelWithString:@"Claude 使用量"]; title.font=UsageDetailFont(17,NSFontWeightBold); title.textColor=NSColor.systemPurpleColor;
    self.planLabel=[NSTextField labelWithString:@"プラン: --"]; self.planLabel.textColor=NSColor.secondaryLabelColor;
    self.sessionCard=[[ClaudeUsageCard alloc]initWithName:@"セッション"]; self.weeklyCard=[[ClaudeUsageCard alloc]initWithName:@"週間"];
    self.updatedLabel=[NSTextField wrappingLabelWithString:@"最終更新：--\nClaude Desktop・Web・Claude Codeの利用量を合算した共有利用枠です\n取得元：Claude Code statusLine"]; self.updatedLabel.textColor=NSColor.secondaryLabelColor;
    UsageSettingsStore *display=UsageSettingsStore.sharedStore;self.updatedLabel.hidden=!display.showUpdatedTime;self.sessionCard.resetLabel.hidden=!display.showResetTime;self.weeklyCard.resetLabel.hidden=!display.showResetTime;
    NSButton *settings=[NSButton buttonWithTitle:@"設定…" target:self action:@selector(openSettings:)], *refresh=[NSButton buttonWithTitle:@"再取得" target:self action:@selector(refresh)], *quit=[NSButton buttonWithTitle:@"終了" target:NSApp action:@selector(terminate:)];
    NSStackView *buttons=[NSStackView stackViewWithViews:@[settings,refresh,quit]]; buttons.distribution=NSStackViewDistributionFillEqually; buttons.spacing=8;
    NSStackView *stack=[NSStackView stackViewWithViews:@[title,self.planLabel,self.sessionCard,self.weeklyCard,self.updatedLabel,buttons]]; stack.orientation=NSUserInterfaceLayoutOrientationVertical; stack.spacing=8; stack.edgeInsets=NSEdgeInsetsMake(14,14,14,14); stack.translatesAutoresizingMaskIntoConstraints=NO;
    NSViewController *controller=[NSViewController new]; controller.view=[[NSView alloc]initWithFrame:NSMakeRect(0,0,332,490)]; [controller.view addSubview:stack]; [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:controller.view.leadingAnchor],[stack.trailingAnchor constraintEqualToAnchor:controller.view.trailingAnchor],[stack.topAnchor constraintEqualToAnchor:controller.view.topAnchor]]];
    self.popover=[NSPopover new]; self.popover.contentViewController=controller; self.popover.behavior=NSPopoverBehaviorTransient;
}
- (void)toggle:(id)sender { if(self.popover.shown)[self.popover performClose:nil];else{if(UsageSettingsStore.sharedStore.refreshWhenOpened)[self refresh];[self.popover showRelativeToRect:self.item.button.bounds ofView:self.item.button preferredEdge:NSRectEdgeMinY];} }
- (void)openSettings:(id)sender { if(!self.settingsWindow)self.settingsWindow=[[UsageSettingsWindowController alloc]initWithService:UsageServiceClaude];[self.settingsWindow showWindow:nil];[NSApp activateIgnoringOtherApps:YES]; }
- (void)restartTimer { [self.timer invalidate];self.timer=nil;if(UsageSettingsStore.sharedStore.autoRefreshEnabled)self.timer=[NSTimer scheduledTimerWithTimeInterval:UsageSettingsStore.sharedStore.refreshInterval target:self selector:@selector(refresh) userInfo:nil repeats:YES]; }
- (void)settingsChanged:(NSNotification *)notification { if([notification.object isKindOfClass:NSString.class]&&[notification.object isEqualToString:NSBundle.mainBundle.bundleIdentifier])return;UsageApplyTheme();[self restartTimer];[self buildPopover];[self refresh]; }
- (void)screensChanged:(NSNotification *)notification { NSAttributedString *title=self.item.button.attributedTitle;[NSStatusBar.systemStatusBar removeStatusItem:self.item];self.item=[NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];self.item.button.attributedTitle=title;self.item.button.target=self;self.item.button.action=@selector(toggle:);self.item.button.toolTip=@"Claude共有利用枠";[self refresh]; }
- (void)refresh {
    UsageSnapshot *usage=[self.provider currentSnapshot:nil];NSDate *now=NSDate.date;NSDate *fetchedAt=usage.updatedAt;
    ClaudeUsageWindow *session=[ClaudeUsageWindow new],*weekly=[ClaudeUsageWindow new];session.usedPercent=usage.hasPrimary?@(usage.primaryPercent):nil;session.resetsAt=usage.primaryReset?[NSDate dateWithTimeIntervalSince1970:usage.primaryReset]:nil;session.fetchedAt=fetchedAt;weekly.usedPercent=usage.hasSecondary?@(usage.secondaryPercent):nil;weekly.resetsAt=usage.secondaryReset?[NSDate dateWithTimeIntervalSince1970:usage.secondaryReset]:nil;weekly.fetchedAt=fetchedAt;
    BOOL stale=(session.usedPercent&&[session isStaleAtDate:now])||(weekly.usedPercent&&[weekly isStaleAtDate:now]); self.item.button.attributedTitle=[self menuTitleForSession:session weekly:weekly stale:stale];
    [self.sessionCard displayWindow:session now:now]; [self.weeklyCard displayWindow:weekly now:now];
    NSString *plan=usage.plan.length?usage.plan:@"プラン: --";NSString *model=UsageSettingsStore.sharedStore.showModel&&usage.model.length?[NSString stringWithFormat:@"  ·  %@",usage.model]:@"";self.planLabel.stringValue=[NSString stringWithFormat:@"%@%@",plan,model];
    NSString *updated=fetchedAt?UsageFormattedDate(fetchedAt,YES):@"--";
    NSString *age=stale?[NSString stringWithFormat:@"（%.0f分前）⚠",[now timeIntervalSinceDate:fetchedAt]/60.0]:@"";
    self.updatedLabel.stringValue=[NSString stringWithFormat:@"最終更新：%@%@\nClaude Desktop・Web・Claude Codeの利用量を合算した共有利用枠です\n取得元：Claude Code statusLine",updated,age];
    NSTimeInterval reset=usage.primaryReset?:usage.secondaryReset;[self.notificationController evaluateUsedPercent:usage.primaryPercent resetIdentifier:[NSString stringWithFormat:@"%.0f",reset]];
    self.item.button.accessibilityLabel=[NSString stringWithFormat:@"Claudeセッション使用率%@、週間使用率%@%@",session.usedPercent?[NSString stringWithFormat:@"%.0fパーセント",session.usedPercent.doubleValue]:@"取得できません",weekly.usedPercent?[NSString stringWithFormat:@"%.0fパーセント",weekly.usedPercent.doubleValue]:@"取得できません",stale?@"、古いデータ":@""];
}
@end

int main(void) { @autoreleasepool { NSApplication *app=NSApplication.sharedApplication; ClaudeDelegate *delegate=[ClaudeDelegate new]; app.delegate=delegate; [app run]; } return 0; }
