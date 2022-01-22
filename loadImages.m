% Load the single images that will be stiched together to perform
% automatic mosaicing.
%
% To then access the images: image1 = images(:,:,:,1);
% It's a 4-D array that contains all the images in the from: 
% images(rows, cols, RGB channels, imgIndex)

function [images,numImages, map] = loadImages(imgPath, extension, maxSize)

    images = [];
    imgs = dir(strcat(imgPath, '/*.', extension));    
    numImages = size(imgs,1);
     
    for i = 1:numImages
        %Read the image
        [currentImage, map] = imread(fullfile(imgPath, imgs(i).name));
        
        %Resize the image if bigger than a threshold
        %NOTE: - all images should have the same size;
        %      - images are resized keeping the same aspect ratio with max
        %      dimension equal to "maxSize"
        
        if size(currentImage,1) > size(currentImage,2) %vertical
            currentImage = imresize(currentImage, [maxSize, NaN]);
        else
            currentImage = imresize(currentImage, [NaN, maxSize]);
        end
                
        %Add the image
        images = cat(4,images,currentImage);
    end    
end

