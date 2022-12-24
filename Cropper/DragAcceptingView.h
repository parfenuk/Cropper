//
//  DragAcceptingView.h
//  Cropper
//
//  Created by Miraslau Parafeniuk on 22/12/2022.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DragAcceptingView : NSView

@property (nonatomic, weak) NSViewController *parentController;

@end

NS_ASSUME_NONNULL_END
