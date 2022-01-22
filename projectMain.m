%-------------------------------------------------------------------------
%| This is the Computer Vision PROJECT's main file.
%| From this script, all the other functions are called and to better
%| understand the pipeline, the Power Point presentation should be checked.
%-------------------------------------------------------------------------

%- The user should change the PATHS and then choose the images to stitch.
%- The user must choose between splitting or not.
%- The user can manually change the "mosaicingStrategy" while the
%  "shootingOrder" shouldn't impact too much on the results. 
%- The inlier-outlier corrispondences can be shown for every homography,
%  setting "showInOutliers = true". By default only the two splitted
%  mosaics show them.
%- The final image mosaics will be saved inside the "outputMosaics" folder.
%- "resizedImages_CVToolbox" is a temporary folder that is needed for
%  running the "ImageStitchingCVToolbox_SCRIPT.m" script.
%- The "images" folder contains all the different images but the user can
%  choose them modifying the comments.
%- "vlfeat-0.9.21" folder represent the "SIFT" library, so those files are
%  also needed.
%- If needed several parameters inside this script can be changed and fine
%  tuned.
%- If the user decides to crop the final mosaic, a couple of questions must
%  be correctly answered.

clear; clc; close all;

%Add SIFT toolbox to the PATH
addpath( genpath('D:\Documenti\MATLAB_workspace\ComputerVision\ComputerVisionProject\vlfeat-0.9.21\toolbox\') );

%Load and resize the images
disp("You can choose one of the following sample folders:")
disp("1) Images taken by a Nikon Reflex (handheld or tripod")
dir('images/reflex')
disp("2) Images taken by a standard smartphone (handheld)")
dir('images/smartphone')

%Reflex images (working):
% [images, numImages, cmap] = loadImages('images/reflex/cartieraChiesa', 'jpg', 400);
% [images, numImages, cmap] = loadImages('images/reflex/chiesa', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano1', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano3', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano5', 'jpg', 300);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano6', 'jpg', 400);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano7', 'jpg', 500);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano8', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano9', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/fobbia/pano10', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/golfoMaderno','jpg', 1000); %split, left2right
% [images, numImages, cmap] = loadImages('images/reflex/golfoMaderno_correzioneProfilo', 'jpg', 1000);
[images, numImages, cmap] = loadImages('images/reflex/golfoMaderno_correzioneProfilo+upright', 'jpg', 600);
% [images, numImages, cmap] = loadImages('images/reflex/lago1', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/meccanico1', 'jpg', 1000); %best: last2first
% [images, numImages, cmap] = loadImages('images/reflex/meccanico2', 'jpg', 1000); %best: last2first
% [images, numImages, cmap] = loadImages('images/reflex/meccanico3', 'jpg', 1000); %best: last2first
% [images, numImages, cmap] = loadImages('images/reflex/meccanico4', 'jpg', 1000); 
% [images, numImages, cmap] = loadImages('images/reflex/montagneLago', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/montagneLago2', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/montagneLowContrast', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/pontile', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/porto1', 'jpg', 1000);
% [images, numImages, cmap] = loadImages('images/reflex/porto2', 'jpg', 1000);


%Smartphone images (must keep a high resolution to work):
% [images, numImages, cmap] = loadImages('images/smartphone/1', 'jpg', 1000);  
% [images, numImages, cmap] = loadImages('images/smartphone/2', 'jpg',1000);
% [images, numImages, cmap] = loadImages('images/smartphone/3', 'jpg', 1000); 
% [images, numImages, cmap] = loadImages('images/smartphone/4', 'jpg', 1000); 
% [images, numImages, cmap] = loadImages('images/smartphone/5', 'jpg', 1000); 
% [images, numImages, cmap] = loadImages('images/smartphone/fasano', 'jpg', 1000);

fprintf("Number of images to be stitched: %d", numImages);

%Ask to the user if he wants to split the mosaicing process
split = input("\nDo you want to split the mosaicing process (better if numImages > 20)? (y/n) ", 's');

%Select the "mosaicing strategy" (first2last, last2first, fromCenter)
% - It's not convenient to split and use the "fromCenter" strategy!
% - When split=='y' last2first could produce bad results, depending on
%   where the most distorted part is (H could be badly estimated)
% - The end result, if we split, also depends on how the images were shot
%   (left/up to right/down or right/down to left/up)
mosaicingStrategy = 'first2last';
shootingOrder = 'left2right'; %right2left/left2right/up2down/down2up


mosaicingOrder = getMosaicingOrder(mosaicingStrategy, shootingOrder, numImages, split);


fprintf("\nMosaicing order (strategy): ");
for i = 1:length(mosaicingOrder)
    fprintf('%d ', mosaicingOrder(i));
end

%Set the "speed" by dicreasing the number of used inliers to re-estimate
%the homography
speed = 1; %from 1 (all inliers) to 10 (10 inliers)

%Set the number of iterations and the threshold for RANSAC
numIterations = 500;
threshold = 5;

firstTime = true;
imgCount = 2;
mosaicFirst = [];
mosaicSecond = [];

for n = mosaicingOrder(2:numImages)
        
    %Check the mosaicing status 
    fprintf("✓ Image %d of %d\n",imgCount,numImages);
    imgCount = imgCount + 1;
    
    img1_RGB = images(:,:,:,n);
    if firstTime
        %Select the first image (that is a right image --> img2_single_RGB),
        %according to the choosen strategy
        img2_RGB = images(:,:,:,mosaicingOrder(1)); 
        firstTime = false;
    else
        img2_RGB = mosaic;
    end    
    
    %Take care of the splitting
    if n == ceil(numImages/2)
        if strcmp(split,'y') 
            mosaicFirst = mosaic;
            mosaic = [];
            img2_RGB = images(:,:,:,n+1);       
        end
    end
    
    %vl_sift requires images to belong to the "single" class
    img1_single = im2single(img1_RGB);
    img2_single = im2single(img2_RGB);

    %vl_sift requires images to be grayscale
    img1_single_gray = rgb2gray(img1_single);
    img2_single_gray = rgb2gray(img2_single);
    
    %Call the vl_sift function to retrieve SIFT frames and descriptors
    [f1,d1] = vl_sift(img1_single_gray);
    [f2,d2] = vl_sift(img2_single_gray);

    %Call the vl_ubcmatch function to retrieve SIFT matches and scores
    [matches, scores] = vl_ubcmatch(d1,d2);

    %Retrieve the salient points on the first (X1) and second (X2) image
    X1 = f1(1:2,matches(1,:));
    X2 = f2(1:2,matches(2,:));

    %Robust computation of the Homography matrix using RANSAC method
    showInOutliers = false;
    H = computeHomography(img1_RGB, img2_RGB, X1, X2, matches, numIterations, threshold, speed, showInOutliers);
  
    %Call the imwarp function to get the warped image (+ black area)
    %according to the previously estimated homography
    [warpedImage_R, bb_R , ~ ] = imwarp_prof(img2_RGB(:,:,1),inv(H), 'linear', 'valid');
    [warpedImage_G, bb_G , ~ ] = imwarp_prof(img2_RGB(:,:,2),inv(H), 'linear', 'valid');
    [warpedImage_B, bb_B , ~ ] = imwarp_prof(img2_RGB(:,:,3),inv(H), 'linear', 'valid');

    %Call the adjustSizes function to match sizes between the warped
    %and the fixed image
    [corners_R, bb_ij_R] = adjustSizes(img1_RGB(:,:,1), bb_R);
    [corners_G, bb_ij_G] = adjustSizes(img1_RGB(:,:,2), bb_G);
    [corners_B, bb_ij_B] = adjustSizes(img1_RGB(:,:,3), bb_B);

    %Call the getMosaic function to merge the two matching size images
    [mosaic_ref_R, mosaic_mov_R] = getMosaic(corners_R, bb_ij_R, img1_RGB(:,:,1), warpedImage_R);
    [mosaic_ref_G, mosaic_mov_G] = getMosaic(corners_G, bb_ij_G, img1_RGB(:,:,2), warpedImage_G);
    [mosaic_ref_B, mosaic_mov_B] = getMosaic(corners_B, bb_ij_B, img1_RGB(:,:,3), warpedImage_B);  
    
    %"Color blending easy", could be improved:
    mosaic_R = colorBlendingEasy(mosaic_ref_R,mosaic_mov_R);
    mosaic_G = colorBlendingEasy(mosaic_ref_G,mosaic_mov_G);    
    mosaic_B = colorBlendingEasy(mosaic_ref_B,mosaic_mov_B);    
    
    %Crop the mosaic in order to minimize the "black space" (NaN pixels)
    [mosaic_R, mosaic_G, mosaic_B] = minimizeBlackSpace(mosaic_R, mosaic_G, mosaic_B);
     
    %Merge the channels together to compose a RGB mosaic
    clear mosaic;
    mosaic(:,:,1) = uint8(mosaic_R);
    mosaic(:,:,2) = uint8(mosaic_G);
    mosaic(:,:,3) = uint8(mosaic_B);

    %Do image warping (this script was provided by the SIFT developers,
    %during programming as a reference). Also, to now use this function
    %the overall script should be modified and checked. So, it is left here
    %just for curiosity/future developments.
    %mosaic = imageWarpCopied(img1_single,img2_single,H); %SIFT
    
    %To check mosaicing progress:    
    figure(10); clf; imshow(mosaic); 
end

%If the user decided to split (in half) the mosaicing process
if strcmp(split, 'y')
    %Show the first mosaic
    figFirstPart = figure('WindowState','maximized');
    imagesc(mosaicFirst); axis image off;
    title('Mosaic first part');
    
    %Show the second mosaic
    figSecondPart = figure('WindowState','maximized');
    mosaicSecond = mosaic;
    imagesc(mosaicSecond); axis image off;
    title('Mosaic second part');
    
    %Save the first and second part mosaics as .png    
    exportgraphics(figFirstPart,'outputMosaics/firstPartMosaic.png');
    exportgraphics(figSecondPart,'outputMosaics/secondPartMosaic.png');
    
    %Estimate the homography between the left and right mosaics
    %vl_sift requires images to belong to the "single" class
    img1_single = im2single(mosaicFirst); img2_single = im2single(mosaicSecond);

    %vl_sift requires images to be grayscale
    img1_single_gray = rgb2gray(img1_single); img2_single_gray = rgb2gray(img2_single);

    %Call the vl_sift function to retrieve SIFT frames and descriptors
    [f1,d1] = vl_sift(img1_single_gray); [f2,d2] = vl_sift(img2_single_gray);

    %Call the vl_ubcmatch function to retrieve SIFT matches and scores
    [matches, scores] = vl_ubcmatch(d1,d2);

    %Retrieve the salient points on the first (X1) and second (X2) image
    X1 = f1(1:2,matches(1,:)); X2 = f2(1:2,matches(2,:));

    %Robust computation of the Homography matrix using RANSAC method
    showInOutliers = true;
    numIterations = 2000;
    speed = 1; %use, in this case, the max. number of inliers
    threshold = 5; %increase the threshold to accept more inliers (high warping)
    H = computeHomography(mosaicFirst, mosaicSecond, X1, X2, matches, numIterations, threshold, speed, showInOutliers);
    
    %Call the imwarp_prof function to get the warped image (+ black area)
    %according to the previously estimated homography
    [warpedImage_R, bb_R , ~ ] = imwarp_prof(mosaicSecond(:,:,1),inv(H), 'linear', 'valid');
    [warpedImage_G, bb_G , ~ ] = imwarp_prof(mosaicSecond(:,:,2),inv(H), 'linear', 'valid');
    [warpedImage_B, bb_B , ~ ] = imwarp_prof(mosaicSecond(:,:,3),inv(H), 'linear', 'valid');

    %Call the adjustSizes function to match sizes between the warped
    %and the fixed image
    [corners_R, bb_ij_R] = adjustSizes(mosaicFirst(:,:,1), bb_R);
    [corners_G, bb_ij_G] = adjustSizes(mosaicFirst(:,:,2), bb_G);
    [corners_B, bb_ij_B] = adjustSizes(mosaicFirst(:,:,3), bb_B);

    %Call the getMosaic function to merge the two matching size images
    [mosaic_ref_R, mosaic_mov_R] = getMosaic(corners_R, bb_ij_R, mosaicFirst(:,:,1), warpedImage_R);
    [mosaic_ref_G, mosaic_mov_G] = getMosaic(corners_G, bb_ij_G, mosaicFirst(:,:,2), warpedImage_G);
    [mosaic_ref_B, mosaic_mov_B] = getMosaic(corners_B, bb_ij_B, mosaicFirst(:,:,3), warpedImage_B);  
    
    %"Color blending easy", could be improved:
    mosaic_R = colorBlendingEasy(mosaic_ref_R,mosaic_mov_R);
    mosaic_G = colorBlendingEasy(mosaic_ref_G,mosaic_mov_G);    
    mosaic_B = colorBlendingEasy(mosaic_ref_B,mosaic_mov_B);    
    
    %Crop the mosaic in order to minimize the "black space"
    [mosaic_R, mosaic_G, mosaic_B] = minimizeBlackSpace(mosaic_R, mosaic_G, mosaic_B);
    
    %Merge the channels together to compose a RGB mosaic
    clear mosaic; 
    fullMosaic_L_R(:,:,1) = uint8(mosaic_R);
    fullMosaic_L_R(:,:,2) = uint8(mosaic_G);
    fullMosaic_L_R(:,:,3) = uint8(mosaic_B);
    
    mosaic = fullMosaic_L_R;
    
    %Show the full mosaic
    figMosaic = figure('WindowState','maximized');
    imagesc(fullMosaic_L_R);
    axis image off; title('Full mosaic (First+Second)');
    
    %Save the mosaic figure as a .png
    exportgraphics(figMosaic,'outputMosaics/FullMosaic.png');
else
    figMosaic = figure('WindowState','maximized');
    imagesc(mosaic); axis image off;
    title('Full mosaic');

    %Save the mosaic figure as a .png
    exportgraphics(figMosaic,'outputMosaics/FullMosaic.png');
end


%Show and save also the cropped version of the mosaic, if requested
doCrop = input("Do you want to crop the image, if so 2 questions must be answereed? (y/n) ",'s');
if(strcmp(doCrop, 'y'))
    panoramaOrientation = input("Is this a vertical or horizontal panorama? (V/H) ",'s');
    if(strcmp(panoramaOrientation, 'V'))
        minDistortion = input("Where is the minimum distortion inside the image? (up/center/down) ",'s');
    else
        minDistortion = input("Where is the minimum distortion inside the image? (left/center/right) ",'s');
    end
    %Crop the image and show it
    croppedMosaic = cropMosaic(mosaic, panoramaOrientation, minDistortion);
    figCropped = figure('WindowState','maximized'); 
    imshow(croppedMosaic); title('Cropped mosaic');
    
    %Save the cropped mosaic figure as a .png
    exportgraphics(figCropped,'outputMosaics/CroppedMosaic.png');
end
close(figure(10));

