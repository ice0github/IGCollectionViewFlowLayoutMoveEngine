//
//  ViewController.m
//  T_CollectionMoveable
//
//  Created by GavinHe on 16/2/4.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import "ViewController.h"
#import "CollectionViewCell.h"
#import "IGCollectionViewFlowLayoutMoveEngine.h"

@interface ViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,IGCollectionViewFlowLayoutMoveDelegate>{
    UICollectionView *cvMain;
    
    NSMutableArray *datas;
    
    IGCollectionViewFlowLayoutMoveEngine *moveEngine;
    
    NSIndexPath *_reorderingCellIndexPath;
    UIView *_cellFakeView;
}
@property (nonatomic, assign) CGPoint reorderingCellCenter;
@property (nonatomic, assign) CGPoint cellFakeViewCenter;
@property (nonatomic, assign) CGPoint panTranslation;
@property (nonatomic, assign) UIEdgeInsets scrollTrigerEdgeInsets;
@property (nonatomic, assign) UIEdgeInsets scrollTrigePadding;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initData];
    [self buildUI];
}

#pragma mark - ----> 界面

- (void)buildUI{
    self.view.backgroundColor = [UIColor whiteColor];
    float itemSize = self.view.bounds.size.width*0.25-0.5;
    
    UICollectionViewFlowLayout *cvLayout = [[UICollectionViewFlowLayout alloc] init];
    cvLayout.itemSize                    = CGSizeMake(itemSize, itemSize);
    cvLayout.minimumLineSpacing          = 1;
    cvLayout.minimumInteritemSpacing     = 0.5;
    
    cvMain = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                collectionViewLayout:cvLayout];
    cvMain.backgroundColor = [UIColor grayColor];
    cvMain.delegate   = self;
    cvMain.dataSource = self;
    [self.view addSubview:cvMain];
    
    [cvMain registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:cellID];
    
    [moveEngine setupWithCollectionView:cvMain];


}

#pragma mark - ----> 数据

- (void)initData{
    datas = [NSMutableArray new];
    
    for (int i = 0 ; i < 60 ;  i++) {
        [datas addObject:[NSString stringWithFormat:@"%d",i]];
    }

    moveEngine                    = [[IGCollectionViewFlowLayoutMoveEngine alloc] init];
    moveEngine.itemSizeWhenMoving = CGSizeMake(self.view.bounds.size.width*0.33, self.view.bounds.size.width*0.33);
    moveEngine.moveDelegate       = self;
}

- (void)loadData{
    [datas removeAllObjects];
    
    for (int i = 0 ; i < 60 ;  i++) {
        [datas addObject:[NSString stringWithFormat:@"%d",i]];
    }
    
    [cvMain reloadData];
}


#pragma mark - ----> Collection Delegate


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return datas.count;
}

static NSString *cellID = @"CollectionViewCell";

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    CollectionViewCell *cell = (CollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    cell.label.text = datas[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self loadData];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < 20) {
        return CGSizeMake(self.view.bounds.size.width*0.5-1, self.view.bounds.size.width*0.5-1);
    }else{
        return CGSizeMake(self.view.bounds.size.width*0.25-1, self.view.bounds.size.width*0.25-1);
    }
}

#pragma mark - ---->  Move Delegate
// 能否移动这个Item
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < 4) {
        return NO;
    }
    return YES;
}

// 能否移动到某个Item
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath{
    if (toIndexPath.row > 7 && toIndexPath.row < 15) {
        return NO;
    }
    return YES;
}

// 将移动到某个Item到某个位置
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath{
    
}

// 已经移动某个Item到某个位置
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath{
    [datas exchangeObjectAtIndex:fromIndexPath.row withObjectAtIndex:toIndexPath.row];
}


@end
