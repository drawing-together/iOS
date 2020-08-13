//
//  OpenCVWrapper.h
//  DrawingTogether
//
//  Created by trycatch on 2020/05/28.
//  Copyright © 2020 hansung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+(UIImage *) cvWarp: (UIImage *) src_data w: (int) width h: (int) height src: (int *) src_triangle dst: (int *) dst_triangle;
@end

NS_ASSUME_NONNULL_END
