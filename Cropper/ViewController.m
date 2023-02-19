//
//  ViewController.m
//  Cropper
//
//  Created by Miraslau Parafeniuk on 17.02.22.
//

#import "ViewController.h"

#define FM [NSFileManager defaultManager]
#define StrFmt NSString stringWithFormat
#define STEP 0.05

@implementation ViewController

@synthesize audioPlayer, timer, underlayView, slFull, slCropped, slVolume, slOutputChannelVolume, btnPlay1, btnPlay2, tfDurationTime, tfCurrentTime, tfFrom, tfTo, tfSaveStatus, tfFolderName, tfFileName;

NSString *open_panel_folder_path; // last successfully chosen from open panel
NSString *full_file_path;
int active_channel = 0; // playing first slider or the second one
double second_player_offset; // in seconds

- (NSString *)roundedDown:(double)d precision:(int)k {
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.decimalSeparator = @".";
    formatter.minimumFractionDigits = k;
    formatter.maximumFractionDigits = k;
    formatter.roundingMode = NSNumberFormatterRoundFloor;

    return [formatter stringFromNumber:@(d)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    underlayView.parentController = self;
}

- (void)activate:(NSSlider *)sliderToPlay {
    
    if (sliderToPlay == slFull) {
        btnPlay1.enabled = YES;
        slFull.enabled = YES;
        btnPlay2.enabled = NO;
        slCropped.enabled = NO;
        
        slFull.minValue = 0;
        slFull.maxValue = audioPlayer.duration;
        audioPlayer.currentTime = slFull.minValue;
        tfCurrentTime.stringValue = @"0.00";
        tfDurationTime.stringValue = [self roundedDown:slFull.maxValue precision:3];
    }
    else { // sliderToPlay == slCropped
        double d1 = tfFrom.doubleValue, d2 = tfTo.doubleValue;
        if (d1 < 0) d1 = 0;
        if (d2 == 0 || d2 > audioPlayer.duration) d2 = audioPlayer.duration;
        if (d1 >= d2) return;
        
        btnPlay1.enabled = NO;
        slFull.enabled = NO;
        btnPlay2.enabled = YES;
        slCropped.enabled = YES;
        
        slCropped.minValue = d1;
        slCropped.maxValue = d2;
        audioPlayer.currentTime = slCropped.minValue;
        tfCurrentTime.stringValue = @"0.00";
        tfDurationTime.stringValue = [self roundedDown:d2-d1 precision:3];
        tfFrom.stringValue = [self roundedDown:d1 precision:2];
        tfTo.stringValue   = [self roundedDown:d2 precision:2];
    }
}

- (void)didLoadFileFromPath:(NSString *)path {
    
    full_file_path = path;
    NSUInteger slash = [full_file_path rangeOfString:@"/" options: NSBackwardsSearch].location;
    NSUInteger dot = [full_file_path rangeOfString:@"." options: NSBackwardsSearch].location;
    open_panel_folder_path = [full_file_path substringToIndex:slash];
    NSMutableString *songName = [full_file_path substringWithRange:NSMakeRange(slash+1, dot-slash-1)].mutableCopy;
    tfFolderName.stringValue = tfFileName.stringValue = songName;
    
    [self loadAudioFile];
}

- (void)loadAudioFile {
    
    NSError *err;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:full_file_path] error:&err];
    audioPlayer.volume = slVolume.doubleValue / 100;
    if (err) [self reportStatus:err.description];
    else { // UI preparation
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updatePlaybackInfo) userInfo:nil repeats:YES];
        tfFrom.stringValue = @"";
        tfTo.stringValue = @"";
        [self activate:slFull];
    }
}

- (void)updatePlaybackInfo {
    
    if (slFull.enabled) {
        slFull.doubleValue = audioPlayer.currentTime;
        tfCurrentTime.stringValue = [self roundedDown:audioPlayer.currentTime precision:2];
    }
    else if (slCropped.enabled) {
        slCropped.doubleValue = audioPlayer.currentTime;
        tfCurrentTime.stringValue = [self roundedDown:slCropped.doubleValue - slCropped.minValue precision:2];
        if (slCropped.doubleValue == slCropped.maxValue) [audioPlayer pause];
    }
}

- (IBAction)valueChanged:(NSSlider *)sender {
    
    if (sender == slFull) {
        audioPlayer.currentTime = slFull.doubleValue;
        tfCurrentTime.stringValue = [self roundedDown:audioPlayer.currentTime precision:2];
    }
    else if (sender == slCropped) {
        audioPlayer.currentTime = slCropped.doubleValue;
        tfCurrentTime.stringValue = [self roundedDown:slCropped.doubleValue - slCropped.minValue precision:2];
        if (slCropped.doubleValue == slCropped.maxValue) [audioPlayer pause];
    }
    else if (sender == slVolume) {
        audioPlayer.volume = slVolume.doubleValue / 100;
    }
    else if (sender == slOutputChannelVolume) {
        audioPlayer.volume = slOutputChannelVolume.doubleValue / 100;
        slVolume.doubleValue = slOutputChannelVolume.doubleValue;
    }
}

- (IBAction)actPlayOrPause:(NSButton *)sender {
    
    if (audioPlayer.isPlaying) [audioPlayer pause];
    else [audioPlayer play];
}

- (IBAction)actCrop:(NSButton *)sender {
    
    if (audioPlayer.isPlaying) [audioPlayer stop];
    if (btnPlay1.enabled) [self activate:slCropped];
    else [self activate:slFull];
}

- (IBAction)actOpen:(NSButton *)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSModalResponse response = [panel runModal];
    
    if (response == NSModalResponseOK) {
        //NSLog(@"%@\n%@\n%@",panel.URL, panel.URL.absoluteString, panel.URL.path);
        if (![panel.URL.absoluteString hasPrefix:@"file://"]) {
            [self reportStatus:@"Chosen object is not from file system"];
            return;
        }
        [self didLoadFileFromPath:panel.URL.path];
    }
}

- (IBAction)actSave:(NSButton *)sender {
    
    NSMutableString *folderPath = [StrFmt:@"%@/%@",open_panel_folder_path,tfFolderName.stringValue].mutableCopy;
    if (![FM fileExistsAtPath:folderPath]) {
        NSError *err;
        [FM createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&err];
        if (err) {
            [self reportStatus:err.description];
            return;
        }
    }
    
    NSString *writing_path = (sender.tag == 1 ?  [StrFmt:@"%@/%@.m4a",folderPath,tfFileName.stringValue] : [StrFmt:@"%@/%@_A.m4a",folderPath,tfFileName.stringValue]);
    NSURL *inputUrl = [NSURL fileURLWithPath:full_file_path];
    NSURL *outputUrl = [NSURL fileURLWithPath:writing_path];
    if ([FM fileExistsAtPath:writing_path]) {
        [FM removeItemAtPath:writing_path error:nil];
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputUrl options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@YES}];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVMutableAudioMixInputParameters *volumeParam = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    volumeParam.trackID = track.trackID;
    [volumeParam setVolume:slOutputChannelVolume.doubleValue / 100 atTime:kCMTimeZero];
    audioMix.inputParameters = @[ volumeParam ];
    
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    session.outputURL = outputUrl;
    session.outputFileType = AVFileTypeAppleM4A;
    session.audioMix = audioMix;
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
                    [self reportStatus:session.error.description];
                });
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
    // TODO: use alerts and error message types instead
    tfSaveStatus.stringValue = statusString;
    [tfSaveStatus performSelector:@selector(setStringValue:) withObject:@"" afterDelay:5.0];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
