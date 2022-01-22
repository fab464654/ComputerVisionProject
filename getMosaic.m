function [mosaic_ref,mosaic_mov] = getMosaic(corners,bb_ij, img1,warpedImage)

    %NaN pixels are converted to black
    ind = find(isnan(warpedImage));
    warpedImage(ind) = 0;
    
    %Find the coordinates from the corners
    minj = min(corners(2,:));
    mini = min(corners(1,:));
    maxj = max(corners(4,:));
    maxi = max(corners(3,:));

    %Mosaic bounding boxes
    bb_mos = [mini; minj; maxi; maxj];

    offs = [abs(mini); abs(minj)];

    sz_mos = bb_mos + [offs; offs];

    if(sz_mos(1)==0 && sz_mos(2)==0) 
        mosaic_ref = zeros(sz_mos(3), sz_mos(4));
        mosaic_mov = mosaic_ref;
        mosaic_out = mosaic_ref;
    else
        disp('somethig wrong...'); 
    end

    %Do the image warping in order to retrieve two matching images
    if((offs(1)>0) && (offs(2)>0))
        mosaic_ref(offs(1):(size(img1,1)+offs(1)-1),offs(2):(size(img1,2)+offs(2)-1))=img1;
        mosaic_mov(1:(size(warpedImage,1)),1:size(warpedImage,2))=warpedImage(:,:);
    end

    if ((offs(1)>0) && (offs(2)==0))
        mosaic_ref(offs(1):(size(img1,1)+offs(1)-1),1:size(img1,2))=img1;
        mosaic_mov(1:size(warpedImage,1),abs(bb_ij(2)):(size(warpedImage,2)+abs(bb_ij(2))-1))=warpedImage(:,:);
    end

    if ((offs(1)==0) && (offs(2)>0))
        mosaic_ref(1:size(img1,1),offs(2):(size(img1,2)+offs(2)-1))=img1;
        mosaic_mov(bb_ij(1):(size(warpedImage,1)+bb_ij(1)-1),1:size(warpedImage,2))=warpedImage(:,:);
    end

    if ((offs(1)==0) && (offs(2)==0))
        mosaic_ref(1:size(img1,1),1:size(img1,2))=img1;
        mosaic_mov(bb_ij(1):(size(warpedImage,1)+bb_ij(1)-1),bb_ij(2):(size(warpedImage,2)+bb_ij(2)-1))=warpedImage(:,:);
    end
end

