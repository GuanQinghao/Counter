//
//  ViewController.m
//  Counter
//
//  Created by Mac on 2019/9/19.
//  Copyright © 2019 GuanQinghao. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController ()

/// 媒体文件总时长标签
@property (weak) IBOutlet NSTextField *totalTimeLabel;
/// 媒体文件总个数标签
@property (weak) IBOutlet NSTextField *fileCountLabel;
/// 目录标签
@property (weak) IBOutlet NSTextField *directoryLabel;
/// 选择按钮
@property (weak) IBOutlet NSButton *chooseButton;

/// 媒体文件总时长(单位:秒)
@property (nonatomic, assign) CGFloat totalTime;
/// 媒体文件总个数
@property (nonatomic, assign) NSUInteger fileCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 媒体文件总时长标签
    self.totalTimeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.totalTimeLabel.alignment = NSTextAlignmentCenter;
    self.totalTimeLabel.textColor = NSColor.redColor;
    self.totalTimeLabel.placeholderString = @"00:00:00";
    self.totalTimeLabel.font = [NSFont fontWithName:@"PingFangSC-Semibold" size:30.0f];
    self.totalTimeLabel.editable = false;
    
    // 媒体文件总个数标签
    self.fileCountLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.fileCountLabel.alignment = NSTextAlignmentCenter;
    self.fileCountLabel.textColor = NSColor.greenColor;
    self.fileCountLabel.placeholderString = @"0";
    self.fileCountLabel.font = [NSFont fontWithName:@"PingFangSC-Semibold" size:30.0f];
    self.fileCountLabel.editable = false;
    
    // 目录标签
    self.directoryLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.directoryLabel.alignment = NSTextAlignmentLeft;
    //    self.directoryLabel.textColor = NSColor.textColor;
    self.directoryLabel.placeholderString = @"...";
    //    self.directoryLabel.font = [NSFont fontWithName:@"PingFangSC-Semibold" size:15.0f];
    self.directoryLabel.editable = false;
    
    // 选择按钮
    [self.chooseButton setTitle:@"Choose"];
}

/// 遍历所有文件并计算媒体文件的总个数和总时长
/// @param path 路径
- (void)traverse:(NSString *)path {
    
    // 文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 是否是文件夹目录
    BOOL isDirectory = false;
    // 是否存在
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    
    if (isExist) {
        
        if (isDirectory) {
            
            // 文件夹下的所有文件及文件夹
            NSArray *directoryArray = [fileManager contentsOfDirectoryAtPath:path error:nil];
            
            for (NSString *name in directoryArray) {
                
                // 忽略隐藏的文件或文件夹
                if ([name hasPrefix:@"."]) {
                    
                    continue;
                }
                
                // 递归遍历
                [self traverse:[path stringByAppendingPathComponent:name]];
            }
        } else {
            
            // 文件路径URL
            NSURL *pathURL = [NSURL fileURLWithPath:path];
            // 初始化媒体文件
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:pathURL options:nil];
            // 媒体文件时长(单位:秒)
            self.totalTime += CMTimeGetSeconds(asset.duration);
            // 媒体文件个数
            self.fileCount++;
            
            // 主线程刷新
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // 媒体总时长
                self.totalTimeLabel.stringValue = [self convert:self.totalTime];
                // 媒体文件个数
                self.fileCountLabel.stringValue = [NSString stringWithFormat:@"%@",@(self.fileCount)];
            });
        }
    } else {
        
        NSLog(@"files not exist!");
    }
}

/// 选择目录
/// @param sender 选择按钮
- (IBAction)chooseDirectory:(NSButton *)sender {
    
    // 按钮禁用
    sender.enabled = NO;
    
    // 弹出面板
    NSOpenPanel *panel = [[NSOpenPanel alloc] init];
    // 是否允许创建文件夹目录
    panel.canCreateDirectories = NO;
    // 是否允许选择文件夹目录
    panel.canChooseDirectories = YES;
    // 是否允许选择文件
    panel.canChooseFiles = YES;
    // 是否允许多选
    panel.allowsMultipleSelection = NO;
    
    // 显示弹出面板
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        
        if (result == NSModalResponseOK) {
            
            // 选择的文件目录
            NSString *path = panel.URLs.firstObject.path;
            // 显示选择的文件目录
            self.directoryLabel.stringValue = path;
            
            // 全局并发队列异步执行(子线程)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                /*耗时操作*/
                
                // 总时长
                self.totalTime = 0.0f;
                // 总个数
                self.fileCount = 0;
                
                // 遍历媒体文件并计算时长
                [self traverse:path];
                
                // 主线程刷新
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // 按钮可用
                    sender.enabled = YES;
                });
            });
        }
    }];
}

#pragma mark - PrivateMethod

/// 秒数格式化为时分秒
/// @param duration 秒数
- (NSString *)convert:(CGFloat)duration {
    
    if (duration < 0.0f) {
        
        return @"unknown";
    }
    
    // 四舍五入
    NSUInteger total = round(duration);
    // 秒
    NSUInteger seconds = total%60;
    // 分
    NSUInteger minutes = total/60%60;
    // 时
    NSUInteger hours = total/3600;
    
    return [NSString stringWithFormat:@"%02lu:%02lu:%02lu",hours,minutes,seconds];
}

@end
