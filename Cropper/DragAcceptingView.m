//
//  DragAcceptingView.m
//  Cropper
//
//  Created by Miraslau Parafeniuk on 22/12/2022.
//

#import "DragAcceptingView.h"
#import "ViewController.h"

@implementation DragAcceptingView

@synthesize parentController;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self registerForDraggedTypes:@[ NSPasteboardTypeFileURL ]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    
    BOOL can_read = [sender.draggingPasteboard canReadObjectForClasses:@[NSURL.class] options:nil];
    return can_read ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    NSURL *url = (NSURL *)[sender.draggingPasteboard readObjectsForClasses:@[ NSURL.class ] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @(true)}].firstObject;
    
    if ([parentController isKindOfClass:[ViewController class]]) {
        [(ViewController *)parentController didLoadFileFromPath:url.path];
    }
    
    return true;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
