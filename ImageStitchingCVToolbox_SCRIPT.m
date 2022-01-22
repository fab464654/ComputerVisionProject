%-------------------------------------------------------------------------
%| This script is the "translation" from the Tutorial's LiveScript to a  
%| normal MATLAB script.
%-------------------------------------------------------------------------

% Feature Based Panoramic Image Stitching 
% Notice: I took this example from the MATLAB website. This tutorial shows how to use the Computer Vision Toolbox for panoramic image stitching. I did some modifications in order to load my images and use my homography estimation code (while image warping is performed by the tutorial).

clear; close all; clc;


%Add SIFT toolbox to the PATH
addpath( genpath('D:\Documenti\MATLAB_workspace\ComputerVision\ComputerVisionProject\vlfeat-0.9.21\toolbox\') );


% Ask the user to choose an option:
% 1 --> SIFT + myHomography estimation + C.V.Toolbox mosaicing
% 2 --> SIFT + C.V.Toolbox homography  + C.V.Toolbox mosaicing
% 3 --> SURF + C.V.Toolbox homography  + C.V.Toolbox mosaicing
pipeline = -1;
while pipeline < 1 || pipeline > 3
    pipeline = input("Choose one of the following three pipelines to use:\n"...
               +"1 --> SIFT + myHomography estimation + C.V.Toolbox mosaicing\n"...
               +"2 --> SIFT + C.V.Toolbox homography  + C.V.Toolbox mosaicing\n"...
               +"3 --> SURF + C.V.Toolbox homography  + C.V.Toolbox mosaicing\n  --> ");
end

% || Step 1 - Load Images ||
% Load the images.
imgDir = fullfile('images/smartphone/2');
buildingScene_temp = imageDatastore(imgDir);
imgCounter = 0;

% Write the resized images inside a new folder called
% "resizedImages_CVToolbox"; this is needed by the livescript that, by
% default would update the full resolution images with the resized
% ones. And this is not a good behavior in my opinion.
if ~exist('resizedImages_CVToolbox', 'dir')
   mkdir('resizedImages_CVToolbox');
else
    rmdir('resizedImages_CVToolbox','s'); %to avoid problems
    mkdir('resizedImages_CVToolbox');
end
    
% Resize the images:
maxSize = 1000;
while hasdata(buildingScene_temp)
    imgCounter = imgCounter + 1;
    
    % Read the image
    [currentImage,info] = read(buildingScene_temp);   % get the File info
    % Resize the image  
    if size(currentImage,1) > size(currentImage,2) %vertical
        currentImage = imresize(currentImage, [maxSize, NaN]);
    else
        currentImage = imresize(currentImage, [NaN, maxSize]);
    end

    splitted = strsplit(info.Filename,'\');
    imgName = splitted(length(splitted)); %get the image name
    imwrite(currentImage,strcat("resizedImages_CVToolbox/",imgName));        
end

% Update the whole DataStore
buildingScene = imageDatastore("resizedImages_CVToolbox");

% Display images to be stitched.
montage(buildingScene.Files)


    
 

% || Step 2 - Register Image Pairs ||

% Read the first image from the image set.
I = readimage(buildingScene,1);

% Initialize features for I(1), using SURF just for the first image
grayImage = im2gray(I);
points = detectSURFFeatures(grayImage);
[features, points] = extractFeatures(grayImage,points);

% Initialize all the transforms to the identity matrix. Note that the
% projective transform is used here because the building images are fairly
% close to the camera. Had the scene been captured from a further distance,
% an affine transform would suffice.
numImages = numel(buildingScene.Files);

tforms(numImages) = projective2d(eye(3));

% Initialize variable to hold image sizes.
imageSize = zeros(numImages,2);

% Iterate over remaining image pairs
for n = 2:numImages
    
    % Store points and features for I(n-1).
    pointsPrevious = points;
    featuresPrevious = features;
        
    % Read I(n).
    I = readimage(buildingScene, n);
    I_prev = readimage(buildingScene, n-1); %added to show inliers
    
    % TO USE SIFT:
    if(pipeline == 1 || pipeline == 2)
        %vl_sift requires images to belong to the "single" class
        img1_single = im2single(I_prev);
        img2_single = im2single(I);

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

        % Save image size.
        imageSize(n,:) = size(img1_single_gray);
    end
    %----------------------------------------------


    % TO USE SURF: 
    if(pipeline == 3)
        % Convert image to grayscale.
        grayImage = im2gray(I); 

        % Save image size.
        imageSize(n,:) = size(grayImage);

        % Detect and extract SURF features for I(n).
        points = detectSURFFeatures(grayImage);    
        [features, points] = extractFeatures(grayImage, points);

        % Find correspondences between I(n) and I(n-1).
        indexPairs = matchFeatures(features, featuresPrevious, 'Unique', true);

        matchedPoints = points(indexPairs(:,1), :);
        matchedPointsPrev = pointsPrevious(indexPairs(:,2), :);  
        X2 = (matchedPoints.Location).';
        X1 = (matchedPointsPrev.Location).';
        matches = indexPairs.';
    end
    %----------------------------------------------    
    
    % Estimate the transformation between I(n) and I(n-1).

    %TO ESTIMATE THE HOMOGRAPHY WITH MATLAB (FOR SURF NOTATION):
    if(pipeline == 3)
        tforms(n) = estimateGeometricTransform2D(matchedPoints, matchedPointsPrev,...
            'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);
    end
    %----------------------------------------------


    %TO ESTIMATE THE HOMOGRAPHY WITH MATLAB (FOR SIFT NOTATION):
    if(pipeline == 2)
       %Robust computation of the Homography matrix using RANSAC method  
       tforms(n) = estimateGeometricTransform2D(X2.', X1.',...
                   'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);    
    end
    %----------------------------------------------    

    %TO ESTIMATE THE HOMOGRAPHY WITH MY CODE:
    if(pipeline == 1)
        numIterations = 1000;
        threshold = 2;
        speed = 1;
        showInOutliers = false;    

        H = computeHomography(I, I_prev, X2, X1, matches, numIterations, threshold, speed, showInOutliers);

        tforms(n) = projective2d(H.'); %NECESSARY DUE TO THE USED FUNCTION
    end
    %----------------------------------------------

    % Compute T(n) * T(n-1) * ... * T(1)
    tforms(n).T = tforms(n).T * tforms(n-1).T;
end

% At this point, all the transformations in tforms are relative to the first image. This was a convenient way to code the image registration procedure because it allowed sequential processing of all the images. However, using the first image as the start of the panorama does not produce the most aesthetically pleasing panorama because it tends to distort most of the images that form the panorama. A nicer panorama can be created by modifying the transformations such that the center of the scene is the least distorted. This is accomplished by inverting the transform for the center image and applying that transform to all the others.
% Start by using the projective2d outputLimits method to find the output limits for each transform. The output limits are then used to automatically find the image that is roughly in the center of the scene.
% Compute the output limits for each transform.
for i = 1:numel(tforms)           
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(i,2)], [1 imageSize(i,1)]);    
end

% Next, compute the average X limits for each transforms and find the image that is in the center. Only the X limits are used here because the scene is known to be horizontal. If another set of images are used, both the X and Y limits may need to be used to find the center image.
avgXLim = mean(xlim, 2);
[~,idx] = sort(avgXLim);
centerIdx = floor((numel(tforms)+1)/2);
centerImageIdx = idx(centerIdx);

% Finally, apply the center image's inverse transform to all the others.
Tinv = invert(tforms(centerImageIdx));
for i = 1:numel(tforms)    
    tforms(i).T = tforms(i).T * Tinv.T;
end

% || Step 3 - Initialize the Panorama || 
% Now, create an initial, empty, panorama into which all the images are mapped. 
% Use the outputLimits method to compute the minimum and maximum output limits over all transformations. These values are used to automatically compute the size of the panorama.
for i = 1:numel(tforms)           
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(i,2)], [1 imageSize(i,1)]);
end

maxImageSize = max(imageSize);

% Find the minimum and maximum output limits. 
xMin = min([1; xlim(:)]);
xMax = max([maxImageSize(2); xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([maxImageSize(1); ylim(:)]);

% Width and height of panorama.
width  = round(xMax - xMin);
height = round(yMax - yMin);

% Initialize the "empty" panorama.
panorama = zeros([height width 3], 'like', I);

% || Step 4 - Create the Panorama || 
% Use imwarp to map images into the panorama and use vision.AlphaBlender to overlay the images together.
blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');  

% Create a 2-D spatial reference object defining the size of the panorama.
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoramaView = imref2d([height width], xLimits, yLimits);

% Create the panorama.
for i = 1:numImages
    
    I = readimage(buildingScene, i);   
   
    % Transform I into the panorama.
    warpedImage = imwarp(I, tforms(i), 'OutputView', panoramaView);
                  
    % Generate a binary mask.    
    mask = imwarp(true(size(I,1),size(I,2)), tforms(i), 'OutputView', panoramaView);
    
    % Overlay the warpedImage onto the panorama.
    panorama = step(blender, panorama, warpedImage, mask);
end

fig = figure('WindowState','maximized');
imshow(panorama);
if pipeline == 1
    exportgraphics(fig,'outputMosaics/1_CVToolbox_SIFT_myHomography.png');
elseif pipeline == 2
    exportgraphics(fig,'outputMosaics/2_CVToolbox_SIFT_CVToolboxHomography.png');
elseif pipeline == 3
    exportgraphics(fig,'outputMosaics/3_CVToolbox_SURF_CVToolboxHomography.png');
end


