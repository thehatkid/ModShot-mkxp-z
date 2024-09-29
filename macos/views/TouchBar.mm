//
//  TouchBar.mm
//  mkxp-z
//
//  Created by ゾロア on 1/14/22.
//

#import <AppKit/AppKit.h>
#import <SDL_syswm.h>
#import <SDL_events.h>
#import <SDL_timer.h>
#import <SDL_scancode.h>

#import "TouchBar.h"
#import "config.h"
#import "eventthread.h"
#import "sharedstate.h"
#import "display/graphics.h"

API_AVAILABLE(macos(10.12.2))
MKXPZTouchBar *_sharedTouchBar;

@interface MKXPZTouchBar ()
{
    NSWindow *_parent;

    NSTextField *fpsLabel;
    NSSegmentedControl *functionKeys;
}

@property (retain, nonatomic) NSString *gameTitle;

-(void)setupTouchBarLayout:(bool)showSettings resetButton:(bool)showReset;
-(void)updateFPSDisplay:(uint32_t)value;
@end

@implementation MKXPZTouchBar

@synthesize gameTitle;

-(instancetype)init
{
    self = [super init];
    self.delegate = self;
    return self;
}

+(MKXPZTouchBar *)sharedTouchBar
{
    if (!_sharedTouchBar)
        _sharedTouchBar = [MKXPZTouchBar new];
    return _sharedTouchBar;
}

-(NSWindow *)parent
{
    return _parent;
}

-(NSWindow *)setParent:(NSWindow *)window
{
    _parent = window;
    return _parent;
}

-(void)setupTouchBarLayout:(bool)showSettings resetButton:(bool)showReset
{
    if (@available(macOS 10.12.2, *)) {
        if (!functionKeys) {
            functionKeys = [NSSegmentedControl segmentedControlWithLabels:@[@"F5", @"F6", @"F7", @"F8", @"F9"] trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(simulateFunctionKey)];
            functionKeys.segmentStyle = NSSegmentStyleSeparated;
        }

        if (!fpsLabel) {
            fpsLabel = [NSTextField labelWithString:@"Loading..."];
            fpsLabel.alignment = (showSettings || showReset) ? NSTextAlignmentCenter : NSTextAlignmentRight;
            fpsLabel.font = [NSFont labelFontOfSize:NSFont.smallSystemFontSize];
        }

        NSMutableArray *items = [NSMutableArray arrayWithArray:@[@"function", NSTouchBarItemIdentifierFlexibleSpace]];

        if (showSettings || showReset) {
            [items addObject:@"icon"];
            [items addObject:@"fps"];
            [items addObject:NSTouchBarItemIdentifierFlexibleSpace];

            if (showSettings)
                [items addObject:@"settings"];

            if (showReset)
                [items addObject:@"reset"];
        } else {
            [items addObject:@"fps"];
            [items addObject:@"icon"];
        }

        self.defaultItemIdentifiers = items;
    }
}

-(void)updateFPSDisplay:(uint32_t)value
{
    if (fpsLabel) {
        int targetFrameRate = shState->graphics().getFrameRate();
        int percentage = (int)((float)value / (float)targetFrameRate * 100);

        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                self->fpsLabel.stringValue = [NSString stringWithFormat:@"%@\n%i FPS (%i%%)", self.gameTitle, value, percentage];
            }
        });
    }
}

-(NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.12.2)
{
    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];

    if ([identifier isEqualToString:@"settings"]) {
        item.view = [NSButton buttonWithImage:[NSImage imageNamed:@"settings"] target:self action:@selector(openSettingsMenu)];
    } else if ([identifier isEqualToString:@"reset"]) {
        item.view = [NSButton buttonWithImage:[NSImage imageNamed:@"reset"] target:self action:@selector(simulateF12)];
        ((NSButton *)item.view).bezelColor = [NSColor colorWithRed:0xD7 / 255.0 green:0x00 / 255.0 blue:0x15 / 255.0 alpha:1.0];
    } else if ([identifier isEqualToString:@"icon"]) {
        NSImage *appIcon = [[NSApplication sharedApplication] applicationIconImage];
        appIcon.size = {30, 30};
        item.view = [NSImageView imageViewWithImage:appIcon];
    } else if ([identifier isEqualToString:@"fps"]) {
        item.view = fpsLabel;
    } else if ([identifier isEqualToString:@"function"]) {
        item.view = functionKeys;
    } else {
        item = nil;
        return nil;
    }

    return item;
}

-(void)openSettingsMenu
{
    shState->eThread().requestSettingsMenu();
}

-(void)simulateKeyDown:(SDL_Scancode)scancode
{
    SDL_Event e;
    e.key.type = SDL_KEYDOWN;
    e.key.state = SDL_PRESSED;
    e.key.timestamp = SDL_GetTicks();
    e.key.keysym.scancode = scancode;
    e.key.keysym.sym = SDL_GetKeyFromScancode(scancode);
    e.key.windowID = 1;

    SDL_PushEvent(&e);
}

-(void)simulateKeyUp:(SDL_Scancode)scancode
{
    SDL_Event e;
    e.key.type = SDL_KEYUP;
    e.key.state = SDL_RELEASED;
    e.key.timestamp = SDL_GetTicks();
    e.key.keysym.scancode = scancode;
    e.key.keysym.sym = SDL_GetKeyFromScancode(scancode);
    e.key.windowID = 1;

    SDL_PushEvent(&e);
}

-(void)simulateKeypress:(SDL_Scancode)scancode
{
    [self simulateKeyDown:scancode];
    double afr = shState->graphics().averageFrameRate();
    afr = (afr >= 1) ? afr : 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000000 * afr), dispatch_get_main_queue(), ^{
        [self simulateKeyUp:scancode];
    });
}

-(void)simulateF12
{
    [self simulateKeypress:SDL_SCANCODE_F12];
}

-(void)simulateFunctionKey
{
    [self simulateKeypress:(SDL_Scancode)(SDL_SCANCODE_F5 + functionKeys.selectedSegment)];
}
@end

void initTouchBar(SDL_Window *win, Config &conf)
{
    if (@available(macOS 10.12.2, *)) {
        SDL_SysWMinfo wm {};
        SDL_GetWindowWMInfo(win, &wm);

        MKXPZTouchBar *tb = MKXPZTouchBar.sharedTouchBar;
        wm.info.cocoa.window.touchBar = tb;
        tb.parent = wm.info.cocoa.window;
        tb.gameTitle = @(conf.game.title.c_str());

        [tb setupTouchBarLayout:conf.enableSettings resetButton:conf.enableReset];
    }
}

void updateTouchBarFPSDisplay(uint32_t value)
{
    if (@available(macOS 10.12.2, *))
        [MKXPZTouchBar.sharedTouchBar updateFPSDisplay:value];
}
