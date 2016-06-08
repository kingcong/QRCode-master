//
//  ViewController.m
//  QRCode
//
//  Created by 王聪 on 16/5/22.
//  Copyright © 2016年 王聪. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeViewController.h"

@interface ViewController () <QRCodeViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)scanCode:(UIButton *)sender {
    
    QRCodeViewController *qrVc = [[QRCodeViewController alloc] init];
    qrVc.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qrVc];
    
    // 设置扫描完成后的回调
    __weak typeof (self) wSelf = self;
    [qrVc setCompletionWithBlock:^(NSString *resultAsString) {
        [wSelf.navigationController popViewControllerAnimated:YES];
//        [[[UIAlertView alloc] initWithTitle:@"" message:resultAsString delegate:self cancelButtonTitle:@"好的" otherButtonTitles: nil] show];
    }];
    
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - 代理方法

- (void)reader:(QRCodeViewController *)reader didScanResult:(NSString *)result
{
    NSLog(@"%@",result);
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QRCodeController" message:result delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }];
}

@end
