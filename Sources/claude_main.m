#import <Cocoa/Cocoa.h>

static NSColor *CColor(double p) { return p < 60 ? NSColor.systemGreenColor : (p < 85 ? NSColor.systemOrangeColor : NSColor.systemRedColor); }
static NSFont *CModern(CGFloat size, NSFontWeight weight) { NSFont *b=[NSFont systemFontOfSize:size weight:weight]; NSFontDescriptor *d=[b.fontDescriptor fontDescriptorWithDesign:NSFontDescriptorSystemDesignRounded]; return d?[NSFont fontWithDescriptor:d size:size]:b; }
static NSAttributedString *ClaudeTitle(NSString *value, NSColor *color) { NSMutableAttributedString *t=[[NSMutableAttributedString alloc]initWithString:@"Claude " attributes:@{NSFontAttributeName:CModern(13,NSFontWeightSemibold),NSForegroundColorAttributeName:NSColor.systemPurpleColor}]; [t appendAttributedString:[[NSAttributedString alloc]initWithString:value attributes:@{NSFontAttributeName:CModern(13,NSFontWeightBold),NSForegroundColorAttributeName:color}]]; return t; }

@interface CBar : NSView
@property(nonatomic) double value;
@end
@implementation CBar
- (void)setValue:(double)v { _value=v; self.needsDisplay=YES; }
- (void)drawRect:(NSRect)r {
    NSRect b=NSInsetRect(self.bounds,1,4); NSBezierPath *bg=[NSBezierPath bezierPathWithRoundedRect:b xRadius:5 yRadius:5];
    [NSColor.quaternaryLabelColor setFill]; [bg fill]; double f=MAX(0,MIN(1,self.value/100)); if(!f)return;
    b.size.width*=f; [CColor(self.value) setFill]; [[NSBezierPath bezierPathWithRoundedRect:b xRadius:5 yRadius:5] fill];
}
@end

@interface ClaudeDelegate : NSObject<NSApplicationDelegate>
@property NSStatusItem *item; @property NSPopover *popover;
@property NSTextField *session; @property NSTextField *week; @property NSTextField *sessionReset; @property NSTextField *weekReset; @property NSTextField *model; @property NSTextField *updated;
@property CBar *sessionBar; @property CBar *weekBar;
@end

@implementation ClaudeDelegate
- (NSTextField*)label:(NSString*)s size:(CGFloat)n color:(NSColor*)c { NSTextField *l=[NSTextField labelWithString:s]; l.font=CModern(n,NSFontWeightRegular); if(c)l.textColor=c; return l; }
- (void)applicationDidFinishLaunching:(NSNotification*)n {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory]; [self makeItem:@"Claude使用率 --%"];
    [self buildPopover]; [self refresh];
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(screensChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
}
- (void)makeItem:(NSString*)title {
    self.item=[NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength]; self.item.button.attributedTitle=ClaudeTitle([title containsString:@"--"]?@"--%":title,NSColor.secondaryLabelColor);
    self.item.button.toolTip=@"Claude Code 使用量"; self.item.button.target=self; self.item.button.action=@selector(toggle:);
}
- (void)screensChanged:(NSNotification*)n { [NSStatusBar.systemStatusBar removeStatusItem:self.item]; [self makeItem:@"--%"] ; [self refresh]; }
- (void)buildPopover {
    NSTextField *title=[self label:@"Claude Code 使用量" size:15 color:NSColor.systemPurpleColor]; title.font=CModern(16,NSFontWeightBold);
    self.session=[self label:@"セッション --%" size:24 color:nil]; self.session.font=CModern(24,NSFontWeightBold);
    self.sessionBar=[CBar new]; self.weekBar=[CBar new]; for(CBar *b in @[self.sessionBar,self.weekBar]){b.translatesAutoresizingMaskIntoConstraints=NO;[b.heightAnchor constraintEqualToConstant:16].active=YES;[b.widthAnchor constraintEqualToConstant:288].active=YES;}
    self.sessionReset=[self label:@"" size:11 color:NSColor.secondaryLabelColor];
    self.week=[self label:@"週間 --%" size:18 color:nil]; self.week.font=CModern(18,NSFontWeightSemibold);
    self.weekReset=[self label:@"" size:11 color:NSColor.secondaryLabelColor]; self.model=[self label:@"" size:11 color:NSColor.secondaryLabelColor]; self.updated=[self label:@"" size:10 color:NSColor.tertiaryLabelColor];
    NSButton *update=[NSButton buttonWithTitle:@"更新" target:self action:@selector(refresh)], *quit=[NSButton buttonWithTitle:@"終了" target:NSApp action:@selector(terminate:)];
    NSStackView *buttons=[NSStackView stackViewWithViews:@[update,quit]];buttons.spacing=8;buttons.distribution=NSStackViewDistributionFillEqually;[buttons.widthAnchor constraintEqualToConstant:288].active=YES;
    NSStackView *stack=[NSStackView stackViewWithViews:@[title,self.session,self.sessionBar,self.sessionReset,self.week,self.weekBar,self.weekReset,self.model,self.updated,buttons]];
    stack.orientation=NSUserInterfaceLayoutOrientationVertical;stack.alignment=NSLayoutAttributeLeading;stack.spacing=7;stack.edgeInsets=NSEdgeInsetsMake(16,16,16,16);stack.translatesAutoresizingMaskIntoConstraints=NO;
    NSViewController *vc=[NSViewController new];vc.view=[[NSView alloc]initWithFrame:NSMakeRect(0,0,320,310)];[vc.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor],[stack.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor],[stack.topAnchor constraintEqualToAnchor:vc.view.topAnchor]]];
    self.popover=[NSPopover new];self.popover.contentViewController=vc;self.popover.behavior=NSPopoverBehaviorTransient;
}
- (void)toggle:(id)x { if(self.popover.shown)[self.popover performClose:nil];else{[self refresh];[self.popover showRelativeToRect:self.item.button.bounds ofView:self.item.button preferredEdge:NSRectEdgeMinY];} }
- (NSDictionary*)block:(NSDictionary*)r keys:(NSArray*)keys { for(NSString *k in keys)if([r[k] isKindOfClass:NSDictionary.class])return r[k];return @{}; }
- (NSNumber*)number:(NSDictionary*)d keys:(NSArray*)keys { for(NSString *k in keys)if([d[k] isKindOfClass:NSNumber.class])return d[k];return nil; }
- (NSString*)reset:(NSNumber*)epoch { if(!epoch)return @"リセット時刻: --"; NSDateFormatter *f=[NSDateFormatter new];f.locale=[NSLocale localeWithLocaleIdentifier:@"ja_JP"];f.dateFormat=@"M月d日 H:mm";return [@"リセット: " stringByAppendingString:[f stringFromDate:[NSDate dateWithTimeIntervalSince1970:epoch.doubleValue]]]; }
- (void)refresh {
    NSURL *u=[NSFileManager.defaultManager.homeDirectoryForCurrentUser URLByAppendingPathComponent:@".claude/usage-menubar.json"];
    NSData *data=[NSData dataWithContentsOfURL:u]; NSDictionary *d=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;
    NSDictionary *r=d[@"rate_limits"]?:@{};NSDictionary *s=[self block:r keys:@[@"five_hour",@"session",@"current_session"]],*w=[self block:r keys:@[@"seven_day",@"week",@"current_week"]];
    NSNumber *sp=[self number:s keys:@[@"used_percentage",@"percentage",@"used"]],*wp=[self number:w keys:@[@"used_percentage",@"percentage",@"used"]];
    if(!sp&&!wp){self.item.button.attributedTitle=ClaudeTitle(@"--%",NSColor.secondaryLabelColor);self.session.stringValue=@"データ待機中";self.session.textColor=NSColor.secondaryLabelColor;self.week.stringValue=@"Claude Codeで1メッセージ送信してください";return;}
    double p=sp?sp.doubleValue:wp.doubleValue;self.item.button.attributedTitle=ClaudeTitle([NSString stringWithFormat:@"%.0f%%",p],CColor(p));
    self.session.stringValue=sp?[NSString stringWithFormat:@"セッション %.0f%%",sp.doubleValue]:@"セッション --%";self.session.textColor=sp?CColor(sp.doubleValue):NSColor.secondaryLabelColor;self.sessionBar.value=sp.doubleValue;
    self.week.stringValue=wp?[NSString stringWithFormat:@"週間 %.0f%%",wp.doubleValue]:@"週間 --%";self.week.textColor=wp?CColor(wp.doubleValue):NSColor.secondaryLabelColor;self.weekBar.value=wp.doubleValue;
    self.sessionReset.stringValue=[self reset:[self number:s keys:@[@"resets_at",@"reset_at",@"reset"]]];self.weekReset.stringValue=[self reset:[self number:w keys:@[@"resets_at",@"reset_at",@"reset"]]];
    self.model.stringValue=[NSString stringWithFormat:@"モデル: %@",[d valueForKeyPath:@"model.display_name"]?:@"--"];
    NSDate *date=nil;[u getResourceValue:&date forKey:NSURLContentModificationDateKey error:nil];NSDateFormatter *f=[NSDateFormatter new];f.dateFormat=@"M月d日 H:mm:ss";self.updated.stringValue=date?[NSString stringWithFormat:@"最終更新: %@",[f stringFromDate:date]]:@"";
}
@end

int main(){@autoreleasepool{NSApplication *a=NSApplication.sharedApplication;ClaudeDelegate *d=[ClaudeDelegate new];a.delegate=d;[a run];}return 0;}
