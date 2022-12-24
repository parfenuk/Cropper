//
//  ViewController.h
//  Cropper
//
//  Created by Miraslau Parafeniuk on 17.02.22.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "DragAcceptingView.h"

@interface ViewController : NSViewController <NSDraggingDestination>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) IBOutlet DragAcceptingView *underlayView;
@property (nonatomic, strong) IBOutlet NSSlider *slFull;
@property (nonatomic, strong) IBOutlet NSSlider *slCropped;
@property (nonatomic, strong) IBOutlet NSSlider *slVolume;
@property (nonatomic, strong) IBOutlet NSSlider *slOutputChannelVolume;
@property (nonatomic, strong) IBOutlet NSButton *btnPlay1;
@property (nonatomic, strong) IBOutlet NSButton *btnPlay2;
@property (nonatomic, strong) IBOutlet NSTextField *tfDurationTime;
@property (nonatomic, strong) IBOutlet NSTextField *tfCurrentTime;
@property (nonatomic, strong) IBOutlet NSTextField *tfFrom;
@property (nonatomic, strong) IBOutlet NSTextField *tfTo;
@property (nonatomic, strong) IBOutlet NSTextField *tfSaveStatus;
@property (nonatomic, strong) IBOutlet NSTextField *tfFolderName; // folder where to save
@property (nonatomic, strong) IBOutlet NSTextField *tfFileName; // how to name for saving

- (void)didLoadFileFromPath:(NSString *)path;

@end

