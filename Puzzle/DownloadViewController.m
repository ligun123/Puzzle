//
//  DownloadViewController.m
//  Puzzle
//
//  Created by Kira on 10/8/13.
//  Copyright (c) 2013 Kira. All rights reserved.
//

#import "DownloadViewController.h"
#import "def.h"
#import "DownloadCell.h"
#import "BuyCoinsViewController.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController

- (id)initWithPhotoList:(NSArray *)list
{
    NSString *nibName = (isPad) ? @"DownloadViewController_pad" : @"DownloadViewController";
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        // Custom initialization
        self.photoListArray = list;
        [[ImageManager shareInterface] partAllTileList:list];
        [[ImageManager shareInterface] loadTiltImages];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadTileImage:) name:kNotiNameDidLoadTileImage object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadBigImage:) name:kNotiNameDidLoadBigImage object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needBuyMoreCoin:) name:kNotiNameNeedMoreCoin object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buyMoreCoinOver:) name:kNotiNameBuyCoinOver object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(btnBackTap:)];
    backBtn.tintColor = [UIColor purpleColor];
    self.navigationItem.leftBarButtonItem = [backBtn autorelease];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(btnDoneTap:)];
    doneBtn.tintColor = [UIColor purpleColor];
    self.navigationItem.rightBarButtonItem = [doneBtn autorelease];
    
    if (isPad) {
        UIImageView *back = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GreenBack.jpg"]];
        back.frame = self.view.bounds;
        [self.view insertSubview:[back autorelease] atIndex:0];
    } else {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"GreenBack.jpg"]];
    }
}

- (void)btnBackTap:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)btnDoneTap:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.photoTable = nil;
    self.photoListArray = nil;
    [super dealloc];
}

#pragma mark - Table View

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:@"coincount"];
    return [NSString stringWithFormat:NSLocalizedString(@"currentCoinTitle", nil), count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[ImageManager shareInterface] localTileImagesArray] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"downloadCell";
    static NSString *identifierPad = @"downloadCell_pad";
    DownloadCell *cell = [tableView dequeueReusableCellWithIdentifier: ((isPad) ? identifierPad : identifier)];
    if (!cell) {
        NSString *cellNibName = (isPad) ? @"DownloadCell_pad" : @"DownloadCell";
        cell = [[[NSBundle mainBundle] loadNibNamed:cellNibName owner:self options:nil] objectAtIndex:0];
    }
    NSDictionary *dataDic = [[[ImageManager shareInterface] localTileImagesArray] objectAtIndex:indexPath.row];
    NSString *tilename = [dataDic objectForKey:@"path"];
    [cell resetViewImagePrefix:tilename];
    [cell setDataDic:dataDic];
    [cell setFavour:[dataDic objectForKey:@"favour"]];
    if ([[dataDic objectForKey:@"categaryid"] integerValue] != 1) {
        //不是免费的图片
        [cell showPayStyle];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didLoadTileImage:(NSNotification *)noti
{
    [self.photoTable reloadData];
}

- (void)didLoadBigImage:(NSNotification *)noti
{//下载一个大图片完成后
    [self.photoTable reloadData];
}

- (void)needBuyMoreCoin:(NSNotification *)noti
{
    BuyCoinsViewController *buy = [[BuyCoinsViewController alloc] init];
    [self.navigationController pushViewController:buy animated:YES];
    [buy release];
}

- (void)buyMoreCoinOver:(NSNotification *)noti
{
    [self.photoTable reloadData];
}


@end
