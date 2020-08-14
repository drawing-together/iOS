//
//  OpenCVWrapper.m
//  DrawingTogether
//
//  Created by trycatch on 2020/05/28.
//  Copyright © 2020 hansung. All rights reserved.
//
#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"
#import <opencv2/imgcodecs/ios.h>
#include <opencv2/imgproc.hpp>
#include <stdio.h>

#include <opencv2/core/types_c.h>
#include <opencv2/core/core_c.h>
#include <opencv2/imgproc/imgproc_c.h>
using namespace cv;
using namespace std;


@implementation OpenCVWrapper

+(UIImage *) cvWarp: (UIImage *) src_data w: (int) width h: (int) height src: (int*) src_triangle dst: (int*) dst_triangle {
//    int triangle_count = src_triangle_size/6;
//
//    int *src_triangle_ptr = src_triangle;
//    int *dst_triangle_ptr = dst_triangle;

    Mat imageMat;

    UIImageToMat(src_data, imageMat);
    resize(imageMat, imageMat, Size2d(width, height));
    Size2d size = imageMat.size();

    IplImage *src  = cvCreateImage(cvSize(size.width, size.height), IPL_DEPTH_8U, 4);
    src->imageData = (char *) imageMat.data;

    IplImage *warp = cvCreateImage(cvSize(size.width, size.height), IPL_DEPTH_8U, 4);
    int warp_data[(int)(size.width * size.height)];
    int *warp_ptr = warp_data;
    warp->imageData = (char *) warp_ptr;

    IplImage *buf = cvCreateImage(cvGetSize(warp),IPL_DEPTH_8U,4);
    IplImage *buf2 = cvCreateImage(cvGetSize(warp),IPL_DEPTH_8U,4);

    CvPoint2D32f srcTri[3], dstTri[3];
    CvMat *warp_mat = cvCreateMat(2,3,CV_32FC1);

    CvPoint **pts;
    pts = (CvPoint **) malloc (sizeof (CvPoint *) * 2);
    pts[0] = (CvPoint *) malloc (sizeof (CvPoint) * 3);
    int npts[1] = {3};


    Rect2d rect(0, 0, size.width, size.height);
    Subdiv2D subdiv(rect);

    vector<Point2f> points;
    points.push_back(Point2f(0, 0));
    points.push_back(Point2f(size.width-1, 0));
    points.push_back(Point2f(size.width-1, size.height-1));
    points.push_back(Point2f(0, size.height-1));
    points.push_back(Point2f(src_triangle[0], src_triangle[1]));

    for( vector<Point2f>::iterator it = points.begin(); it != points.end(); it++) {
        subdiv.insert(*it);
    }

    vector<Vec6f> triangleList;
    subdiv.getTriangleList(triangleList);
    vector<int> pt;
//    Subdiv2D subdiv2(rect);
//
//    vector<Point2f> points2;
//    points2.push_back(Point2f(0, 0));
//    points2.push_back(Point2f(size.width-1, 0));
//    points2.push_back(Point2f(size.width-1, size.height-1));
//    points2.push_back(Point2f(0, size.height-1));
//    points2.push_back(Point2f(dst_triangle[0], dst_triangle[1]));
//
//    for( vector<Point2f>::iterator it = points2.begin(); it != points2.end(); it++) {
//        subdiv2.insert(*it);
//    }

    vector<Vec6f> triangleList2;
//    subdiv2.getTriangleList(triangleList2);
    vector<int> pt2;

    for( size_t i = 0; i < triangleList.size(); i++ ){
        Vec6f t = triangleList[i];
        Vec6f t2;
        for (int j = 0; j < 6; j++) {
            if (j % 2 == 0 && t[j] == src_triangle[0]) {
                t[j] = dst_triangle[0];
            }
            else if (j % 2 == 1 && t[j] == src_triangle[1]) {
                t[j] = dst_triangle[1];
            }
        }
        triangleList2.push_back(t);
    }

    for( size_t i = 0; i < triangleList.size(); i++ ){
        Vec6f t = triangleList[i];
        Vec6f t2 = triangleList2[i];
        pt.push_back(cvRound(t[0]));
        pt.push_back(cvRound(t[1]));
        pt.push_back(cvRound(t[2]));
        pt.push_back(cvRound(t[3]));
        pt.push_back(cvRound(t[4]));
        pt.push_back(cvRound(t[5]));

        pt2.push_back(cvRound(t2[0]));
        pt2.push_back(cvRound(t2[1]));
        pt2.push_back(cvRound(t2[2]));
        pt2.push_back(cvRound(t2[3]));
        pt2.push_back(cvRound(t2[4]));
        pt2.push_back(cvRound(t2[5]));
    }

    for(int i=0; i<triangleList.size(); i++){

        srcTri[0].x = pt[i*6];
        srcTri[0].y = pt[i*6+1];
        srcTri[1].x = pt[i*6+2];
        srcTri[1].y = pt[i*6+3];
        srcTri[2].x = pt[i*6+4];
        srcTri[2].y = pt[i*6+5];

        dstTri[0].x = pts[0][0].x = pt2[i*6];
        dstTri[0].y = pts[0][0].y = pt2[i*6+1];
        dstTri[1].x = pts[0][1].x = pt2[i*6+2];
        dstTri[1].y = pts[0][1].y = pt2[i*6+3];
        dstTri[2].x = pts[0][2].x = pt2[i*6+4];
        dstTri[2].y = pts[0][2].y = pt2[i*6+5];

        int x = (srcTri[0].x<dstTri[0].x)?srcTri[0].x:dstTri[0].x;
        int y = (srcTri[0].y<dstTri[0].y)?srcTri[0].y:dstTri[0].y;
        int w = (srcTri[0].x>dstTri[0].x)?srcTri[0].x:dstTri[0].x;
        int h = (srcTri[0].y>dstTri[0].y)?srcTri[0].y:dstTri[0].y;

        for(int k=1; k<3 ; k++){
            if(x > srcTri[k].x)
                x = srcTri[k].x;
            if(y > srcTri[k].y)
                y = srcTri[k].y;
            if(x > dstTri[k].x)
                x = dstTri[k].x;
            if(y > dstTri[k].y)
                y = dstTri[k].y;

            if(w < srcTri[k].x)
                w = srcTri[k].x;
            if(h < srcTri[k].y)
                h = srcTri[k].y;
            if(w < dstTri[k].x)
                w = dstTri[k].x;
            if(h < dstTri[k].y)
                h = dstTri[k].y;
        }

        srcTri[0].x = srcTri[0].x -x;
        srcTri[0].y = srcTri[0].y -y;
        srcTri[1].x = srcTri[1].x -x;
        srcTri[1].y = srcTri[1].y -y;
        srcTri[2].x = srcTri[2].x -x;
        srcTri[2].y = srcTri[2].y -y;

        dstTri[0].x = dstTri[0].x -x;
        dstTri[0].y = dstTri[0].y -y;
        dstTri[1].x = dstTri[1].x -x;
        dstTri[1].y = dstTri[1].y -y;
        dstTri[2].x = dstTri[2].x -x;
        dstTri[2].y = dstTri[2].y -y;

        pts[0][0].x = dstTri[0].x;
        pts[0][0].y = dstTri[0].y;
        pts[0][1].x = dstTri[1].x;
        pts[0][1].y = dstTri[1].y;
        pts[0][2].x = dstTri[2].x;
        pts[0][2].y = dstTri[2].y;

        cvSetImageROI(src,cvRect(x,y,w+1,h+1));
        cvSetImageROI(buf,cvRect(x,y,w+1,h+1));
        cvSetImageROI(buf2,cvRect(x,y,w+1,h+1));
        cvSetImageROI(warp,cvRect(x,y,w+1,h+1));

        cvGetAffineTransform(srcTri,dstTri,warp_mat);
        cvWarpAffine(src,buf,warp_mat);

        cvZero(buf2);
        cvFillPoly (buf2, pts, npts, 1, cvScalar(255,255,255,255),8,0);
        cvFillPoly(warp,pts,npts,1,cvScalar(0,0,0,0),8,0);

        cvAnd(buf2,buf,buf,NULL);
        cvOr(buf,warp,warp,NULL);
    }

    free(pts[0]);
    free(pts);
    cvReleaseImage(&buf);
    cvReleaseImage(&buf2);
    cvResetImageROI(warp);
//    env->ReleaseIntArrayElements(warp_data, warp_ptr, JNI_ABORT);
//    env->ReleaseIntArrayElements(src_triangle, src_triangle_ptr, JNI_ABORT);
//    env->ReleaseIntArrayElements(dst_triangle, dst_triangle_ptr, JNI_ABORT);
//    env->ReleaseIntArrayElements(src_data, src_ptr, JNI_ABORT);


    return MatToUIImage(cvarrToMat(warp));
}

void getIplImageBuf(IplImage *imagebuf, int *data, int width, int height){
    imagebuf->nSize = 144;
    imagebuf->ID = 0;
    imagebuf->nChannels = 4;
    imagebuf->alphaChannel = 0;
    imagebuf->depth =8;
    imagebuf->dataOrder =0;
    imagebuf->align =4;
    imagebuf->width = width;
    imagebuf->height = height;
    imagebuf->roi = NULL;
    imagebuf->maskROI = NULL;
    imagebuf->imageId = NULL;
    imagebuf->widthStep = width *4;
    imagebuf->imageSize = height * imagebuf->widthStep;
    imagebuf->imageData = (char *) data;
    imagebuf->imageDataOrigin = NULL;

}


@end
