//
//  ListTablePicker.h
//  Groove
//
//  Created by C-ty on 2014/12/23.
//  Copyright (c) 2014年 Cty. All rights reserved.
//

#import "InputSubmitView.h"
#import "TempoListUICell.h"
#import "NameEditer.h"
#import "GlobalConfig.h"

@protocol  ListTablePickerProtocol <InputSubmitViewProtocol>
@required

@optional

- (IBAction) DeleteItem : (TempoList *) TargetTempoList;
- (IBAction) AddNewItem : (NSString *) ItemName;
@end

@interface ListTablePicker : InputSubmitView <UITableViewDataSource, UITableViewDelegate, TempoListUICellProtocol, InputSubmitViewProtocol>
@property (strong, nonatomic) IBOutlet UIScrollView *ScrolView;
@property (strong, nonatomic) IBOutlet UITableView *TableView;
@property (strong, nonatomic) IBOutlet UIButton *AddButton;
@property (strong, nonatomic) IBOutlet UIButton *SaveButton;
@property (strong, nonatomic) IBOutlet UIView *EditerView;
@property (strong, nonatomic) IBOutlet NameEditer *NameEditer;
@property (nonatomic, assign) id <ListTablePickerProtocol> delegate;
@property (strong, nonatomic, getter = GetTempoListArrayForBinding, setter = SetTempoListArrayForBinding:) NSArray * TempoListArrayForBinding;

- (NSInteger) GetSelectedIndex;
- (void) SetSelectedCell : (TempoList *) TargetTempoList;

@end
