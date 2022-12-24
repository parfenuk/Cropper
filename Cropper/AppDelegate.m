//
//  AppDelegate.m
//  Cropper
//
//  Created by Miraslau Parafeniuk on 17.02.22.
//

#import "AppDelegate.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    
    if (flag) [sender.windows.firstObject orderFront:self];
    else [sender.windows.firstObject makeKeyAndOrderFront:self];
    
    return YES;
}

@end
