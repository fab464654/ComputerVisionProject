%Crop the mosaic in order to potentially save the image with
%the maximum number of "meaningful" pixels
%How: by considering a inner rectangle and expand it vertically and
%horizontally until it comes outside of the mosaic borders.
      
function croppedMosaic = cropMosaic(mosaic, panoramaOrientation, minDistortion)
    
    %They will be in the form: [minX minY maxX maxY]
    mosaicRealBorders = zeros(1,4);
    
    %Detect colorPixels pixels (logical matrix)
    colorPixels = (mosaic(:,:,1) ~= 0 & mosaic(:,:,2) ~= 0 & mosaic(:,:,3) ~= 0);

    %Find the coordinates of colored points inside the mosaic
    [coordY, coordX] = find(colorPixels(:,:) == 1);
    
    %Find corners
    indices = boundary(coordY,coordX);
    mosaicBorder = polyshape(coordX(indices),coordY(indices),'simplify', false);

    %Find the mosaicBorder's centroid
    [center_x,center_y] = centroid(mosaicBorder);
    
    %Create a small rectangle polygon inside the mosaicBorder polygon
    %I assume I can create a 20x20 pixels (thr) rectangle (around the centroid)
    thr = 20;
    rectangle = polyshape([center_x-thr center_x-thr center_x+thr center_x+thr ], ...
                          [center_y-thr center_y+thr center_y+thr center_y-thr]);
        
    intersection = intersect(mosaicBorder,rectangle);
    
%     figure; plot(mosaicBorder); hold on; plot(rectangle);

    %% HORIZONTAL PANORAMA %%
    if strcmp(panoramaOrientation, 'H')
        %Expand the rectangle horizontally
        while(subtract(rectangle,intersection).NumRegions == 0)
            %Increase right vertices      
            rectangle.Vertices(3,1) = rectangle.Vertices(3,1) + 10;     
            rectangle.Vertices(4,1) = rectangle.Vertices(4,1) + 10;
            intersection = intersect(mosaicBorder,rectangle);
        end
        
        %Decrease right vertices by 10 to avoid intersections
        rectangle.Vertices(3,1) = rectangle.Vertices(3,1) - 10;     
        rectangle.Vertices(4,1) = rectangle.Vertices(4,1) - 10;
            
        while(subtract(rectangle,intersection).NumRegions == 0)
            %Decrease left vertices 
            rectangle.Vertices(1,1) = rectangle.Vertices(1,1) - 10;        
            rectangle.Vertices(2,1) = rectangle.Vertices(2,1) - 10; 
            intersection = intersect(mosaicBorder,rectangle);
        end
        
        %Increase left vertices by 10 to avoid intersections
        rectangle.Vertices(1,1) = rectangle.Vertices(1,1) + 10;        
        rectangle.Vertices(2,1) = rectangle.Vertices(2,1) + 10; 
            
        
        %Assign the left and right limits to the real mosaic borders
        mosaicRealBorders(3) = rectangle.Vertices(3,1);
        mosaicRealBorders(1) = rectangle.Vertices(1,1);

        %Restart the "expansion" process from the small rectangle placed
        %according to the less distorted location (minimum width or height)
        %that has been provided by the user
        if(strcmp(minDistortion,'center'))
            rectangle = polyshape([center_x-thr center_x-thr center_x+thr center_x+thr ], ...
                                  [center_y-thr center_y+thr center_y+thr center_y-thr]);
        elseif(strcmp(minDistortion,'right'))
            rightPointX = max(coordX) - thr*4; %(to be safe)
            rectangle = polyshape([rightPointX-thr rightPointX-thr rightPointX+thr rightPointX+thr ], ...
                                  [center_y-thr center_y+thr center_y+thr center_y-thr]);
        elseif(strcmp(minDistortion,'left'))
            leftPointX = min(coordX) + thr*4; %(to be safe)
            rectangle = polyshape([leftPointX-thr leftPointX-thr leftPointX+thr leftPointX+thr ], ...
                                  [center_y-thr center_y+thr center_y+thr center_y-thr]);
        end       
%         figure(10); clf; plot(mosaicBorder); hold on; plot(rectangle); pause;

        intersection = intersect(mosaicBorder,rectangle);

        %Expand the rectangle vertically
        while(subtract(rectangle,intersection).NumRegions == 0)
            %Increase upper vertices      
%             figure(11); clf; plot(mosaicBorder); hold on; plot(rectangle); pause;

            rectangle.Vertices(2,2) = rectangle.Vertices(2,2) + 10;     
            rectangle.Vertices(3,2) = rectangle.Vertices(3,2) + 10;
            intersection = intersect(mosaicBorder,rectangle);
        end
        
        %Decrease upper vertices by 10 to avoid intersections
        rectangle.Vertices(2,2) = rectangle.Vertices(2,2) - 10;     
        rectangle.Vertices(3,2) = rectangle.Vertices(3,2) - 10;
      
        while(subtract(rectangle,intersection).NumRegions == 0)
            %Decrease lower vertices
            rectangle.Vertices(1,2) = rectangle.Vertices(1,2) - 10;       
            rectangle.Vertices(4,2) = rectangle.Vertices(4,2) - 10;
            intersection = intersect(mosaicBorder,rectangle); 
        end       
        
        %Increase lower vertices by 10 to avoid intersections
        rectangle.Vertices(1,2) = rectangle.Vertices(1,2) + 10;       
        rectangle.Vertices(4,2) = rectangle.Vertices(4,2) + 10;
            
        %Assign the left and right limit to the real mosaic borders
        mosaicRealBorders(2) = rectangle.Vertices(1,2);
        mosaicRealBorders(4) = rectangle.Vertices(2,2);
        
        
        
        
    %% VERTICAL PANORAMA %%
    elseif strcmp(panoramaOrientation, 'V')
        %Expand the rectangle vertically 
        while(subtract(rectangle,intersection).NumRegions == 0)
            %Increase upper vertices                    
            rectangle.Vertices(2,2) = rectangle.Vertices(2,2) + 10;       
            rectangle.Vertices(3,2) = rectangle.Vertices(3,2) + 10;
            intersection = intersect(mosaicBorder,rectangle);
        end
        
        %Decrease upper vertices by 10 to avoid intersections
        rectangle.Vertices(2,2) = rectangle.Vertices(2,2) - 10;       
        rectangle.Vertices(3,2) = rectangle.Vertices(3,2) - 10;
        
        while(subtract(rectangle,intersection).NumRegions == 0)   
            %Decrease lower vertices
            rectangle.Vertices(1,2) = rectangle.Vertices(1,2) - 10;     
            rectangle.Vertices(4,2) = rectangle.Vertices(4,2) - 10;
            intersection = intersect(mosaicBorder,rectangle);
        end
        
        %Increase lower vertices by 10 to avoid intersections
        rectangle.Vertices(1,2) = rectangle.Vertices(1,2) + 10;     
        rectangle.Vertices(4,2) = rectangle.Vertices(4,2) + 10;
            
        %Assign the upper and lower limit to the real mosaic borders
        mosaicRealBorders(4) = rectangle.Vertices(2,2);
        mosaicRealBorders(2) = rectangle.Vertices(1,2);
        
        %Restart the "expansion" process from the small rectangle placed
        %according to the less distorted location (minimum width or height)
        %that has been provided by the user
        if(strcmp(minDistortion,'center'))
            rectangle = polyshape([center_x-thr center_x-thr center_x+thr center_x+thr ], ...
                                  [center_y-thr center_y+thr center_y+thr center_y-thr]);
        elseif(strcmp(minDistortion,'down'))
            upPointY = max(coordY) - thr*4; %(to be safe)
            rectangle = polyshape([center_x-thr center_x-thr center_x+thr center_x+thr ], ...
                                  [upPointY-thr upPointY+thr upPointY+thr upPointY-thr]);
        elseif(strcmp(minDistortion,'up'))
            downPointY = min(coordY) + thr*4; %(to be safe)
            rectangle = polyshape([center_x-thr center_x-thr center_x+thr center_x+thr ], ...
                                  [downPointY-thr downPointY+thr downPointY+thr downPointY-thr]);
        end
        %Expand the rectangle horizontally
        while(subtract(rectangle,intersection).NumRegions == 0)
            %Increase right vertices                         
            rectangle.Vertices(3,1) = rectangle.Vertices(3,1) + 10;     
            rectangle.Vertices(4,1) = rectangle.Vertices(4,1) + 10;
            intersection = intersect(mosaicBorder,rectangle);
        end
        
        %Decrease right vertices by 10 to avoid intersections
        rectangle.Vertices(3,1) = rectangle.Vertices(3,1) - 10;     
        rectangle.Vertices(4,1) = rectangle.Vertices(4,1) - 10;
            
        while(subtract(rectangle,intersection).NumRegions == 0)
            %Decrease left vertices                         
            rectangle.Vertices(1,1) = rectangle.Vertices(1,1) - 10;        
            rectangle.Vertices(2,1) = rectangle.Vertices(2,1) - 10;
            intersection = intersect(mosaicBorder,rectangle);
        end
        
        %Increase left vertices by 10 to avoid intersections
        rectangle.Vertices(1,1) = rectangle.Vertices(1,1) + 10;        
        rectangle.Vertices(2,1) = rectangle.Vertices(2,1) + 10;
           
        %Assign the left and right limit to the real mosaic borders
        mosaicRealBorders(1) = rectangle.Vertices(1,1);
        mosaicRealBorders(3) = rectangle.Vertices(3,1);
        
    else
        error("Invalid panorama orientation!")
    end
    
    %Return the cropped version (rect = [XMIN YMIN WIDTH HEIGHT]
    %               mosaicRealBorders = [minX minY maxX maxY])
    
    croppedMosaic = imcrop(mosaic, [mosaicRealBorders(1), ...
                                    mosaicRealBorders(2), ...
                                    mosaicRealBorders(3) - mosaicRealBorders(1), ...
                                    mosaicRealBorders(4) - mosaicRealBorders(2)]);
    
end

