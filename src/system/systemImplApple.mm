#import "system.h"

#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <sys/sysctl.h>

#import "SettingsMenuController.h"

std::string systemImpl::getLanguage()
{
    @autoreleasepool {
        NSString *languageCode = NSLocale.currentLocale.languageCode;
        NSString *countryCode = NSLocale.currentLocale.countryCode;
        return std::string([NSString stringWithFormat:@"%@_%@", languageCode, countryCode].UTF8String);
    }
}

std::string systemImpl::getUserName()
{
    @autoreleasepool {
        NSString *name = NSUserName();
        return std::string(name.UTF8String);
    }
}

std::string systemImpl::getUserFullName()
{
    NSString *name = NSFullUserName();

    if ([name isEqualToString:@""])
        name = NSUserName();

    return std::string(name.UTF8String);
}

int systemImpl::getScalingFactor()
{
    return NSApplication.sharedApplication.mainWindow.backingScaleFactor;
}

bool systemImpl::isWine()
{
    // Always false on Mac builds, see systemImpl.cpp
    return false;
}

bool systemImpl::isRosetta()
{
    int translated = 0;
    size_t size = sizeof(translated);

    int result = sysctlbyname("sysctl.proc_translated", &translated, &size, NULL, 0);

    if (result == -1)
        return false;

    return translated;
}

systemImpl::WineHostType systemImpl::getRealHostType()
{
    return WineHostType::Mac;
}

// Constant, if it's not nil then just raise the menu instead.
SettingsMenu *smenu = nil;

void openSettingsWindow()
{
    if (smenu == nil) {
        smenu = [SettingsMenu openWindow];
        return;
    }
    [smenu raise];
}

bool isMetalSupported()
{
    if (@available(macOS 10.13.0, *))
        return MTLCreateSystemDefaultDevice() != nil;
    return false;
}

std::string getPlistValue(const char *key)
{
    @autoreleasepool {
        NSString *hash = [[NSBundle mainBundle] objectForInfoDictionaryKey:@(key)];
        if (hash != nil)
            return std::string(hash.UTF8String);
        return "";
    }
}
