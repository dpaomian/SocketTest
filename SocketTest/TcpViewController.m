//
//  TcpViewController.m
//  SocketTest
//
//  Created by mac on 15/7/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "TcpViewController.h"
#import "TcpClient.h"
#import "ITcpClient.h"
#import "Reachability.h"

#define server_Host  @"192.168.2.14"
#define server_Port    @"8899"

@interface TcpViewController ()<UITextFieldDelegate,ITcpClient>
{
    UITextField *useTextField;
    UITextView *recivedTV;
}

@end

@implementation TcpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
    }
    
    self.title = @"TCP";
    
    UILabel *ipLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 20, 200, 20)];
    ipLabel.backgroundColor = [UIColor clearColor];
    ipLabel.text = [NSString stringWithFormat:@"地址:%@",server_Host];
    [self.view addSubview:ipLabel];
    
    UILabel *hostLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 50, 200, 20)];
    hostLabel.backgroundColor = [UIColor clearColor];
    hostLabel.text = [NSString stringWithFormat:@"端口:%@",server_Port];
    [self.view addSubview:hostLabel];
    
    UIButton *contentBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    contentBtn.frame = CGRectMake(20, 80, 200, 30);
    [contentBtn setTitle:@"立即连接" forState:UIControlStateNormal];
    [contentBtn addTarget:self action:@selector(contentBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:contentBtn];
    
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
    
    [self startNotifierNetwork];

}

//开启网络状况的监听
- (void)startNotifierNetwork
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    NSString *remoteHostName = @"www.apple.com";
    Reachability *hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
    [hostReachability startNotifier];
    // [self updateInterfaceWithReachability:hostReachability];
}

//监听到网络状态改变
- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

//处理连接改变后的情况
- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    BOOL connectionRequired = [reachability connectionRequired];
    
    switch (netStatus)
    {
        case NotReachable:
        {
            NSLog(@"网络环境 无网络");
            connectionRequired = NO;
            
            recivedTV.text = @"网络不可用";
            recivedTV.backgroundColor = [UIColor redColor];
            
            TcpClient *tcp = [TcpClient sharedInstance];
            [tcp setDelegate_ITcpClient:self];
            
            [tcp.asyncSocket disconnect];
            
            break;
        }
            
        case ReachableViaWWAN:
        {
            NSLog(@"网络环境 3G/2G");
            
            recivedTV.backgroundColor = [UIColor greenColor];
            recivedTV.text = @"当前通过2g or 3g连接";
            
            break;
        }
        case ReachableViaWiFi:
        {
            NSLog(@"网络环境 wifi");
            
            recivedTV.backgroundColor = [UIColor greenColor];
            recivedTV.text = @"当前通过wifi连接";
            
            break;
        }
    }
    
}

-(void)contentBtnClick
{
    TcpClient *tcp = [TcpClient sharedInstance];
    [tcp setDelegate_ITcpClient:self];
    if(tcp.asyncSocket.isConnected)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"网络已经连接好啦！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        NSString *HOST = server_Host;
        NSString *port = server_Port;
        [tcp openTcpConnection:HOST port:[port intValue]];
    }
    
    [useTextField resignFirstResponder];
}

-(void)sendBtnClick
{
    [useTextField resignFirstResponder];
    
    NSString *sendMessage = useTextField.text;
    NSLog(@"发送内容 %@",sendMessage);
    
    if (sendMessage!=nil&&sendMessage.length>0)
    {
        TcpClient *tcp = [TcpClient sharedInstance];
        if(tcp.asyncSocket.isDisconnected)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"网络不通" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            return;
        }
        else if(tcp.asyncSocket.isConnected)
        {
            
            NSString *requestStr = [NSString stringWithFormat:@"%@\r\n",sendMessage];
            [tcp writeString:requestStr];
            
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"TCP链接没有建立" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
        }
        
        [useTextField resignFirstResponder];
    }
}

#pragma mark -
#pragma mark ITcpClient

/**发送到服务器端的数据*/
-(void)OnSendDataSuccess:(NSString*)sendedTxt;
{
    recivedTV.text = [NSString stringWithFormat:@"%@\r\n-->发送:%@\r\n",recivedTV.text,sendedTxt];
}

/**收到服务器端发送的数据*/
-(void)OnReciveData:(NSString*)recivedTxt;
{
    recivedTV.text = [NSString stringWithFormat:@"%@\r\n-->接收:%@\r\n",recivedTV.text,recivedTxt];
}

/**socket连接出现错误*/
-(void)OnConnectionError:(NSError *)err;
{
    recivedTV.text = [NSString stringWithFormat:@"%@\r\n\r\n****网络出错! ****\r\n",recivedTV.text];
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
