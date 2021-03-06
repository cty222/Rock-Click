//
//  MetronomeMainViewControllerIphone.m
//  Groove
//
//  Created by C-ty on 2014/8/31.
//  Copyright (c) 2014年 Cty. All rights reserved.
//

#import "MetronomeMainViewController.h"


@interface MetronomeMainViewController ()

@end

@implementation MetronomeMainViewController
{
    // Index
    int _FocusIndex;
    BOOL _IsDeleteUICellFinished;
    
    // LoopCellPlayingFlag
    METRONOME_PLAYING_MODE _PlayingMode;
    
    // Tools
    NotesTool * _NTool;
    
    
    // ========================
    // Loop
    NSTimer *PlaySoundTimer;
    
    // Loop Counter
    int _AccentCounter;
    CURRENT_PLAYING_NOTE _CurrentPlayingNoteCounter;
    int _LoopCountCounter;
    int _TimeSignatureCounter;
    BOOL _ListChangeFocusFlag;
    
    
    BOOL _IsNeedChangeToNextCell;
    //
    // ========================

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   
    [self SyncCurrentTempoListFromModel];
    
    [self SyncCurrentTempoCellDatatableWithModel];

    [self ReflashCellListAndFocusCellByCurrentData];
    
    if (self.CellParameterSettingSubController != nil)
    {
        [self.CellParameterSettingSubController MainViewWillAppear];
    }
    
    if (self.LoopAndPlayViewSubController != nil)
    {
        [self.LoopAndPlayViewSubController MainViewWillAppear];
    }
    
    if (self.SystemPageController != nil)
    {
        [self.SystemPageController MainViewWillAppear];
    }
    
    // ===================
    // Setup music by model music info
    if (gPlayMusicChannel == nil)
    {
        gPlayMusicChannel = [PlayerForSongs alloc];
    }
    
    if (self.CurrentTempoList.musicInfo == nil)
    {
        self.CurrentTempoList.musicInfo = [gMetronomeModel CreateNewMusicInfo];
        [gMetronomeModel Save];
    }
    
    [self SyncMusicInfoFromTempList];

    [self SyncMusicPropertyFromGlobalConfig];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.PlayingMode = STOP_PLAYING;
    [gPlayMusicChannel Stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self InitailzieTools];
    
    [self InitializeFlagStatus];
    
    // UI layout
    //
    
    CGRect FullViewFrame = self.FullView.frame;
    CGRect TopViewFrame = self.TopView.frame;
    CGRect BottomViewFrame = self.BottomView.frame;
    

    NSNumber * DeviceType = [GlobalConfig DeviceType];
    switch (DeviceType.intValue) {
        case IPHONE_4S:
            FullViewFrame = CGRectMake(FullViewFrame.origin.x
                                      , FullViewFrame.origin.y
                                      , FullViewFrame.size.width
                                      , IPHONE_4S_HEIGHT
                                      );
            
            TopViewFrame = CGRectMake(TopViewFrame.origin.x
                                      , TopViewFrame.origin.y
                                      , TopViewFrame.size.width
                                      , TopViewFrame.size.height - (IPHONE_5S_HEIGHT - IPHONE_4S_HEIGHT)
                                      );
            BottomViewFrame = CGRectMake(BottomViewFrame.origin.x
                                      , BottomViewFrame.origin.y  - (IPHONE_5S_HEIGHT - IPHONE_4S_HEIGHT)
                                      , BottomViewFrame.size.width
                                      , BottomViewFrame.size.height
                                      );
            break;
        case IPHONE_5S:
            break;
        default:
            break;
    }
    
    self.FullView.frame = FullViewFrame;
    self.TopView.frame = TopViewFrame;
    self.BottomView.frame = BottomViewFrame;
    
    // Initalize Sub View
    [self InitializeTopSubView];
    
    [self InitializeBottomSubView];

    // Get Control UI form sub View and initialize default data
    [self InitializeSubController];
    
    [self.CellParameterSettingSubController InitlizeCellParameterControlItems];
    
    [self.LoopAndPlayViewSubController InitlizePlayingItems];
    
    [self.LoopAndPlayViewSubController InitializeLoopControlItem];
   
    [self.SystemPageController InitializeSystemButton];
    
    
    [self GlobalEventInitialize];
    
}

- (void) GlobalEventInitialize
{
    // Change View Controller
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ChangePageToSystemView:)
                                                 name:kChangeToSystemPageView
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ChangePageToMetronomeView:)
                                                 name:kChangeBackToMetronomeView
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(VoiceStopByInterrupt:)
                                                 name:kVoiceStopByInterrupt
                                               object:nil];
}

- (void) ChangePageToSystemView:(NSNotification *)Notification
{
    [self presentViewController:[GlobalConfig SystemPageViewController] animated:YES completion:nil];
}

- (void) ChangePageToMetronomeView:(NSNotification *)Notification
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) VoiceStopByInterrupt: (NSNotification *)Notification
{
    self.PlayingMode = STOP_PLAYING;
}

- (void) InitializeSubController
{
    self.CellParameterSettingSubController = [[CellParameterSettingControl alloc] init];
    self.CellParameterSettingSubController.ParrentController = self;
    
    self.LoopAndPlayViewSubController = [[LoopAndPlayViewControl alloc] init];
    self.LoopAndPlayViewSubController.ParrentController = self;
    
    self.SystemPageController = [[SystemPageControl alloc] init];
    self.SystemPageController.ParrentController = self;
}

- (void) InitailzieTools
{
    // 2. Initialize player
    [AudioPlay AudioPlayEnable];
    
    // 3. Initilize Click Voice
    [AudioPlay ResetClickVocieList];
    
    _NTool = [[NotesTool alloc] init];
    _NTool.delegate = self;
}

- (void) InitializeFlagStatus
{
    _PlayingMode = STOP_PLAYING;
    _FocusIndex = -1;
    
    self.IsNeededToRestartMetronomeClick = NO;
}

- (void) InitializeTopSubView
{
    if (self.TopSubView == nil)
    {
        self.TopSubView = [[MetronmoneTopSubViewIphone alloc] initWithFrame:self.TopView.frame];
    }
    if (self.TopView.subviews.count != 0)
    {
        [[self.TopView subviews]
         makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    [self.TopView addSubview:self.TopSubView];

}

- (void) InitializeBottomSubView
{
    if (self.BottomSubView == nil)
    {
        CGRect SubFrame = self.BottomView.frame;
        SubFrame.origin = CGPointMake(0, 0);
        
        self.BottomSubView = [[MetronomeBottomView alloc] initWithFrame:SubFrame];
    }
    if (self.BottomView.subviews.count != 0)
    {
        [[self.BottomView subviews]
         makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }

    [self.BottomView addSubview:self.BottomSubView];
}

// ============
//
// TODO : Model Sync
//

- (void) SyncCurrentTempoListFromModel
{
    NSNumber *LastTempoListIndexUserSelected = [GlobalConfig GetLastTempoListIndexUserSelected];
    
    self.CurrentTempoList =  [gMetronomeModel PickTargetTempoListFromDataTable:LastTempoListIndexUserSelected];
   
    if (self.CurrentTempoList == nil)
    {
        NSLog(@"嚴重錯誤: Last TempoList 同步錯誤 Error!!!");

        self.CurrentTempoList = [gMetronomeModel PickTargetTempoListFromDataTable:@0];
        if (self.CurrentTempoList == nil)
        {
            NSLog(@"嚴重錯誤: TempoList 資料庫需要reset");
        }
        else
        {
            [GlobalConfig SetLastTempoListIndexUserSelected:0];
        }
    }
    
    if (self.CurrentTempoList != nil)
    {
        [self SyncMetronomePrivateProperties];
    }
}

- (void) SyncMetronomePrivateProperties
{
    if (self.CurrentTempoList == nil)
    {
        NSLog(@"Error: Using Error CurrentList is nil!!");
        [self SyncCurrentTempoListFromModel];
        return;
    }
    
    if ([self.CurrentTempoList.privateProperties.doubleValueEnable boolValue])
    {
        _CellParameterSettingSubController.BPMPicker.Mode = BPM_PICKER_DOUBLE_MODE;
    }
    else
    {
        _CellParameterSettingSubController.BPMPicker.Mode = BPM_PICKER_INT_MODE;
    }
}

- (void) SyncMusicPropertyFromGlobalConfig
{
    self.MusicProperties = [GlobalConfig GetMusicProperties];
    if (self.MusicProperties.MusicFunctionEnable)
    {
        _LoopAndPlayViewSubController.PlayMusicButton.hidden = NO;
        _LoopAndPlayViewSubController.PlayCellListButton.hidden = YES;
        
        // Sync music property
        if (self.MusicProperties.MusicHalfRateEnable)
        {
            [gPlayMusicChannel SetPlayRateToHalf];
        }
        else
        {
            [gPlayMusicChannel SetPlayRateToNormal];
        }
        
        [gPlayMusicChannel SetPlayMusicLoopingEnable: self.MusicProperties.PlayMusicLoopingEnable];
        
    }
    else
    {
        _LoopAndPlayViewSubController.PlayMusicButton.hidden = YES;
        _LoopAndPlayViewSubController.PlayCellListButton.hidden = NO;
    }
}

- (void) SyncMusicInfoFromTempList
{
    if (self.CurrentTempoList.musicInfo.persistentID != nil)
    {
        MPMediaItem *Item =  [gPlayMusicChannel GetFirstMPMediaItemFromPersistentID : self.CurrentTempoList.musicInfo.persistentID ];
        if (![gPlayMusicChannel isPlaying])
        {
            [gPlayMusicChannel PrepareMusicToplay:Item];
        }
        gPlayMusicChannel.StartTime = [self.CurrentTempoList.musicInfo.startTime floatValue];
        gPlayMusicChannel.StopTime = [self.CurrentTempoList.musicInfo.endTime floatValue];
        gPlayMusicChannel.Volume = [self.CurrentTempoList.musicInfo.volume floatValue];
    }
}

- (void) SyncCurrentTempoCellDatatableWithModel
{
    if (self.CurrentTempoList == nil)
    {
        NSLog(@"錯誤: SyncCurrentFocusCellFromCurrentTempoList CurrentTempoList == nil");
        return;
    }

    self.CurrentCellsDataTable = [gMetronomeModel FetchTempoCellFromTempoListWithSort:self.CurrentTempoList];
    if (self.CurrentCellsDataTable == nil)
    {
        self.CurrentCellsDataTable = gMetronomeModel.TempoListDataTable[0];
    }
    
    NSLog(@"%@", self.CurrentCellsDataTable);
}

- (int) GetFocusCellWithCurrentTempoList
{
    if (self.CurrentTempoList == nil)
    {
        NSLog(@"錯誤: SyncCurrentFocusCellFromCurrentTempoList CurrentTempoList == nil");
        return 0;
    }
    
    NSNumber *LastFocusCellIndex = self.CurrentTempoList.focusCellIndex;

    if (self.CurrentCellsDataTable.count > [LastFocusCellIndex intValue])
    {
        return [LastFocusCellIndex intValue];
    }
    else
    {
        return 0;
    }
}

- (void) ReflashCellListAndFocusCellByCurrentData
{
    [self.LoopAndPlayViewSubController CopyCellListToSelectBar : self.CurrentCellsDataTable];
}


//
// ============

//  =========================
//  property
//
- (BOOL) GetIsDeleteUICellFinished
{
    return _IsDeleteUICellFinished;
}

-(void) SetIsDeleteUICellFinished: (BOOL)NewValue
{
    if (_IsDeleteUICellFinished == NewValue)
    {
        return;
    }
    
    _IsDeleteUICellFinished = NewValue;
}


- (int) GetFocusIndex
{
    if (_FocusIndex >= self.CurrentCellsDataTable.count)
    {
        NSLog(@"Bug !! Controller _FocusIndex over count error" );
        _FocusIndex = (int)(self.CurrentCellsDataTable.count -1);
    }
    else if (_FocusIndex < 0)
    {
        NSLog(@"Bug !! Controller _FocusIndex lower 0 error");
        _FocusIndex = 0;
        
    }
    return _FocusIndex;
}

// 不會設下去到Bottom View UI
- (void) SetFocusIndex:(int) NewValue
{
    if (NewValue < 0
        || NewValue >= self.CurrentCellsDataTable.count
        || (self.PlayingMode == LIST_PLAYING && NewValue == _FocusIndex && !_ListChangeFocusFlag)
        )
    {
      return;
    }
    else if (_ListChangeFocusFlag)
    {
        _ListChangeFocusFlag = NO;
    }
    
    _FocusIndex = NewValue;
    
    // 同步到 Model
    self.CurrentTempoList.focusCellIndex = [NSNumber numberWithInt:_FocusIndex];
    [gMetronomeModel Save];
    
    self.CurrentCell = self.CurrentCellsDataTable[_FocusIndex];
    
    // Set BPM
    self.TopSubView.BPMPicker.Value = [self.CurrentCell.bpmValue floatValue];
    
    // Set Volume Set
    [self.CellParameterSettingSubController.VolumeSetsControl SetVolumeBarVolume:self.CurrentCell];
    
    // Set Voice
    self.CurrentVoice = [gClickVoiceList objectAtIndex:[self.CurrentCell.voiceType.sortIndex intValue]];
    [_CellParameterSettingSubController ChangeVoiceTypePickerImage:[self.CurrentCell.voiceType.sortIndex intValue]];
    
    // Set TimeSignature
    self.CurrentTimeSignature = self.CurrentCell.timeSignatureType.timeSignature;
    [self.CellParameterSettingSubController.TimeSigaturePicker setTitle:self.CurrentTimeSignature forState:UIControlStateNormal];

    // Set LoopCount
    [_CellParameterSettingSubController.LoopCellEditerView.ValueScrollView SetValueWithoutDelegate:[self.CurrentCell.loopCount intValue]];

    
    [self ResetCounter];

}

- (METRONOME_PLAYING_MODE) GetPlayingMode
{
    return _PlayingMode;
}

- (void) SetPlayingMode : (METRONOME_PLAYING_MODE) NewValue
{
    if (NewValue == _PlayingMode)
    {
        return;
    }
    
    _PlayingMode = NewValue;
    
    switch (_PlayingMode) {
        case STOP_PLAYING:
            [self StopClick];
            [self ResetCounter];

            if (self.MusicProperties.MusicFunctionEnable && self.MusicProperties.PlaySingleCellWithMusicEnable)
            {
                if (gPlayMusicChannel.isPlaying)
                {
                    [gPlayMusicChannel Stop];
                }
            }
            break;
        case SINGLE_PLAYING:
            [self StartClick];
            if (self.MusicProperties.MusicFunctionEnable && self.MusicProperties.PlaySingleCellWithMusicEnable)
            {
                if (gPlayMusicChannel.isPlaying)
                {
                    [gPlayMusicChannel Stop];
                }
                [gPlayMusicChannel Play];
            }
            break;
        case LIST_PLAYING:
            [self StartClick];
            break;
        default:
            self.PlayingMode = STOP_PLAYING;
            break;
    }
    
    [self.LoopAndPlayViewSubController ChangeButtonDisplayByPlayMode];

}
//
//  =========================



//  =========================
// delegate
//
- (void) HumanVoiceDynamicFirstBeat
{
    switch (_TimeSignatureCounter) {
        case 0:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetFirstBeatVoice]];
            break;
        case 1:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetTwoBeatVoice]];
            break;
        case 2:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetThreeBeatVoice]];
            break;
        case 3:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetFourBeatVoice]];
            break;
        case 4:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetFiveBeatVoice]];
            break;
        case 5:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetSixBeatVoice]];
            break;
        case 6:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetSevenBeatVoice]];
            break;
        case 7:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetEightBeatVoice]];
            break;
        case 8:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetNineBeatVoice]];
            break;
        case 9:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetTenBeatVoice]];
            break;
        case 10:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetElevenBeatVoice]];
            break;
        case 11:
            [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                                : [self.CurrentVoice GetTwelveBeatVoice]];
            break;
    }
}

- (void) FirstBeatFunc
{
    // Accent
    if ( _AccentCounter == 0 || _AccentCounter >= [self.CellParameterSettingSubController DecodeTimeSignatureToValue:self.CurrentTimeSignature])
    {
        [gPlayUnit playSound: [self.CurrentCell.accentVolume floatValue]/ MAX_VOLUME
                                : [self.CurrentVoice GetAccentVoice]];

        if ([self.CurrentCell.accentVolume floatValue] > 0)
        {
            [_CellParameterSettingSubController.VolumeSetsControl.AccentCircleVolumeButton TwickLing];
        }
        _AccentCounter = 0;
    }
    
    // TODO: Change Voice
    if ([@"HumanVoice" isEqualToString:NSStringFromClass([self.CurrentVoice class])])
    {
        [self HumanVoiceDynamicFirstBeat];
    }
    else
    {
        [gPlayUnit playSound: [self.CurrentCell.quarterNoteVolume floatValue] / MAX_VOLUME
                            : [self.CurrentVoice GetFirstBeatVoice]];
    }
    if ([self.CurrentCell.quarterNoteVolume floatValue] > 0)
    {
        [_CellParameterSettingSubController.VolumeSetsControl.QuarterCircleVolumeButton TwickLing];
    }
    _AccentCounter++;
}

- (void) EBeatFunc
{
    [gPlayUnit playSound: [self.CurrentCell.sixteenNoteVolume floatValue] / MAX_VOLUME
                        : [self.CurrentVoice GetEbeatVoice]];
    if ([self.CurrentCell.sixteenNoteVolume floatValue] > 0)
    {
        [_CellParameterSettingSubController.VolumeSetsControl.SixteenthNoteCircleVolumeButton TwickLing];
    }
}

- (void) AndBeatFunc
{
    [gPlayUnit playSound: [self.CurrentCell.eighthNoteVolume floatValue] / MAX_VOLUME
                        : [self.CurrentVoice GetAndBeatVoice]];
    if ([self.CurrentCell.eighthNoteVolume floatValue] > 0)
    {
        [_CellParameterSettingSubController.VolumeSetsControl.EighthNoteCircleVolumeButton TwickLing];
    }
}

- (void) ABeatFunc
{
    [gPlayUnit playSound: [self.CurrentCell.sixteenNoteVolume floatValue] / MAX_VOLUME
                        : [self.CurrentVoice GetAbeatVoice]];
    if ([self.CurrentCell.sixteenNoteVolume floatValue] > 0)
    {
        [_CellParameterSettingSubController.VolumeSetsControl.SixteenthNoteCircleVolumeButton TwickLing];
    }
}

- (void) TicBeatFunc
{
    if ([self.CurrentTempoList.privateProperties.shuffleEnable boolValue])
    {
        return;
    }
    
    [gPlayUnit playSound: [self.CurrentCell.trippleNoteVolume floatValue] / MAX_VOLUME
                        : [self.CurrentVoice GetTicbeatVoice]];
    
    if ([self.CurrentCell.trippleNoteVolume floatValue] > 0)
    {
        [_CellParameterSettingSubController.VolumeSetsControl.TrippleNoteCircleVolumeButton TwickLing];
    }
}

- (void) TocBeatFunc
{
    [gPlayUnit playSound: [self.CurrentCell.trippleNoteVolume floatValue] / MAX_VOLUME
                        : [self.CurrentVoice GetTocbeatVoice]];
    if ([self.CurrentCell.trippleNoteVolume floatValue] > 0)
    {
        [_CellParameterSettingSubController.VolumeSetsControl.TrippleNoteCircleVolumeButton TwickLing];
    }
}
//
//  =========================

//  =========================
//  Play Function
//

- (void) ChangeToNextLoopCell
{
    // Change to next
    if (self.PlayingMode == LIST_PLAYING)
    {
        int NewIndex = self.FocusIndex + 1;
        
        if (NewIndex >= self.CurrentCellsDataTable.count)
        {
            if ([self.CurrentTempoList.privateProperties.tempoListLoopingEnable boolValue])
            {
                NewIndex = 0;
                _ListChangeFocusFlag = YES;
            }
            else
            {
                self.PlayingMode = STOP_PLAYING;
                return;
            }
        }

        [self StopClick];
        self.FocusIndex = NewIndex;
        
        // 如果Count是0就跳到下一個Cell
        if ([self.CurrentCell.loopCount intValue] == 0)
        {
            [self ChangeToNextLoopCell];
            return;
        }
        
        [self.LoopAndPlayViewSubController ChangeSelectBarForcusIndex: NewIndex];
        
        [self StartClick];
    }
}

- (void) ResetCounter
{
    _IsNeedChangeToNextCell = NO;
    _LoopCountCounter = 0;
    _TimeSignatureCounter = 0;
    _AccentCounter = 0;
    _CurrentPlayingNoteCounter = NONE_CLICK;
}

//Stop click
- (void) StopClick
{
    if (PlaySoundTimer != nil)
    {
        [PlaySoundTimer invalidate];
        PlaySoundTimer = nil;
    }
}

//Start click
- (void) StartClick
{
    //重要!! 只要被改過值都會被設成YES.
    self.IsNeededToRestartMetronomeClick = NO;

    if (PlaySoundTimer != nil) {
        [self StopClick];
        [self ResetCounter];
    }
    
    if (self.PlayingMode == LIST_PLAYING)
    {
        if (_LoopCountCounter >= [self.CurrentCell.loopCount intValue])
        {
            [self ChangeToNextLoopCell];
            // 最後一次只有delay
            // 沒有聲音
            return;
        }
    }
    
    if (_CurrentPlayingNoteCounter == NONE_CLICK)
    {
        _CurrentPlayingNoteCounter = FIRST_CLICK;
    }
    
    // 因為Timer的特性是先等再做
    // 所以必須要調整成先開始一次與最後多等一次
    [self MetronomeTicker: nil];
    
    float CurrentBPMValue = [self.CurrentCell.bpmValue floatValue];
    

    if (_CellParameterSettingSubController.BPMPicker.Mode == BPM_PICKER_INT_MODE)
    {
        NSLog(@"CurrentBPMValue %f", CurrentBPMValue);

        NSLog(@"ROUND_NO_DECOMAL_FROM_DOUBLE %f", ROUND_NO_DECOMAL_FROM_DOUBLE(CurrentBPMValue));

        NSLog(@"BPM_TO_TIMER_VALUE %f", BPM_TO_TIMER_VALUE(ROUND_NO_DECOMAL_FROM_DOUBLE(CurrentBPMValue)));
        PlaySoundTimer = [NSTimer scheduledTimerWithTimeInterval:BPM_TO_TIMER_VALUE(
                                                                ROUND_NO_DECOMAL_FROM_DOUBLE(CurrentBPMValue))
                                                          target:self
                                                        selector:@selector(MetronomeTicker:)
                                                        userInfo:nil
                                                         repeats:YES];
#if CTY_DEBUG
        NSLog(@"CurrentBPMValue %f", CurrentBPMValue);
        NSLog(@"BPM_TO_TIMER_VALUE %f", BPM_TO_TIMER_VALUE(                                                          ROUND_NO_DECOMAL_FROM_DOUBLE(CurrentBPMValue)));
#endif

    }
    else
    {
        PlaySoundTimer = [NSTimer scheduledTimerWithTimeInterval:BPM_TO_TIMER_VALUE(ROUND_ONE_DECOMAL_FROM_DOUBLE(CurrentBPMValue))
                                                          target:self
                                                        selector:@selector(MetronomeTicker:)
                                                        userInfo:nil
                                                         repeats:YES];
#if CTY_DEBUG
        NSLog(@"CurrentBPMValue %f", CurrentBPMValue);
        NSLog(@"BPM_TO_TIMER_VALUE %f", BPM_TO_TIMER_VALUE(                                                          ROUND_ONE_DECOMAL_FROM_DOUBLE(CurrentBPMValue)));
#endif
    }

}

- (void) MetronomeTicker: (NSTimer *) ThisTimer
{
    if (self.PlayingMode == STOP_PLAYING)
    {
        [self ResetCounter];
        [self StopClick];
        [ThisTimer invalidate];
        return;
    }

    // 必須要完整的delay
    // 所以是最後一次跑完, 再進來才換.
    if(_IsNeedChangeToNextCell)
    {
        _IsNeedChangeToNextCell = NO;
        [self ChangeToNextLoopCell];
        [ThisTimer invalidate];
        return;
    }
    
    NSLog(@"_CurrentPlayingNoteCounter %d", _CurrentPlayingNoteCounter);

    
    // Play function
    [self TriggerMetronomeSounds];
    
    [self AddMetronomeCounter];
    
    if ([self IsLoopCounterIsLargerThenSetupValue])
    {
        _IsNeedChangeToNextCell = YES;
    }
    
    [self RestartClickIfBPMValueBeSetWhenPlaying];
}

- (void) AddMetronomeCounter
{
    // Count script
    _CurrentPlayingNoteCounter++;
    
    if (_CurrentPlayingNoteCounter >= RESET_CLICK)
    {
        _CurrentPlayingNoteCounter = FIRST_CLICK;
        
        _TimeSignatureCounter++;
        if (_TimeSignatureCounter >= [self.CellParameterSettingSubController DecodeTimeSignatureToValue:self.CurrentTimeSignature])
        {
            _TimeSignatureCounter = 0;
            if (self.PlayingMode >= LIST_PLAYING)
            {
                _LoopCountCounter++;
            }
        }
    }
}

- (BOOL) IsLoopCounterIsLargerThenSetupValue
{
    if (self.PlayingMode == LIST_PLAYING)
    {
        if (_LoopCountCounter >= [self.CurrentCell.loopCount intValue])
        {
            return YES;
        }
    }
    
    return NO;
}

- (void) RestartClickIfBPMValueBeSetWhenPlaying
{
    if(self.IsNeededToRestartMetronomeClick && self.PlayingMode != STOP_PLAYING)
    {
        [self StopClick];
        [self StartClick];
    }
}

- (void) TriggerMetronomeSounds
{
    [NotesTool NotesFunc:_CurrentPlayingNoteCounter :_NTool];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return YES;
}

// 支持的旋转方向
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

// 一开始的屏幕旋转方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}
@end
