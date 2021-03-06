//
//  DownloadViewController.h
//  Puzzle
//
//  Created by Kira on 10/8/13.
//  Copyright (c) 2013 Kira. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"
#import "ImageManager.h"
#import "HudController.h"

@interface DownloadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UIButton *hottestBtn;
    IBOutlet UIButton *latestBtn;
    IBOutlet UIView *indView;
}

@property (nonatomic, retain) NSArray *photoListArray;

@property (nonatomic, retain) IBOutlet UITableView *photoTable;

- (id)initWithPhotoList:(NSArray *)list;

@end
