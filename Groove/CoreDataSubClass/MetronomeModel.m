//
//  MetronomeModel.m
//  Groove
//
//  Created by C-ty on 2014/9/25.
//  Copyright (c) 2014年 Cty. All rights reserved.
//

#import "MetronomeModel.h"

// private property
@interface MetronomeModel ()

@property NSFetchRequest* TempoCellEntityFetch;
@property NSFetchRequest* TempoCellEntitySigleOwnerFetch;
@property NSFetchRequest* TempoListEntityFetch;
@property NSFetchRequest* TimeSignatureTypeEntityFetch;
@property NSFetchRequest* VoiceTypeEntityFetch;
@property NSFetchRequest* DbConfigEntityFetch;

@end

@implementation MetronomeModel
{
    NSManagedObjectContext * _ManagedObjectContext;
    NSManagedObjectModel * _ManagedObjectModel;
    NSNumber * _DbVersion; // For compare with pList checking
}

- (void) InitializeCoreData : (NSManagedObjectContext *) ManagedObjectContext
         ManagedObjectModel : (NSManagedObjectModel *) ManagedObjectModel
                  DbVersion : (NSNumber *) DbVersion
{

    Boolean IsItNeedToInsertDBValue = NO;
    _ManagedObjectContext = ManagedObjectContext;
    _ManagedObjectModel = ManagedObjectModel;
    _DbVersion = DbVersion;
    
    // CheckVersion
    self.DbVersionDataTable = [self FetchDbConfigWhereDbVersion : _DbVersion];
    if (self.DbVersionDataTable.count == 0)
    {
        IsItNeedToInsertDBValue = YES;
    }
    
    // If need to set default
    if (IsItNeedToInsertDBValue)
    {
        NSLog(@"Reset Db");
        
        // *****************
        // TODO: Delete all data
        // *****************
        
        // Create
        [self ResetToDefaultDb: _DbVersion];
    }

    // Fetch All Data
    // Select TimeSignatureType
    [self SyncTimeSignatureTypeDataTableWithModel];
    
    [self SyncVoiceTypeWithModel];
    
    // Select TempoList
    [self SyncTempoListDataTableWithModel];
   
    
#if DEBUG_CLOSE
    // Debug Test
    for (TempoCell* Cell in self.TempoCellDataTable) {
        NSLog(@"%@", Cell);
    }
#endif
    
}

// ==============================
// Reset to Default
//
- (void) ResetToDefaultDb : (NSNumber *)DBVersion
{
    // Create TempoList
    NSLog(@"01 Create TempoList");
    [self CreateDefaultTempoList];
    
    // Create TimeSignature
    NSLog(@"02 Create TimeSignature");
    [self CreateDefaultTimeSignatureType];
    
    // Create VoiceType
    NSLog(@"03 Create VoiceType");
    [self CreateDefaultVoiceType];
    
    // Create TempoCell
    NSLog(@"04 Create TempoCell");
    [self CreateDefaultTempoCell];
    
    // Update DbVersion
    NSLog(@"04 Update DbVersion");
    [self UpdateDbVersion:DBVersion];
}

- (void) UpdateDbVersion : (NSNumber *)NewDBVersion
{
    DbConfig* NewDbConfig = [NSEntityDescription
                             insertNewObjectForEntityForName:NSStringFromClass([DbConfig class]) inManagedObjectContext:_ManagedObjectContext];
    NewDbConfig.dbVersion = NewDBVersion;
    [self Save];
}

- (void) CreateDefaultTempoList
{
    for (int Index=0;Index <3; Index++)
    {
        [self AddNewTempoList: [NSString stringWithFormat:@"Default%d", Index]];
    }
    [self Save];
}

- (void) CreateDefaultTimeSignatureType
{
    NSArray *TimeSignatureArray =[NSArray arrayWithObjects:@"1/4",@"2/4",@"3/4",@"4/4",@"5/4",@"6/4",@"7/4",@"8/4",@"9/4",@"10/4",@"11/4",@"12/4", nil];
    for (int Index=0;Index <TimeSignatureArray.count; Index++)
    {
        TimeSignatureType* NewTimeSignatureType = [NSEntityDescription
                                                   insertNewObjectForEntityForName:NSStringFromClass([TimeSignatureType class]) inManagedObjectContext:_ManagedObjectContext];
        NewTimeSignatureType.timeSignature = (NSString *)TimeSignatureArray[Index];
        NewTimeSignatureType.sortIndex = [NSNumber numberWithInt:Index];
        NSLog(@"%@", NewTimeSignatureType);
    }
    [self Save];
}

- (void) CreateDefaultVoiceType
{
    NSArray *VoiceTypeArray =[NSArray arrayWithObjects:@"NomalHiClickVoice", @"NomalLowClickVoice", @"HumanVoice", nil];
    for (int Index=0;Index <VoiceTypeArray.count; Index++)
    {
        VoiceType* NewVoiceType = [NSEntityDescription
                                                   insertNewObjectForEntityForName:NSStringFromClass([VoiceType class]) inManagedObjectContext:_ManagedObjectContext];
        NewVoiceType.voiceType = (NSString *)VoiceTypeArray[Index];
        NewVoiceType.sortIndex = [NSNumber numberWithInt:Index];
    }
    [self Save];
}

- (void) CreateDefaultTempoCell
{
    // Select TimeSignatureType
    if (self.TimeSignatureTypeDataTable == nil)
    {
        [self SyncTimeSignatureTypeDataTableWithModel];
    }
    
    // Select TempoList
    if (self.TempoListDataTable == nil)
    {
        [self SyncTempoListDataTableWithModel];
    }
    
    for (int Row = 0; Row < self.TempoListDataTable.count; Row++)
    {
        for (int Index = 0 ;Index < 3; Index++)
        {
            TempoCell* NewTempoList = [NSEntityDescription
                                       insertNewObjectForEntityForName:NSStringFromClass([TempoCell class])  inManagedObjectContext:_ManagedObjectContext];
            NewTempoList.bpmValue = [NSNumber numberWithInt:(50 + (Index + Row) *10)];
            NewTempoList.loopCount = @1;
            NewTempoList.accentVolume = @10.0;
            NewTempoList.quarterNoteVolume = @10.0;
            NewTempoList.eighthNoteVolume = @7.0;
            NewTempoList.sixteenNoteVolume = @0;
            NewTempoList.trippleNoteVolume = @0;
            NewTempoList.timeSignatureType = self.TimeSignatureTypeDataTable[3];
            NewTempoList.listOwner = self.TempoListDataTable[Row];
            NewTempoList.sortIndex = [NSNumber numberWithInt:Index];
        }
    }
    [self Save];
}

- (MusicBindingInfo *) CreateNewMusicInfo
{
    MusicBindingInfo *NewInfo = [NSEntityDescription
                                insertNewObjectForEntityForName:NSStringFromClass([MusicBindingInfo class])  inManagedObjectContext:_ManagedObjectContext];
    NewInfo.volume = [NSNumber numberWithFloat:DefaultMusicVolume];
    [self Save];

    return NewInfo;
}

//
// ==============================


// ==============================
// Fetch
//

- (NSArray *) FetchDbConfigWhereDbVersion : (NSNumber *) DbVersion
{
    if (self.DbConfigEntityFetch == nil)
    {
        NSEntityDescription *Entity;
        Entity = [NSEntityDescription entityForName:NSStringFromClass([DbConfig class]) inManagedObjectContext:_ManagedObjectContext];
        
        self.DbConfigEntityFetch = [_ManagedObjectModel fetchRequestFromTemplateWithName:@"FetchDbVersion" substitutionVariables:[NSDictionary dictionaryWithObject:DbVersion forKey:@"DbVersion"]];
        [self.DbConfigEntityFetch setEntity:Entity];
    }
    
    return [_ManagedObjectContext executeFetchRequest:self.DbConfigEntityFetch error:nil];
}

- (void) SyncTempoListDataTableWithModel
{
    self.TempoListDataTable = [self FetchTempoListWithSort];
}

- (NSArray *) FetchTempoListWithSort
{
    if (self.TempoListEntityFetch == nil)
    {
        NSEntityDescription *Entity;
        self.TempoListEntityFetch = [[NSFetchRequest alloc] init];
        Entity = [NSEntityDescription entityForName:NSStringFromClass([TempoList class]) inManagedObjectContext:_ManagedObjectContext];
        [self.TempoListEntityFetch setEntity:Entity];
        
        // Sort
        NSSortDescriptor *Sort = [[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES];
        NSArray *SortArray = [[NSArray alloc] initWithObjects:Sort, nil];
        [self.TempoListEntityFetch setSortDescriptors:SortArray];
    }
    return [_ManagedObjectContext executeFetchRequest:self.TempoListEntityFetch error:nil];
}

- (void) SyncTimeSignatureTypeDataTableWithModel
{
    self.TimeSignatureTypeDataTable = [self FetchTimeSignatureType];
}

- (NSArray *) FetchTimeSignatureType
{
    NSEntityDescription *Entity;
    
    if (self.TimeSignatureTypeEntityFetch == nil)
    {
        self.TimeSignatureTypeEntityFetch = [[NSFetchRequest alloc] init];
        Entity = [NSEntityDescription entityForName:NSStringFromClass([TimeSignatureType class]) inManagedObjectContext:_ManagedObjectContext];
        [self.TimeSignatureTypeEntityFetch setEntity:Entity];
        
        // Sort
        NSSortDescriptor *Sort = [[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES];
        NSArray *SortArray = [[NSArray alloc] initWithObjects:Sort, nil];
        [self.TimeSignatureTypeEntityFetch setSortDescriptors:SortArray];
    }
    return [_ManagedObjectContext executeFetchRequest:self.TimeSignatureTypeEntityFetch error:nil];
}

- (void) SyncVoiceTypeWithModel
{
    self.VoiceTypeDataTable = [self FetchVoiceType];
}

- (NSArray *) FetchVoiceType
{
    NSEntityDescription *Entity;
    if (self.VoiceTypeEntityFetch == nil)
    {
        self.VoiceTypeEntityFetch = [[NSFetchRequest alloc] init];
        Entity = [NSEntityDescription entityForName:NSStringFromClass([VoiceType class]) inManagedObjectContext:_ManagedObjectContext];
        [self.VoiceTypeEntityFetch setEntity:Entity];
        
        // Sort
        NSSortDescriptor *Sort = [[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES];
        NSArray *SortArray = [[NSArray alloc] initWithObjects:Sort, nil];
        [self.VoiceTypeEntityFetch setSortDescriptors:SortArray];
    }
    return [_ManagedObjectContext executeFetchRequest:self.VoiceTypeEntityFetch error:nil];
}

- (NSArray *) FetchTempoCell
{
    if (self.TempoCellEntityFetch == nil)
    {
        NSEntityDescription *Entity;
        self.TempoCellEntityFetch = [[NSFetchRequest alloc] init];
        Entity = [NSEntityDescription entityForName:NSStringFromClass([TempoCell class]) inManagedObjectContext:_ManagedObjectContext];
        [self.TempoCellEntityFetch setEntity:Entity];
    }
    return [_ManagedObjectContext executeFetchRequest:self.TempoCellEntityFetch error:nil];
}

- (NSArray *) FetchTempoCellFromTempoListWithSort : (TempoList *) listOwner
{
    NSEntityDescription *Entity;
    Entity = [NSEntityDescription entityForName:NSStringFromClass([TempoCell class]) inManagedObjectContext:_ManagedObjectContext];
    
    self.TempoCellEntitySigleOwnerFetch = [_ManagedObjectModel fetchRequestFromTemplateWithName:@"FetchCellFromSigleOwner" substitutionVariables:[NSDictionary dictionaryWithObject:listOwner forKey:@"listOwner"]];
    [self.TempoCellEntitySigleOwnerFetch setEntity:Entity];
    
    // Sort
    NSSortDescriptor *Sort = [[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES];
    NSArray *SortArray = [[NSArray alloc] initWithObjects:Sort, nil];
    [self.TempoCellEntitySigleOwnerFetch setSortDescriptors:SortArray];
    
    NSError *Error;
    NSArray *ReturnArray = [_ManagedObjectContext executeFetchRequest:self.TempoCellEntitySigleOwnerFetch error:&Error];
    if (Error)
    {
        NSLog(@"%@", Error);
    }
    return ReturnArray;
}

- (TempoList *) PickTargetTempoListFromDataTable : (NSNumber * ) TempoListIndex
{
    TempoList * ReturnTempoList = nil;
    
    NSNumber *LastTempoListIndexUserSelected = TempoListIndex;
    
    NSArray* TempoListDataTable = gMetronomeModel.TempoListDataTable;
    
    if (TempoListDataTable.count > [LastTempoListIndexUserSelected intValue])
    {
        ReturnTempoList = TempoListDataTable[[LastTempoListIndexUserSelected intValue]];
    }
   
    return ReturnTempoList;
}

- (TempoList *) GetTargetTempoListFromDataTable : (NSNumber * ) TempoListIndex : (NSArray* )TempoListDataTable
{
    TempoList * ReturnTempoList = nil;

    if (TempoListDataTable.count > [TempoListIndex intValue])
    {
        ReturnTempoList = TempoListDataTable[[TempoListIndex intValue]];
    }

    return ReturnTempoList;
}


//
// ==============================

// ==============================
//
//

- (void) Save
{
    [_ManagedObjectContext save:nil];
}

// TODO : 要Fix 效能
- (int) GetNewEmptySortIndexForTempoCell: (TempoList *) CellOwner
{
    NSArray *TempoCellArrayInTempoList = [self FetchTempoCellFromTempoListWithSort:CellOwner];
    if (TempoCellArrayInTempoList.count == 0)
    {
        return 0;
    }
    else
    {
        TempoCell * Cell = TempoCellArrayInTempoList[TempoCellArrayInTempoList.count - 1];
        return [Cell.sortIndex intValue] + 1;
    }

}

- (void) AddNewTempoCell : (TempoList *) CellOwner
{
    TempoCell* NewTempoCell = [NSEntityDescription
                               insertNewObjectForEntityForName:NSStringFromClass([TempoCell class])  inManagedObjectContext:_ManagedObjectContext];
    NewTempoCell.bpmValue = [NSNumber numberWithFloat:(120.0f)];
    NewTempoCell.loopCount = @1;
    NewTempoCell.accentVolume = @10.0;
    NewTempoCell.quarterNoteVolume = @10.0;
    NewTempoCell.eighthNoteVolume = @0;
    NewTempoCell.sixteenNoteVolume = @0;
    NewTempoCell.trippleNoteVolume = @0;
    NewTempoCell.timeSignatureType = self.TimeSignatureTypeDataTable[3];
    NewTempoCell.listOwner = CellOwner;
    NewTempoCell.sortIndex = [NSNumber numberWithInt:[self GetNewEmptySortIndexForTempoCell:CellOwner] ];

    [self Save];
}

- (void) DeleteTargetTempoCell : (TempoCell *) TargetCell
{
    [_ManagedObjectContext deleteObject:TargetCell];
    
    [self Save];
}

// TODO : 要Fix 效能
- (int) GetNewEmptySortIndexForTempoList
{
    [self SyncTempoListDataTableWithModel];
    if (self.TempoListDataTable.count == 0)
    {
        return 0;
    }
    else
    {
        TempoList * OldLastTempoList  = self.TempoListDataTable[self.TempoListDataTable.count - 1];
        return [OldLastTempoList.sortIndex intValue] + 1;
    }
}

- (TempoList*) AddNewTempoList : (NSString *) ListName
{

    TempoList* NewTempoList = [NSEntityDescription
                               insertNewObjectForEntityForName:NSStringFromClass([TempoList class]) inManagedObjectContext:_ManagedObjectContext];
    NewTempoList.tempoListName = ListName;
    NewTempoList.focusCellIndex = @0;
    NewTempoList.sortIndex = [NSNumber numberWithInt:[self GetNewEmptySortIndexForTempoList]];
    
    [self Save];
    
    return NewTempoList;
}

- (void) DeleteTempoList : (TempoList *) TargetTempoList
{
    // 如果沒有清空相依性, _ManagedObjectContext會假裝沒有
    // 但model裡還是存在, 刪不掉
    
    NSArray * CellArray = [self FetchTempoCellFromTempoListWithSort:TargetTempoList];
    
    for (TempoCell *tmpCell in CellArray)
    {
        [_ManagedObjectContext deleteObject:tmpCell];
    }
    
    if (TargetTempoList.musicInfo != nil)
    {
        [_ManagedObjectContext deleteObject:TargetTempoList.musicInfo];
    }

    [_ManagedObjectContext deleteObject:TargetTempoList];
    
    [self Save];
}

- (void) CreateNewDefaultTempoList: (NSString *) ListName
{
    TempoList * NewTempoList = [self AddNewTempoList:ListName];
    [self AddNewTempoCell:NewTempoList];
}
//
// ==============================

@end
