//
//  UdpViewController.m
//  SocketTest
//
//  Created by mac on 15/7/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "UdpViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "DDLog.h"

#define server_Host  @"192.168.2.14"
#define server_Port    8899

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface UdpViewController ()<GCDAsyncUdpSocketDelegate,UITextFieldDelegate>
{
    long useTag;
    UITextField *useTextField;
    UITextView *recivedTV;
    
    //udp对象
    GCDAsyncUdpSocket *udpServerSoket;
}
@end

@implementation UdpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
    }
    
    self.title = @"UDP";
    
    useTag = 100;
    
    UILabel *ipLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 20, 200, 20)];
    ipLabel.backgroundColor = [UIColor clearColor];
    ipLabel.text = [NSString stringWithFormat:@"地址:%@",server_Host];
    [self.view addSubview:ipLabel];
    
    UILabel *hostLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 50, 200, 20)];
    hostLabel.backgroundColor = [UIColor clearColor];
    hostLabel.text = [NSString stringWithFormat:@"端口:%d",server_Port];
    [self.view addSubview:hostLabel];
    
    useTextField = [[UITextField alloc]init];
    useTextField.backgroundColor = [UIColor whiteColor];
    useTextField.frame = CGRectMake(10, 130, 200, 30);
    useTextField.placeholder = @"请输入发送内容";
    useTextField.borderStyle = UITextBorderStyleLine;
    useTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    useTextField.returnKeyType = UIReturnKeySend;
    useTextField.delegate = self;
    [self.view addSubview:useTextField];
    
    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendBtn.frame = CGRectMake(230, 130, 60, 30);
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [sendBtn addTarget:self action:@selector(sendBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendBtn];
    
    recivedTV = [[UITextView alloc]init];
    recivedTV.frame = CGRectMake(10, 170, 300, 100);
    recivedTV.editable = NO;
    recivedTV.backgroundColor = [UIColor grayColor];
    [self.view addSubview:recivedTV];

    
    [self createUdpSocket];
    
}

-(void)createUdpSocket
{
    //创建一个后台队列 等待接收数据
   // dispatch_queue_t dQueue = dispatch_queue_create("My socket queue", NULL); //第一个参数是该队列的名字
    //1.实例化一个udp socket套接字对象
    // udpServerSocket需要用来接收数据
    udpServerSoket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    //2.服务器端来监听端口8899(等待端口8899的数据)
    [udpServerSoket bindToPort:8085 error:nil];
    
    //3.接收一次消息(启动一个等待接收,且只接收一次)
    [udpServerSoket receiveOnce:nil];

}

- (void)sendBtnClick
{
    [useTextField resignFirstResponder];
    
    NSString *s = useTextField.text;
    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSString *host = server_Host;
    uint16_t port = server_Port;
    
    [udpServerSoket sendData:data toHost:host port:port withTimeout:60 tag:useTag];
}

#pragma mark -GCDAsyncUdpSocketDelegate
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    if (tag == useTag)
    {
        NSLog(@"表示标记为%ld的数据发送完成了",useTag);
        useTag++;
    }
}
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"标记为tag %ld的发送失败 失败原因 %@",tag, error);
    
    recivedTV.text = [NSString stringWithFormat:@"%@\r\n-->发送失败\r\n",recivedTV.text];
    
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString *ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 继续来等待接收下一次消息
    NSLog(@"收到服务端的响应 [%@:%d] %@", ip, port, s);
    
    recivedTV.text = [NSString stringWithFormat:@"%@\r\n-->收到服务端的响应:%@\r\n",recivedTV.text,s];
    
    [sock receiveOnce:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendBackToHost:ip port:port withMessage:s];
    });
}

-(void)sendBackToHost:(NSString *)ip port:(uint16_t)port withMessage:(NSString *)s
{
    NSString *msg = @"send message";
    recivedTV.text = [NSString stringWithFormat:@"%@\r\n-->我再发送消息:%@\r\n",recivedTV.text,msg];

    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    
    [udpServerSoket sendData:data toHost:ip port:port withTimeout:60 tag:200];
}

-(void)dealloc
{
    NSLog(@"%s",__func__ );
    [udpServerSoket close];
    udpServerSoket = nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeySend)
    {
        [self sendBtnClick];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    textField.text = @"";
    return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [useTextField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
