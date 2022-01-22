%Once the imwarp function is called, this function can be used to match
%sizes between the warped and the fixed image.
function [corners, bb_ij] = adjustSizes(image1, bb)
    
    %Adjust dimensions (bb = bounding box)
    bb_ij(1) = bb(2);
    bb_ij(2) = bb(1);
    bb_ij(3) = bb(4);
    bb_ij(4) = bb(3);
    
    if size(bb_ij,1) < size(bb_ij,2)
        bb_ij=bb_ij'; %transpose if needed
    end   

    bb_1 = [0; 0; size(image1)'];   %new image bounding boxes
    corners = [bb_ij bb_1];         %new image corners
end