function mosaic = imageWarpCopied(im1,im2,H)
    
    %% Copied from the tutorial, just for checking

    % --------------------------------------------------------------------
    %                                                               Mosaic
    % --------------------------------------------------------------------

    box2 = [1  size(im2,2) size(im2,2)  1 ;
            1  1           size(im2,1)  size(im2,1) ;
            1  1           1            1 ] ;
    box2_ = inv(H) * box2 ;
    box2_(1,:) = box2_(1,:) ./ box2_(3,:) ;
    box2_(2,:) = box2_(2,:) ./ box2_(3,:) ;
    ur = min([1 box2_(1,:)]):max([size(im1,2) box2_(1,:)]) ;
    vr = min([1 box2_(2,:)]):max([size(im1,1) box2_(2,:)]) ;

    [u,v] = meshgrid(ur,vr) ;
    im1_ = vl_imwbackward(im2double(im1),u,v) ;

    z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
    u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
    v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
    im2_ = vl_imwbackward(im2double(im2),u_,v_) ;

        
    mass = ~isnan(im1_) + ~isnan(im2_) ;
  
    im1_(isnan(im1_)) = 0 ;
    im2_(isnan(im2_)) = 0 ;
         
    mosaic = (im1_ + im2_) ./ mass;
   
    %----------------------------------------------------------
    %Split the mosaic channels
    mosaicR = mosaic(:,:,1);
    mosaicG = mosaic(:,:,2);
    mosaicB = mosaic(:,:,3);

    %Detect black pixels
    blackpixelsmask = isnan(mosaicR) & isnan(mosaicG) & isnan(mosaicB);

    %Find the coordinates of black points inside the mask
    [coordY, coordX] = find(blackpixelsmask(:,:) == 0);

    minX = min(coordX); maxX = max(coordX); 
    minY = min(coordY); maxY = max(coordY); 

    %Crop the image in order to better show the mosaic
    mosaic = imcrop(mosaic, [minX minY (maxX-minX) (maxY-minY)]);
    
    %----------------------------------------------------------
    
%     figure(10); clf ;
%     imagesc(mosaic) ; axis image off ;
%     title('Mosaic left') ;


end

