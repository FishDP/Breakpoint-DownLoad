//
//  DKPDownLoadVc.m
//  断点下载
//
//  Created by DP on 16/6/25.
//  Copyright © 2016年 dp. All rights reserved.
//

#define FULLPATH [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingString:@"video.mp4"]
#define DATAPATH [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingString:@"tem.txt"]
#import "DKPDownLoadVc.h"

@interface DKPDownLoadVc ()<NSURLSessionDataDelegate>
/**进度条*/
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
/** 已经下载数据*/
@property (nonatomic, assign) NSInteger currentData;
/** 总数据长度*/
@property (nonatomic, assign) NSInteger totalDataSize;
/** 任务*/
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
/** 文件句柄*/
@property (nonatomic, strong)  NSFileHandle *handle ;

@property (nonatomic, assign) NSInteger btnClickCount;
/** 会话对象*/
@property (nonatomic, strong)  NSURLSession *session;
@end

@implementation DKPDownLoadVc
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.session invalidateAndCancel];//释放session的代理（当前控制器）
    
}
- (NSURLSession *)session {
    if (_session == nil) {
        
        //3.创建连接，设置代理
        _session = [NSURLSession sessionWithConfiguration:[ NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
    }
    return _session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:FULLPATH error:nil];
    self.currentData =  [info[@"NSFileSize"] integerValue];
    
    NSData *data = [NSData dataWithContentsOfFile:DATAPATH];
    if (data) {
        
        NSInteger totalSize = [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding] integerValue];
        self.progressView.progress = 1.0 * self.currentData/totalSize;
    }
  
}

- (void)setFileUrl:(NSURL *)fileUrl {
    _fileUrl = fileUrl;
}
- (void)downLoadWithURL:(NSURL *)url {
    
    if (_dataTask == nil) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSString *rangeStr = [NSString stringWithFormat:@"bytes=%ld-",self.currentData];
        [request setValue:rangeStr forHTTPHeaderField:@"Range"];
        
        _dataTask = [self.session dataTaskWithRequest:request];
        [self.dataTask resume];
        
    }
}

- (NSURLSessionDataTask *)dataTask  {
    
    if (self.progressView.progress == 1) {
        NSLog(@"已下载完成");
        return nil;
    }
    if (_dataTask == nil) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.fileUrl];
        
        NSString *rangeStr = [NSString stringWithFormat:@"bytes=%ld-",self.currentData];
        [request setValue:rangeStr forHTTPHeaderField:@"Range"];
        
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[ NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        
        _dataTask = [session dataTaskWithRequest:request];
        
    }
    return _dataTask;
}

/**开始*/
- (IBAction)startBtnClick:(UIButton *)sender {
    
    
    self.btnClickCount ++;
    if (self.btnClickCount % 2 == 1) {
        //奇数-->下载
    
        [self.dataTask resume];
        sender.selected = YES;
    }else
    {
        [self.dataTask suspend];
        sender.selected = NO;
    }
}


#pragma mark ----------
#pragma mark - NSURLSessionDataDelegate
//1.收到响应时调用(在该方法中)
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    self.totalDataSize = response.expectedContentLength +self.currentData;
    NSData *totaldata = [[NSString stringWithFormat:@"%ld",self.totalDataSize] dataUsingEncoding:NSUTF8StringEncoding];
    [totaldata writeToFile:DATAPATH atomically:YES];
    completionHandler (NSURLSessionResponseAllow);
    NSString *fullPath = FULLPATH;
    if (!self.currentData) {
        [[NSFileManager defaultManager] createFileAtPath:fullPath contents:nil attributes:nil];
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:fullPath];
    self.handle = handle;
    
    [self.handle seekToEndOfFile];
}
//2.收到数据时调用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    self.currentData += data.length;
    self.progressView.progress = 1.0* self.currentData/self.totalDataSize;
    NSLog(@"%f",self.progressView.progress);
    [self.handle writeData:data];
}

//3.完成或者出错时调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"%s",__func__);
    
    [self.handle closeFile];
    self.handle = nil;
}

@end
