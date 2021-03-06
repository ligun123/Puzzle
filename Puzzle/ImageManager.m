//
//  ImageManager.m
//  Puzzle
//
//  Created by Kira on 9/2/13.
//  Copyright (c) 2013 Kira. All rights reserved.
//

#import "ImageManager.h"
#import "def.h"
#import "BWStatusBarOverlay.h"
#import "HudController.h"

static ImageManager *userInterface = nil;

@implementation ImageManager

+ (NSArray *)AllPlayImagePaths
{
    NSMutableArray *imgArr = [NSMutableArray arrayWithCapacity:10];
    
    NSString *resFolder = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"free"];
    NSArray *subitems = [[NSFileManager defaultManager] subpathsAtPath:resFolder];
    for (int i = 0; i < [subitems count]; i ++) {
        NSString * itemPath = [resFolder stringByAppendingPathComponent:[subitems objectAtIndex:i]];
        [imgArr addObject:itemPath];
    }
    
    NSString *docPath = [NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()];
    NSArray *subItem = [[NSFileManager defaultManager] subpathsAtPath:docPath];
    for (int i = 0; i < [subItem count]; i ++) {
        NSString *imgPath = [docPath stringByAppendingPathComponent:[subItem objectAtIndex:i]];
        [imgArr addObject:imgPath];
    }
    return imgArr;
}

+ (NSMutableArray *)AllPlayImagePrefix
{
    NSMutableArray *imgArr = [NSMutableArray arrayWithCapacity:30];
    NSString *docPath = [NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()];
    NSArray *subItem = [[NSFileManager defaultManager] subpathsAtPath:docPath];
    for (int i = 0; i < [subItem count]; i ++) {
        NSString *imgName = [subItem objectAtIndex:i];
        if ([imgName rangeOfString:@"tile"].location == NSNotFound) {
            NSString *prefix = [[imgName componentsSeparatedByString:@"."] objectAtIndex:0];
            [imgArr addObject:prefix];
        }
    }
    return imgArr;
}

+ (ImageManager *)shareInterface
{
    if (userInterface == nil) {
        userInterface = [[self alloc] init];
    }
    return userInterface;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    self.localTileImagesArray = nil;
    self.serverTileImagesArray = nil;
    [super dealloc];
}

- (void)hottestSortedLocalTileImageArray
{
    NSArray *sortedArray = [self.localTileImagesArray sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger photoid1 = [[(NSDictionary *)obj1 objectForKey:@"favour"] integerValue];
        NSInteger photoid2 = [[(NSDictionary *)obj2 objectForKey:@"favour"] integerValue];
        return photoid1 < photoid2;
    }];
    self.localTileImagesArray = [NSMutableArray arrayWithArray:sortedArray];
}
- (void)latestSortedLocalTileImageArray
{
    NSArray *sortedArray = [self.localTileImagesArray sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger photoid1 = [[(NSDictionary *)obj1 objectForKey:@"photoid"] integerValue];
        NSInteger photoid2 = [[(NSDictionary *)obj2 objectForKey:@"photoid"] integerValue];
        return photoid1 < photoid2;
    }];
    self.localTileImagesArray = [NSMutableArray arrayWithArray:sortedArray];
}

- (NSString *)tilePathForPrefix:(NSString *)name
{
    return [NSString stringWithFormat:@"%@/Documents/%@_tile.jpg", NSHomeDirectory(), name];
}

- (NSString *)bigPicPathForPrefix:(NSString *)name
{
    return [NSString stringWithFormat:@"%@/Documents/%@.jpg", NSHomeDirectory(), name];
}

- (void)partAllTileList:(NSArray *)allList
{
    //allList是某个类别下的所有tile图片
    //在类别之间切换必须要清空localTileImagesArray + serverTileImagesArray;
    if (self.localTileImagesArray != nil) {
        self.localTileImagesArray = nil;
    }
    self.localTileImagesArray = [NSMutableArray arrayWithCapacity:30];
    
    if (self.serverTileImagesArray != nil) {
        self.serverTileImagesArray = nil;
    }
    self.serverTileImagesArray = [NSMutableArray arrayWithCapacity:30];
    
    for (int i = 0; i < [allList count]; i ++) {
        NSDictionary *item = [allList objectAtIndex:i];
        NSString *filePrefix = [item objectForKey:@"path"];
        
        NSString *fullPath = [self tilePathForPrefix:filePrefix];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            //has download
            [self.localTileImagesArray addObject:item];
        } else {
            [self.serverTileImagesArray addObject:item];
        }
    }
}

- (void)loadTiltImages
{
    //init tile queue
    if (!([self.serverTileImagesArray count] > 0)) {
        return ;
    }
    ASINetworkQueue *tileQueue = [[ASINetworkQueue alloc] init];
    tileQueue.delegate = self;
    [tileQueue setRequestDidFinishSelector:@selector(tileRequestDidFinish:)];
    [tileQueue setRequestDidFailSelector:@selector(tileRequestDidFail:)];
    [tileQueue setQueueDidFinishSelector:@selector(tileQueueDidFinish:)];
    
    for (int i = 0; i < [self.serverTileImagesArray count]; i ++) {
        //Download the tile image
        NSDictionary *tileItem = [self.serverTileImagesArray objectAtIndex:i];
        NSString *name = [tileItem objectForKey:@"path"];
        NSString *tileUrl = [NSString stringWithFormat:@"%@/download.php?filename=%@&suffix=_tile.jpg", domin, name];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:tileUrl]];
        NSString *desPath = [self tilePathForPrefix:name];
        [request setDownloadDestinationPath:desPath];
        [request setUserInfo:tileItem];
        [tileQueue addOperation:request];
    }
    [tileQueue go];
}

- (void)deleteImageWithDataDic:(NSDictionary *)dic
{
    NSLog(@"%s -> %@", __FUNCTION__, dic);
    NSString *tileUrl = [NSString stringWithFormat:@"%@/removephoto.php", domin];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:tileUrl]];
    [request setRequestMethod:@"POST"];
    [request setPostValue:[dic objectForKey:@"path"] forKey:@"path"];
    [request setDelegate:self];
    [request setDidFailSelector:@selector(deleteDidFail:)];
    [request setDidFinishSelector:@selector(deleteDidFinish:)];
    [request startAsynchronous];
}

- (void)loadBigImageWithDataDic:(NSDictionary *)dic
{
    NSString *prefix = [dic objectForKey:@"path"];
    [[HudController shareHudController] showWithLabel:@"Loading..."];
    NSString *tileUrl = [NSString stringWithFormat:@"%@/download.php?filename=%@&suffix=.jpg", domin, prefix];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:tileUrl]];
    NSString *desPath = [self bigPicPathForPrefix:prefix];
    [request setDownloadDestinationPath:desPath];
    [request setUserInfo:dic];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(loadBigDidFinish:)];
    [request setDidFailSelector:@selector(loadBigDidFail:)];
    [request startAsynchronous];
}

- (void)loadBigImageWithPrefix:(NSString *)prefix
{
    [[HudController shareHudController] showWithLabel:@"Loading..."];
    NSString *tileUrl = [NSString stringWithFormat:@"%@/download.php?filename=%@&suffix=.jpg", domin, prefix];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:tileUrl]];
    NSString *desPath = [self bigPicPathForPrefix:prefix];
    [request setDownloadDestinationPath:desPath];
    [request setUserInfo:[NSDictionary dictionaryWithObject:prefix forKey:@"prefix"]];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(loadBigDidFinish:)];
    [request setDidFailSelector:@selector(loadBigDidFail:)];
    [request startAsynchronous];
}

#pragma mark - Tile Network Queue Delegate

- (void)tileRequestDidFail:(ASIHTTPRequest *)request
{
    [BWStatusBarOverlay showErrorWithMessage:NSLocalizedString(@"NetworkErrorMessage", nil) duration:2.0 animated:YES];
    NSString *tilePath = [self tilePathForPrefix:[[request userInfo] objectForKey:@"path"]];
    [[NSFileManager defaultManager] removeItemAtPath:tilePath error:nil];
}

- (void)tileRequestDidFinish:(ASIHTTPRequest *)request
{
    NSDictionary *tileItem = [request userInfo];
    if ([self.serverTileImagesArray indexOfObject:tileItem] == NSNotFound) {
        //说明这个request并不是当前类别
        //则仅仅保存图片，不做后续的操作操作
        return ;
    }
    [self.localTileImagesArray addObject:tileItem];
    [self.serverTileImagesArray removeObject:tileItem];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotiNameDidLoadTileImage object:nil];
}

- (void)tileQueueDidFinish:(ASINetworkQueue *)queue
{
    [queue reset];
    [queue cancelAllOperations];
    [queue release];
}

#pragma mark - Load Big Pic Request

- (void)loadBigDidFinish:(ASIHTTPRequest *)request
{
    [[HudController shareHudController] hudWasHidden];
    if ([[[request userInfo] objectForKey:@"categaryid"] integerValue] != 1) {
        NSInteger cur = [[NSUserDefaults standardUserDefaults] integerForKey:@"coincount"];
        [[NSUserDefaults standardUserDefaults] setInteger:cur -10 forKey:@"coincount"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotiNameDidLoadBigImage object:nil];
}

- (void)loadBigDidFail:(ASIHTTPRequest *)request
{
    [[HudController shareHudController] hudWasHidden];
    [BWStatusBarOverlay showErrorWithMessage:NSLocalizedString(@"NetworkErrorMessage", nil) duration:2.0 animated:YES];
}

#pragma mark - Delete Request Delegate

- (void)deleteDidFail:(ASIHTTPRequest *)reqeust
{
    [self alertMessage:[reqeust responseString]];
}
- (void)deleteDidFinish:(ASIHTTPRequest *)reqeust
{
    if ([reqeust responseStatusCode] != 200) {
        [self alertMessage:[reqeust responseString]];
    }
}

- (void)alertMessage:(NSString *)str
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

@end
