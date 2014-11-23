//
//  MetronomeSelectBar.h
//  Groove
//
//  Created by C-ty on 2014/9/21.
//  Copyright (c) 2014年 Cty. All rights reserved.
//

#import "GlobalConfig.h"
#import "XibViewInterface.h"
#import "SelectBarCell.h"
#import "DropCellView.h"

typedef enum{
  SELECT_BAR_NONE,
  SELECT_BAR_CAN_DROP,
  SELECT_BAR_UNCHANGED,
  SELECT_BAR_END
} SELECT_BAR_MOVE_MODE;

@protocol SelectBarProtocol <NSObject>
@required

@optional

- (void) SetFocusIndex: (int) FocusIndex;
- (BOOL) SetTargetCellLoopCountAdd: (int) Index AddValue:(int)Value;
- (void) DeleteTargetIndexCell: (int) Index;

@end

@interface MetronomeSelectBar : XibViewInterface <SelectBarCellProtocol>
@property (getter = GetGrooveCellValueStringList, setter = SetGrooveCellValueStringList:) NSMutableArray* GrooveCellValueStringList;
@property (nonatomic, assign) id<SelectBarProtocol> delegate;

- (void) ChangeFocusIndexByFunction : (int) NewIndex;


// loop button
@property (strong, nonatomic) IBOutlet UIView *HerizontalScrollBar;
@property (strong, nonatomic) IBOutlet UIImageView *FocusLineImage;
@property (strong, nonatomic) IBOutlet UIView *GrooveCellListView;

@property (strong, nonatomic) IBOutlet DropCellView *DropCellView;
@property (strong, nonatomic) UILabel *DropImage;
@end
