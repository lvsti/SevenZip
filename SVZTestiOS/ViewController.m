//
//  ViewController.m
//  SVZTestiOS
//
//  Created by Tamas Lustyik on 2015. 11. 22..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "ViewController.h"
#import <SevenZip/SevenZip.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    SVZArchive* a = [SVZArchive archiveWithURL:[NSURL fileURLWithPath:[paths[0] stringByAppendingPathComponent:@"test.7z"]]
                               createIfMissing:YES
                                         error:NULL];
    [a updateEntries:@[[SVZArchiveEntry archiveEntryWithDirectoryName:@"foo"]]
               error:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
