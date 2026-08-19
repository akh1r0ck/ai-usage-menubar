#import <Cocoa/Cocoa.h>

static NSColor *UsageColor(double value) {
    if (value < 60) return NSColor.systemGreenColor;
    if (value < 85) return NSColor.systemOrangeColor;
    return NSColor.systemRedColor;
}

static NSFont *ModernFont(CGFloat size, NSFontWeight weight) {
    NSFont *base = [NSFont systemFontOfSize:size weight:weight];
    NSFontDescriptor *descriptor = [base.fontDescriptor fontDescriptorWithDesign:NSFontDescriptorSystemDesignRounded];
    return descriptor ? [NSFont fontWithDescriptor:descriptor size:size] : base;
}

static NSAttributedString *CodexTitle(NSString *value, NSColor *color) {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"Codex " attributes:@{NSFontAttributeName: ModernFont(13, NSFontWeightSemibold), NSForegroundColorAttributeName: NSColor.systemBlueColor}];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:value attributes:@{NSFontAttributeName: ModernFont(13, NSFontWeightBold), NSForegroundColorAttributeName: color}]];
    return text;
}

@interface UsageBar : NSView
@property (nonatomic) double value;
@end

@implementation UsageBar
- (void)setValue:(double)value { _value = value; self.needsDisplay = YES; }
- (void)drawRect:(NSRect)dirtyRect {
    NSRect box = NSInsetRect(self.bounds, 1, 4);
    NSBezierPath *background = [NSBezierPath bezierPathWithRoundedRect:box xRadius:5 yRadius:5];
    [NSColor.quaternaryLabelColor setFill]; [background fill];
    double fraction = MAX(0, MIN(1, self.value / 100.0));
    if (fraction <= 0) return;
    box.size.width *= fraction;
    NSBezierPath *fill = [NSBezierPath bezierPathWithRoundedRect:box xRadius:5 yRadius:5];
    [UsageColor(self.value) setFill]; [fill fill];
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property NSStatusItem *statusItem;
@property NSPopover *popover;
@property NSTextField *percentLabel;
@property NSTextField *periodLabel;
@property NSTextField *resetLabel;
@property NSTextField *tokenLabel;
@property NSTextField *contextLabel;
@property NSTextField *updatedLabel;
@property UsageBar *bar;
@property NSTimer *timer;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.attributedTitle = CodexTitle(@"--%", NSColor.secondaryLabelColor);
    self.statusItem.button.toolTip = @"ChatGPT / Codex 使用量";
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(togglePopover:);
    [self buildPopover];
    [self refresh];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(screensChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}

- (void)screensChanged:(NSNotification *)notification {
    // NSStatusBar mirrors the item to every macOS menu bar. Reinsert it after
    // displays are connected/disconnected so the system refreshes every copy.
    NSAttributedString *title = self.statusItem.button.attributedTitle;
    [NSStatusBar.systemStatusBar removeStatusItem:self.statusItem];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.attributedTitle = title;
    self.statusItem.button.toolTip = @"ChatGPT / Codex 使用量";
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(togglePopover:);
    [self refresh];
}

- (NSTextField *)label:(NSString *)text size:(CGFloat)size color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:text];
    label.font = ModernFont(size, NSFontWeightRegular);
    if (color) label.textColor = color;
    return label;
}

- (void)buildPopover {
    NSTextField *title = [self label:@"ChatGPT / Codex 使用量" size:15 color:nil];
    title.font = ModernFont(16, NSFontWeightBold);
    title.textColor = NSColor.systemBlueColor;
    self.percentLabel = [self label:@"読み込み中…" size:30 color:nil];
    self.percentLabel.font = ModernFont(30, NSFontWeightBold);
    self.periodLabel = [self label:@"" size:12 color:NSColor.secondaryLabelColor];
    self.resetLabel = [self label:@"" size:12 color:NSColor.secondaryLabelColor];
    self.tokenLabel = [self label:@"" size:12 color:nil];
    self.contextLabel = [self label:@"" size:12 color:nil];
    self.updatedLabel = [self label:@"" size:10 color:NSColor.tertiaryLabelColor];
    self.bar = [UsageBar new]; self.bar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bar.heightAnchor constraintEqualToConstant:16].active = YES;

    NSButton *refresh = [NSButton buttonWithTitle:@"更新" target:self action:@selector(refresh)];
    NSButton *quit = [NSButton buttonWithTitle:@"終了" target:NSApp action:@selector(terminate:)];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[refresh, quit]];
    buttons.spacing = 8; buttons.distribution = NSStackViewDistributionFillEqually;

    NSStackView *stack = [NSStackView stackViewWithViews:@[title, self.percentLabel, self.periodLabel, self.bar, self.resetLabel, self.tokenLabel, self.contextLabel, self.updatedLabel, buttons]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading; stack.spacing = 8;
    stack.edgeInsets = NSEdgeInsetsMake(16, 16, 16, 16);
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    NSViewController *controller = [NSViewController new];
    controller.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 320, 255)];
    [controller.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:controller.view.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:controller.view.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:controller.view.topAnchor],
        [self.bar.widthAnchor constraintEqualToConstant:288],
        [buttons.widthAnchor constraintEqualToConstant:288]
    ]];
    self.popover = [NSPopover new]; self.popover.contentViewController = controller;
    self.popover.behavior = NSPopoverBehaviorTransient;
}

- (void)togglePopover:(id)sender {
    if (self.popover.shown) [self.popover performClose:nil];
    else { [self refresh]; [self.popover showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSRectEdgeMinY]; }
}

- (NSDictionary *)latestEvent {
    NSURL *root = [NSFileManager.defaultManager.homeDirectoryForCurrentUser URLByAppendingPathComponent:@".codex/sessions"];
    NSArray *keys = @[NSURLContentModificationDateKey, NSURLIsRegularFileKey];
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtURL:root includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    NSMutableArray *files = [NSMutableArray array];
    for (NSURL *url in enumerator) {
        if (![url.pathExtension isEqualToString:@"jsonl"]) continue;
        NSDate *date = nil; [url getResourceValue:&date forKey:NSURLContentModificationDateKey error:nil];
        if (date) [files addObject:@{ @"url": url, @"date": date }];
    }
    [files sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [b[@"date"] compare:a[@"date"]]; }];
    for (NSDictionary *file in [files subarrayWithRange:NSMakeRange(0, MIN(12, files.count))]) {
        NSString *text = [NSString stringWithContentsOfURL:file[@"url"] encoding:NSUTF8StringEncoding error:nil];
        NSArray *lines = [text componentsSeparatedByString:@"\n"];
        for (NSString *line in lines.reverseObjectEnumerator) {
            NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *event = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSDictionary *payload = event[@"payload"];
            if ([payload[@"type"] isEqualToString:@"token_count"]) return @{ @"payload": payload, @"date": file[@"date"] };
        }
    }
    return nil;
}

- (void)refresh {
    NSDictionary *event = [self latestEvent];
    if (!event) { self.statusItem.button.attributedTitle = CodexTitle(@"--%", NSColor.secondaryLabelColor); self.percentLabel.stringValue = @"データなし"; self.percentLabel.textColor = NSColor.secondaryLabelColor; self.periodLabel.stringValue = @"Codexでメッセージを送ると表示されます"; return; }
    NSDictionary *payload = event[@"payload"];
    NSDictionary *limits = payload[@"rate_limits"];
    NSDictionary *window = limits[@"primary"] ?: limits[@"secondary"];
    double percent = [window[@"used_percent"] doubleValue];
    self.bar.value = percent;
    self.statusItem.button.attributedTitle = CodexTitle([NSString stringWithFormat:@"%.0f%%", percent], UsageColor(percent));
    self.percentLabel.stringValue = [NSString stringWithFormat:@"%.0f%% 使用", percent];
    self.percentLabel.textColor = UsageColor(percent);
    NSInteger minutes = [window[@"window_minutes"] integerValue];
    NSString *plan = [limits[@"plan_type"] capitalizedString] ?: @"";
    NSString *duration = minutes % 10080 == 0 ? [NSString stringWithFormat:@"%ld週間", (long)(minutes / 10080)] : (minutes % 1440 == 0 ? [NSString stringWithFormat:@"%ld日間", (long)(minutes / 1440)] : [NSString stringWithFormat:@"%ld時間", (long)(minutes / 60)]);
    self.periodLabel.stringValue = [NSString stringWithFormat:@"%@・%@の利用枠", plan, duration];
    NSTimeInterval reset = [window[@"resets_at"] doubleValue];
    self.resetLabel.stringValue = reset ? [NSString stringWithFormat:@"リセット: %@", [self formatted:[NSDate dateWithTimeIntervalSince1970:reset]]] : @"リセット時刻: --";
    NSDictionary *info = payload[@"info"];
    NSDictionary *usage = info[@"total_token_usage"];
    long long total = [usage[@"total_tokens"] longLongValue];
    long long context = [info[@"model_context_window"] longLongValue];
    self.tokenLabel.stringValue = [NSString stringWithFormat:@"累計トークン  %lld", total];
    self.contextLabel.stringValue = [NSString stringWithFormat:@"現在の文脈    %.0f%%（上限 %lld）", context ? 100.0 * total / context : 0, context];
    self.updatedLabel.stringValue = [NSString stringWithFormat:@"最終記録: %@", [self formatted:event[@"date"]]];
}

- (NSString *)formatted:(NSDate *)date {
    static NSDateFormatter *formatter; static dispatch_once_t once;
    dispatch_once(&once, ^{ formatter = [NSDateFormatter new]; formatter.locale = [NSLocale localeWithLocaleIdentifier:@"ja_JP"]; formatter.dateFormat = @"M月d日 H:mm"; });
    return [formatter stringFromDate:date];
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool { NSApplication *app = NSApplication.sharedApplication; AppDelegate *delegate = [AppDelegate new]; app.delegate = delegate; [app run]; }
    return 0;
}
