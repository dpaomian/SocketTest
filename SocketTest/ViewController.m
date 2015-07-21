//
//  ViewController.m
//  SocketTest
//
//  Created by mac on 15/7/20.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "ViewController.h"
#import "TcpViewController.h"
#import "UdpViewController.h"

@interface ViewController ()
{
    
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
    }
    
    self.title = @"主界面";
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    btn1.frame = CGRectMake(20, 65, 200, 40);
    btn1.backgroundColor = [UIColor purpleColor];
    [btn1 setTitle:@"Tcp 模式1" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    btn1.tag = 100;
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    btn2.frame = CGRectMake(20, 115, 200, 40);
    btn2.backgroundColor = [UIColor purpleColor];
    [btn2 setTitle:@"Udp 模式2" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    btn2.tag = 101;
    [self.view addSubview:btn2];
}

-(void)btnClick:(UIButton *)sender
{
    switch (sender.tag)
    {
        case 100:
        {
            TcpViewController *vc = [[TcpViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 101:
        {
            UdpViewController *vc = [[UdpViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
