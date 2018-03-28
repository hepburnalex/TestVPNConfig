//
//  ViewController.m
//  TestVPNConfig
//
//  Created by Hepburn on 2018/3/22.
//  Copyright © 2018年 Hepburn. All rights reserved.
//

#import "ViewController.h"
#import <NetworkExtension/NetworkExtension.h>

#import "ConfigVPN.h"

@interface ViewController ()
{
    UIWebView *mWebView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    mWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    mWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:mWebView];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(50, 50, 150, 50);
    btn.backgroundColor = [UIColor blueColor];
    [btn setTitle:@"Google" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(OnButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [[ConfigVPN shareManager] connectVPN];
    //[self OnButtonClick];
}

- (void)OnButtonClick
{
    NSString *urlstr = @"https://www.google.com";
    [mWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlstr]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
