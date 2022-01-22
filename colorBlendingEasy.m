%Easy approach to the color blending problem:
%if the two considered pixels are black, keep them black, if
%one of the two image is colored and the other is black, let
%the color "survive". If instead both pixels aren't black, merge
%them half + half.

function blendedImage = colorBlendingEasy(img1,img2)
    for m = 1:size(img1,1)
        for n = 1:size(img1,2)            
            %Img1 pixel black, img2 pixel colored
            if (img1(m,n) == 0 && img2(m,n) ~= 0)
                blendedImage(m,n) = img2(m,n); 
            %Img1 pixel colored, img2 pixel black
            elseif (img1(m,n) ~= 0 && img2(m,n) == 0)
                blendedImage(m,n) = img1(m,n);
            %Both colored pixels
            elseif (img1(m,n) ~= 0 && img2(m,n) ~= 0)
                blendedImage(m,n) = img1(m,n).*0.5 + img2(m,n).*0.5;      
            %Both black pixels
            else
                blendedImage(m,n) = 0;
            end                
        end
    end
end

