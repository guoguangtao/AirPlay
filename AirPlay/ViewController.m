//
//  ViewController.m
//  AirPlay
//
//  Created by ggt on 2017/10/11.
//  Copyright © 2017年 ggt. All rights reserved.
//

#import "ViewController.h"
#import "SearchUPnPDevice.h"
#import "CLUPnPModel.h"
#import "Masonry.h"
#import "CLUPnPAVPositionInfo.h"
#import "CLUPnPRenderer.h"

static NSString *const videoURL = @"http://gslb.miaopai.com/stream/L7z4BV09VvsfwH0-SrnE7JI-rrgvIIZF.mp4?ssig=29bac27f82ca3b8e487cc31fdcc0c9d4&amp;amp;amp;amp;amp;time_stamp=1496827477910&amp;amp;amp;amp;amp;cookie_id=59379ddd43a64&amp;amp;amp;amp;amp;vend=1&amp;amp;amp;amp;amp;os=3&amp;amp;amp;amp;amp;partner=1&amp;amp;amp;amp;amp;platform=2&amp;amp;amp;amp;amp;cookie_id=&amp;amp;amp;amp;amp;refer=miaopai&amp;amp;amp;amp;amp;scid=L7z4BV09VvsfwH0-SrnE7JI-rrgvIIZF";

@interface ViewController () <SearchUPnPDeviceDelegate, UITableViewDataSource, UITableViewDelegate, CLUPnPResponseDelegate>

@property (nonatomic, strong) NSMutableArray *deviceArray; /**< 设备数组 */
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CLUPnPRenderer *renderer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.deviceArray = [NSMutableArray array];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    
    
    [SearchUPnPDevice shareInstance].delegate = self;
    [[SearchUPnPDevice shareInstance] searchAboutDevices];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"1"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"1"];
    }
    
    CLUPnPModel *device = self.deviceArray[indexPath.row];
    cell.textLabel.text = device.friendlyName;
    cell.detailTextLabel.text = device.urlHeader;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.renderer stop];
    
    CLUPnPModel *device = self.deviceArray[indexPath.row];
    CLUPnPRenderer *renderer = [[CLUPnPRenderer alloc] initWithModel:device];
    self.renderer = renderer;
    renderer.delegate = self;
    [renderer setAVTransportURL:videoURL];
    [renderer play];
}

#pragma mark - SearchUPnPDeviceDelegate

/**
 搜索成功返回
 
 @param deviceModel 设备描述文档返回设备基本信息数据
 @param serviceModel 设备描述文档返回设备基服务信息数据
 */
- (void)searchSucessWithDeviceModel:(id) deviceModel serviceModel:(id) serviceModel {
    
    CLUPnPModel *device = (CLUPnPModel *)deviceModel;
    NSLog(@"modelName = %@, friendlyName = %@", device.modelName, device.friendlyName);
    
    for (CLUPnPModel *deviceM in self.deviceArray) {
        if ([deviceM.urlHeader isEqualToString:deviceM.urlHeader]) {
            return;
        }
    }
    [self.deviceArray addObject:device];
    [self.tableView reloadData];
}

/**
 搜索失败返回
 
 @param error 错误信息
 */
- (void)searchFailedWithError:(NSError *)error {
    
    NSLog(@"%s", __func__);
}

#pragma mark - CLUPnPResponseDelegate

/**
 设置 URL 响应
 */
- (void)upnpSetAVTransportURIResponse {
    
    NSLog(@"URL 响应");
}

/**
 获取播放状态
 */
- (void)upnpGetTransportInfoResponse:(CLUPnPTransportInfo *)info {
    
    NSLog(@"播放状态%@", info);
}

/**
 播放响应
 */
- (void)upnpPlayResponse {
    
    NSLog(@"播放");
}

/**
 暂停
 */
- (void)upnpPauseResponse {
    
    NSLog(@"暂停");
}

/**
 停止投屏
 */
- (void)upnpStopResponse {
    
    NSLog(@"停止投屏");
}

/**
 跳转
 */
- (void)upnpSeekResponse {
    
    NSLog(@"跳转");
}

- (void)upnpPreviousResponse {
    
    NSLog(@"上一个");
}

- (void)upnpNextResponse {
    
    NSLog(@"下一个");
}

- (void)upnpSetVolumeResponse {
    
    NSLog(@"设置音量");
}

- (void)upnpSetNextAVTransportURIResponse {
    
    NSLog(@"设置下一个播放链接");
}

- (void)upnpGetVolumeResponse:(NSString *)volume {
    
    NSLog(@"获取音频信息");
}
- (void)upnpGetPositionInfoResponse:(CLUPnPAVPositionInfo *)info {
    
    NSLog(@"获取播放进度%@", info);
}
- (void)upnpUndefinedResponse:(NSString *)xmlString {
    
    NSLog(@"未知错误%@", xmlString);
}

@end
