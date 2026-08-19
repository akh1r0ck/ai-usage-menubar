#import <Cocoa/Cocoa.h>
#import "UsageUI.h"

int main(int argc,const char *argv[]) { @autoreleasepool {
    if(argc!=3)return 2;
    NSApplication *app=NSApplication.sharedApplication;
    NSString *theme=@(argv[2]);UsageSettingsStore.sharedStore.theme=theme;UsageApplyTheme();
    UsageSettingsWindowController *controller=[[UsageSettingsWindowController alloc]initWithService:UsageServiceCodex];
    NSTabView *tabs=(NSTabView *)controller.window.contentView.subviews.firstObject;
    [tabs selectTabViewItemAtIndex:1];
    tabs.tabViewType=NSNoTabsNoBorder;
    [controller.window.contentView layoutSubtreeIfNeeded];
    NSView *view=controller.window.contentView;view.wantsLayer=YES;NSAppearance *appearance=app.effectiveAppearance;[appearance performAsCurrentDrawingAppearance:^{view.layer.backgroundColor=NSColor.windowBackgroundColor.CGColor;}];NSRect bounds=view.bounds;
    NSBitmapImageRep *rep=[view bitmapImageRepForCachingDisplayInRect:bounds];
    [view cacheDisplayInRect:bounds toBitmapImageRep:rep];
    NSData *png=[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    BOOL written=[png writeToFile:@(argv[1]) atomically:YES];NSString *suite=NSProcessInfo.processInfo.environment[@"AI_USAGE_DEFAULTS_SUITE"];if(suite)[NSUserDefaults.standardUserDefaults removePersistentDomainForName:suite];return written?0:1;
} }
