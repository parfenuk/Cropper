//
//  ViewController.m
//  Cropper
//
//  Created by Miraslau Parafeniuk on 17.02.22.
//

#import "ViewController.h"

#define FM [NSFileManager defaultManager]
#define BASE_PATH @"/Users/Miroslav/Music/For Quiz/"
#define StrFmt NSString stringWithFormat
#define sPlus stringByAppendingString
#define STEP 0.05

@implementation ViewController

@synthesize audioPlayer, timer, slFull, slCropped, btnPlay1, btnPlay2, tfDurationTime, tfCurrentTime, tfFrom, tfTo, tfSaveStatus, tfFolderName, tfFileName;

NSString *open_panel_folder_path; // last successfully chosen from open panel
NSString *full_file_path;
int active_channel = 0; // playing first slider or the second one
double second_player_offset; // in seconds

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)activate:(int)k {
    
    if (k == 1) {
        btnPlay1.enabled = YES;
        slFull.enabled = YES;
        btnPlay2.enabled = NO;
        slCropped.enabled = NO;
        
        slFull.minValue = 0;
        slFull.maxValue = audioPlayer.duration;
        audioPlayer.currentTime = slFull.minValue;
        tfCurrentTime.stringValue = [StrFmt:@"%.2f",slFull.minValue];
        tfDurationTime.stringValue = [StrFmt:@"%.2f",audioPlayer.duration];
    }
    else { // k == 2
        double d1 = tfFrom.doubleValue, d2 = tfTo.doubleValue;
        if (!(0 <= d1 && d1 < d2 && d2 <= audioPlayer.duration)) return;
        
        btnPlay1.enabled = NO;
        slFull.enabled = NO;
        btnPlay2.enabled = YES;
        slCropped.enabled = YES;
        
        slCropped.minValue = d1;
        slCropped.maxValue = d2;
        audioPlayer.currentTime = slCropped.minValue;
        tfCurrentTime.stringValue = @"0.00";
        tfDurationTime.stringValue = [StrFmt:@"%.2f",d2-d1];
    }
}

- (void)loadAudioFile:(NSString *)path {
    
    NSError *err;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:&err];
    if (err) NSLog(@"Failed to create audio player, %@",err.description);
    else { // UI preparation
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updatePlaybackInfo) userInfo:nil repeats:YES];
        tfFrom.stringValue = @"";
        tfTo.stringValue = @"";
        [self activate:1];
    }
}

- (void)updatePlaybackInfo {
    
    if (slFull.enabled) {
        slFull.doubleValue = audioPlayer.currentTime;
        tfCurrentTime.stringValue = [StrFmt:@"%.2f",audioPlayer.currentTime];
    }
    if (slCropped.enabled) {
        slCropped.doubleValue = audioPlayer.currentTime;
        tfCurrentTime.stringValue = [StrFmt:@"%.2f",slCropped.doubleValue - slCropped.minValue];
        if (slCropped.doubleValue == slCropped.maxValue) [audioPlayer pause];
    }
}

- (IBAction)valueChanged:(NSSlider *)sender {
    
    if (sender == slFull) {
        audioPlayer.currentTime = slFull.doubleValue;
        tfCurrentTime.stringValue = [StrFmt:@"%.2f",audioPlayer.currentTime];
    }
    else if (sender == slCropped) {
        audioPlayer.currentTime = slCropped.doubleValue;
        tfCurrentTime.stringValue = [StrFmt:@"%.2f",slCropped.doubleValue - slCropped.minValue];
        if (slCropped.doubleValue == slCropped.maxValue) [audioPlayer pause];
    }
}

- (IBAction)actPlayOrPause:(NSButton *)sender {
    
    if (audioPlayer.isPlaying) [audioPlayer pause];
    else [audioPlayer play];
}

- (IBAction)actCrop:(NSButton *)sender {
    
    if (audioPlayer.isPlaying) [audioPlayer stop];
    if (btnPlay1.enabled) [self activate:2];
    else [self activate:1];
}

- (IBAction)actOpen:(NSButton *)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSModalResponse k = [panel runModal];
    if (k == NSModalResponseOK) {
        //NSLog(@"%@\n%@",panel.URL,panel.URL.absoluteString);
        full_file_path = panel.URL.absoluteString;
        int slash = (int)[full_file_path rangeOfString:@"/" options: NSBackwardsSearch].location;
        int dot = (int)[full_file_path rangeOfString:@"." options: NSBackwardsSearch].location;
        open_panel_folder_path = [full_file_path substringToIndex:slash];
        NSMutableString *songName = [[full_file_path substringWithRange:NSMakeRange(slash+1, dot-slash-1)] mutableCopy];
        [songName replaceOccurrencesOfString:@"%20" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,songName.length)];
        tfFolderName.stringValue = songName;
        tfFileName.stringValue = songName;
        [self loadAudioFile:full_file_path];
    }
}

- (IBAction)actSave:(NSButton *)sender {
    
    NSMutableString *folderPath = [[[StrFmt:@"%@/%@",open_panel_folder_path,tfFolderName.stringValue] substringFromIndex:7] mutableCopy]; // remove "file://" prefix
    [folderPath replaceOccurrencesOfString:@"%20" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,folderPath.length)];
    if (![FM fileExistsAtPath:folderPath]) {
        NSError *err;
        [FM createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&err];
        if (err) { // TODO: all errors are on screen
            [self reportStatus:@"Folder creation error"];
            NSLog(@"%@", err.description);
            return;
        }
    }
    NSString *writing_path = (sender.tag == 1 ?  [StrFmt:@"%@/%@.m4a",folderPath,tfFileName.stringValue] : [StrFmt:@"%@/%@_A.m4a",folderPath,tfFileName.stringValue]);
    NSURL *inputUrl = [NSURL URLWithString:full_file_path];
    NSURL *outputUrl = [NSURL fileURLWithPath:writing_path];
    if ([FM fileExistsAtPath:writing_path]) {
        [FM removeItemAtPath:writing_path error:nil];
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputUrl options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@YES}];
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    session.outputURL = outputUrl;
    session.outputFileType = AVFileTypeAppleM4A;
    session.timeRange = CMTimeRangeMake(CMTimeMake(tfFrom.doubleValue*100, 100), CMTimeMake((tfTo.doubleValue - tfFrom.doubleValue)*100, 100));
    [session exportAsynchronouslyWithCompletionHandler:^{
        switch (session.status) {
            case AVAssetExportSessionStatusCompleted: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reportStatus:@"Saved successfully"];
                });
                break;
            }
            case AVAssetExportSessionStatusFailed: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reportStatus:@"Failed to save"];
                });
                NSLog(@"%@", session.error.description);
                break;
            }
            default: break;
        }
    }];
}

- (IBAction)actSetTime:(NSButton *)sender {
    
    if      (sender.tag == 1) tfFrom.stringValue = [StrFmt:@"%.2f", tfCurrentTime.doubleValue];
    else if (sender.tag == 2) tfTo.stringValue   = [StrFmt:@"%.2f", tfCurrentTime.doubleValue];
}

- (IBAction)actChangeTimeRange:(NSButton *)sender {
    
    double d1 = tfFrom.doubleValue, d2 = tfTo.doubleValue;
    if      (sender.tag == 1) d1 += STEP;
    else if (sender.tag == 2) d1 -= STEP;
    else if (sender.tag == 3) d2 += STEP;
    else if (sender.tag == 4) d2 -= STEP;
    if (btnPlay2.enabled) tfDurationTime.stringValue = [StrFmt:@"%.2f",d2-d1];
    tfFrom.stringValue = [StrFmt:@"%.2f", d1];
    tfTo.stringValue   = [StrFmt:@"%.2f", d2];
    slCropped.minValue = d1;
    slCropped.maxValue = d2;
}

- (void)reportStatus:(NSString *)statusString {
    
    tfSaveStatus.stringValue = statusString;
    [tfSaveStatus performSelector:@selector(setStringValue:) withObject:@"" afterDelay:5.0];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
