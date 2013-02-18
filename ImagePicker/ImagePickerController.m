/*****************************************************************************
 *
 * FILE:	ImagePickerController.m
 * DESCRIPTION:	ImagePicker: Image Picker Controller using Assets Library
 * DATE:	Mon, Feb 11 2013
 * UPDATED:	Mon, Feb 18 2013
 * AUTHOR:	Kouichi ABE (WALL) / 阿部康一
 * E-MAIL:	kouichi@MagickWorX.COM
 * URL:		http://www.iPhone.MagickWorX.COM/
 * COPYRIGHT:	(c) 2013 阿部康一／Kouichi ABE (WALL), All rights reserved.
 * LICENSE:
 *
 *  Copyright (c) 2013 Kouichi ABE (WALL) <kouichi@MagickWorX.COM>,
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 *   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
 *   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *   INTERRUPTION)  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 *   THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: ImagePickerController.m,v 1.2 2013/02/14 14:56:26 kouichi Exp $
 *
 *****************************************************************************/

#import <AssetsLibrary/AssetsLibrary.h>
#import "ImagePickerController.h"

#define	kThumbnailWidth		75.0f
#define	kThumbnailHeight	75.0f
#define	kAssetCellWidth		(kThumbnailWidth  + 2.0f * 2.0f)
#define	kAssetCellHeight	(kThumbnailHeight + 2.0f * 2.0f)

/******************************************************************************
 *
 *	AssetsCollectionCell
 *
 *****************************************************************************/
@interface AssetsCollectionCell : UICollectionViewCell
{
@private
  UIImageView *	_imageView;
  UILabel *	_textLabel;
}
@property (nonatomic,retain,readonly) UIImageView *	imageView;
@property (nonatomic,retain,readonly) UILabel *		textLabel;
@end

@interface AssetsCollectionCell ()
@property (nonatomic,retain,readwrite) UIImageView *	imageView;
@property (nonatomic,retain,readwrite) UILabel *	textLabel;
@end

@implementation AssetsCollectionCell

@synthesize	imageView	= _imageView;
@synthesize	textLabel	= _textLabel;

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    CGFloat	x = 2.0f;
    CGFloat	y = 2.0f;
    CGFloat	w = kThumbnailWidth;
    CGFloat	h = kThumbnailHeight;

    UIImageView *	imageView;
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView setClipsToBounds:YES];
    [self.contentView addSubview:imageView];
    self.imageView = imageView;
    [imageView release];

    UILabel *	textLabel;
    textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:textLabel];
    self.textLabel = textLabel;
    [textLabel release];
  }
  return self;
}

-(void)dealloc
{
  [_imageView release];
  [_textLabel release];
  [super dealloc];
}

-(void)prepareForReuse
{
  [super prepareForReuse];

  self.imageView.image	= nil;
  self.textLabel.text	= nil;
}

@end

/******************************************************************************
 *
 *	AssetsPickerController
 *
 *****************************************************************************/
static NSString * assetsCellIdentifier = @"AssetsCollectionCellIdentifier";

@interface AssetsPickerController : UICollectionViewController
{
@private
  ImagePickerSelectHandler	_selectHandler;
}
@property (nonatomic,copy) ImagePickerSelectHandler	selectHandler;
-(id)initWithAssetsGroup:(ALAssetsGroup *)group;
@end

@interface AssetsPickerController ()
{
@private
  ALAssetsGroup *	_group;
  NSMutableArray *	_assets;
}
@property (nonatomic,retain) ALAssetsGroup *	group;
@property (nonatomic,retain) NSMutableArray *	assets;
@end

@implementation AssetsPickerController

@synthesize	selectHandler	= _selectHandler;
@synthesize	group	= _group;
@synthesize	assets	= _assets;

-(id)initWithAssetsGroup:(ALAssetsGroup *)group
{
  UICollectionViewFlowLayout *	layout;
  layout = [[UICollectionViewFlowLayout alloc] init];
  layout.minimumLineSpacing = 0.0f;
  layout.minimumInteritemSpacing = 0.0f;
  layout.itemSize = CGSizeMake(kAssetCellWidth, kAssetCellHeight);
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.sectionInset = UIEdgeInsetsMake(2.0f, 2.0f, 2.0f, 2.0f);

  self = [super initWithCollectionViewLayout:layout];
  if (self) {
    self.group = group;
    [self.collectionView registerClass:[AssetsCollectionCell class]
			 forCellWithReuseIdentifier:assetsCellIdentifier];
    _assets = [[NSMutableArray alloc] init];
  }

  [layout release];

  return self;
}

-(void)dealloc
{
  [_selectHandler release];
  [_group release];
  [_assets release];
  [super dealloc];
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  __block AssetsPickerController *	weakSelf = self;

  ALAssetsGroupEnumerationResultsBlock	resultsBlock = ^(ALAsset * result, NSUInteger index, BOOL * stop) {
    if (result) {
	[weakSelf.assets addObject:result];
      dispatch_async(dispatch_get_main_queue(), ^{
	[weakSelf.collectionView reloadData];
      });
    }
  };
  dispatch_block_t	block = ^{
    [weakSelf.group setAssetsFilter:[ALAssetsFilter allPhotos]];
    [weakSelf.group enumerateAssetsUsingBlock:resultsBlock];
  };
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
}

/*****************************************************************************/

#pragma mark UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}

#pragma mark UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView
	numberOfItemsInSection:(NSInteger)section
{
  return [_assets count];
}

#pragma mark UICollectionViewDataSource
/*
 * The cell that is returned must be retrieved from a call to
 * -dequeueReusableCellWithReuseIdentifier:forIndexPath:
 */
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
	cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  AssetsCollectionCell *	cell;
  cell = (AssetsCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:assetsCellIdentifier forIndexPath:indexPath];

  ALAsset *	asset	= [self.assets objectAtIndex:[indexPath row]];
  UIImage *	image	= [UIImage imageWithCGImage:[asset thumbnail]];
  cell.imageView.image	= image; 

  return cell;
}


#pragma mark UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView
	didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *	cell = [collectionView cellForItemAtIndexPath:indexPath];
  cell.contentView.backgroundColor = [UIColor blueColor];
}

#pragma mark UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView
	didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *	cell = [collectionView cellForItemAtIndexPath:indexPath];
  cell.contentView.backgroundColor = nil;
}

#pragma mark UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView
	didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_selectHandler) {
    /*
     * XXX:
     * ALAssetRepresentation *	representation = [asset defaultRepresentation];
     *
     * 画像のオリジナルを利用したい場合は、fullResolutionImage を使う。
     * [UIImage imageWithCGImage:[representation fullResolutionImage]];
     *
     * デバイスの画面サイズに合わせる場合は、fullScreenImage を使う。
     * [UIImage imageWithCGImage:[representation fullScreenImage]];
     *
     * [representation dimensions] で返る CGSize は fullResolutionImage の
     * 画像サイズと同じ。
     *
     */
    ALAsset *	asset = [self.assets objectAtIndex:[indexPath row]];
    UIImage *	image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
    if (image) {
      _selectHandler(image);
    }
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

@end

/******************************************************************************
 *
 *	ImagePickerController
 *
 *****************************************************************************/
@interface ImagePickerController ()
{
@private
  ALAssetsLibrary *	_assetsLibrary;
  NSMutableArray *	_assetsGroup;
}
@property (nonatomic,retain) ALAssetsLibrary *	assetsLibrary;
@property (nonatomic,retain) NSMutableArray *	assetsGroup;
@end

@implementation ImagePickerController

@synthesize	selectHandler	= _selectHandler;
@synthesize	assetsLibrary	= _assetsLibrary;
@synthesize	assetsGroup	= _assetsGroup;

-(id)init
{
  self = [super init];
  if (self) {
    self.title	= NSLocalizedString(@"ImagePicker", @"");

    ALAssetsLibrary *	assetsLibrary;
    assetsLibrary = [[ALAssetsLibrary alloc] init];
    self.assetsLibrary = assetsLibrary;
    [assetsLibrary release];

    _assetsGroup = [[NSMutableArray alloc] init];
  }
  return self;
}

-(void)dealloc
{
  [_selectHandler release];
  [_assetsLibrary release];
  [_assetsGroup release];
  [super dealloc];
}

-(void)didReceiveMemoryWarning
{
  /*
   * Invoke super's implementation to do the Right Thing,
   * but also release the input controller since we can do that.
   * In practice this is unlikely to be used in this application,
   * and it would be of little benefit,
   * but the principle is the important thing.
   */
  [super didReceiveMemoryWarning];
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  __block ImagePickerController *	weakSelf = self;

  UITableView *	tableView;
  tableView = [[UITableView alloc]
		initWithFrame:self.view.bounds
		style:UITableViewStylePlain];
  tableView.dataSource	= self;
  tableView.delegate	= self;
  tableView.rowHeight	= 90.0f;
  tableView.autoresizingMask	= UIViewAutoresizingFlexibleWidth
				| UIViewAutoresizingFlexibleHeight;
  self.tableView = tableView;
  [tableView release];


  ALAssetsLibraryGroupsEnumerationResultsBlock	resultsBlock = ^(ALAssetsGroup * group, BOOL * stop) {
    if (group) {
      [group setAssetsFilter:[ALAssetsFilter allPhotos]];
      if ([group numberOfAssets] > 0) {	// 上記フィルターに適合した数
	[weakSelf.assetsGroup addObject:group];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
	[weakSelf.tableView reloadData];
      });
    }
  };
  ALAssetsLibraryAccessFailureBlock	failureBlock = ^(NSError * error) {
  };
  dispatch_block_t	block = ^{
    ALAssetsGroupType	groupType = ALAssetsGroupLibrary
				  | ALAssetsGroupAlbum
				  | ALAssetsGroupSavedPhotos
				  | ALAssetsGroupPhotoStream;
    [weakSelf.assetsLibrary enumerateGroupsWithTypes:groupType
			    usingBlock:resultsBlock
			    failureBlock:failureBlock];
  };
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
}

/*****************************************************************************/

#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
  return [_assetsGroup count];
}

#pragma mark UITableViewDataSource
-(UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *	cellIdentifier = @"ImagePickerTableCellIdentifier";

  UITableViewCell *	cell;
  cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc]
	    initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:cellIdentifier];
    [cell autorelease];
  }
  cell.accessoryType	= UITableViewCellAccessoryDisclosureIndicator;

  ALAssetsGroup *	group = [_assetsGroup objectAtIndex:[indexPath row]];

  cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)",
				  [group valueForProperty:ALAssetsGroupPropertyName],
				  [group numberOfAssets]];
  cell.imageView.image = [UIImage imageWithCGImage:[group posterImage]];

  return cell;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  ALAssetsGroup *	group = [_assetsGroup objectAtIndex:[indexPath row]];

  NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];

  AssetsPickerController *	viewController;
  viewController = [[AssetsPickerController alloc] initWithAssetsGroup:group];
  viewController.title = [group valueForProperty:ALAssetsGroupPropertyName];
  viewController.selectHandler = self.selectHandler;
  [self.navigationController pushViewController:viewController animated:YES];
  [viewController release];

  [pool drain];
}

@end
