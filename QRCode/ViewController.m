//
//  ViewController.m
//  QRCode
//
//  Created by 王聪 on 16/5/22.
//  Copyright © 2016年 王聪. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)scanCode:(UIButton *)sender {
    
    QRCodeViewController *qrVc = [[QRCodeViewController alloc] init];
    qrVc.view.backgroundColor = [UIColor clearColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qrVc];
    
    [self presentViewController:nav animated:YES completion:nil];
}

@end
