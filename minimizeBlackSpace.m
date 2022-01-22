%Remove the additional black space around the image, if there is,
%in order to have a better visualization of the full mosaic

function [mosaic_R, mosaic_G, mosaic_B] = minimizeBlackSpace(mosaic_R, mosaic_G, mosaic_B)
   
    %Detect black pixels
    blackpixelsmask = (mosaic_R == 0 & mosaic_G == 0 & mosaic_B == 0);

    %Find the coordinates of black points inside the mask
    [coordY, coordX] = find(blackpixelsmask(:,:) == 0);

    minX = min(coordX); maxX = max(coordX); 
    minY = min(coordY); maxY = max(coordY); 

    %Crop the image to better show the mosaic
    mosaic_R = imcrop(mosaic_R, [minX minY (maxX-minX) (maxY-minY)]);
    mosaic_G = imcrop(mosaic_G, [minX minY (maxX-minX) (maxY-minY)]);
    mosaic_B = imcrop(mosaic_B, [minX minY (maxX-minX) (maxY-minY)]);

end