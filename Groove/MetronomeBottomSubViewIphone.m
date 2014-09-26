//
//  MetronomeBottomSubViewIphone.m
//  Groove
//
//  Created by C-ty on 2014/9/11.
//  Copyright (c) 2014年 Cty. All rights reserved.
//

#import "MetronomeBottomSubViewIphone.h"
#import "MetronomeModel.h"

@implementation MetronomeBottomSubViewIphone
{
    NSMutableArray * _CurrentDataTable;
    int _FocusIndex;

}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self.VolumeSet removeFromSuperview];
        self.VolumeSet = [[VolumeBarSet alloc] initWithFrame:self.VolumeSet.frame];
        self.VolumeSet.MaxValue = 10.0;
        self.VolumeSet.MinValue = -1.0;
        [self addSubview:self.VolumeSet];
       
        [self.SelectGrooveBar removeFromSuperview];
        self.SelectGrooveBar = [[MetronomeSelectBar alloc] initWithFrame:self.SelectGrooveBar.frame];
        self.SelectGrooveBar.delegate = self;
        [self addSubview:self.SelectGrooveBar];
    }
    return self;
}

- (void) SetVolumeBarVolume : (NSArray *) CellDataTable
{
    TempoCell *Cell = CellDataTable[_FocusIndex];
    self.VolumeSet.SliderAccent.value = [Cell.accentVolume floatValue];
    self.VolumeSet.SliderQuarterNote.value = [Cell.quarterNoteVolume floatValue];
    self.VolumeSet.SliderEighthNote.value = [Cell.eighthNoteVolume floatValue];
    self.VolumeSet.SliderSixteenNote.value = [Cell.sixteenNoteVolume floatValue];
    self.VolumeSet.SliderTrippleNote.value = [Cell.trippleNoteVolume floatValue];

}

- (void) CopyGrooveLoopListToSelectBar : (NSArray *) CellDataTable
{
    NSMutableArray * GrooveLoopList = [[NSMutableArray alloc]init];
    for (TempoCell *Cell in CellDataTable)
    {
        [GrooveLoopList addObject:[Cell.loopCount stringValue]];
    }
    self.SelectGrooveBar.GrooveCellList = GrooveLoopList;
}

// =================================
// Property
//
- (NSMutableArray *) GetCurrentDataTable
{
    return _CurrentDataTable;
}
- (void) SetCurrentDataTable : (NSMutableArray *) NewValue
{
    _CurrentDataTable = NewValue;
    
    // Set Select Loop bar
    [self CopyGrooveLoopListToSelectBar: _CurrentDataTable];
}

- (int) GetFocusIndex
{
    return _FocusIndex;
}

- (void) SetFocusIndex:(int) NewValue
{
    _FocusIndex = NewValue;
    [self SetVolumeBarVolume: _CurrentDataTable];
    
    // Pass to parent view.
    if (self.delegate != nil)
    {
        // Check whether delegate have this selector
        if([self.delegate respondsToSelector:@selector(SetFocusIndex:)])
        {
            [self.delegate SetFocusIndex: _FocusIndex];
        }
    }
}
//
// =================================


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
