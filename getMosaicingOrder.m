%Get order in which images are stitched together, final result
%can be different.

function [imgOrder] = getMosaicingOrder(strategy,shootingOrder, numImages, split)
    
    % 1) first2last (default)
    if strcmp(split,'y')        
        if strcmp(shootingOrder, 'right2left')
            imgOrder = [flip(ceil(numImages/2):numImages), 1:(ceil(numImages/2))-1];
        else
            imgOrder = [1:(ceil(numImages/2)), flip((ceil(numImages/2)+1):numImages)];      
        end
    else
        imgOrder = 1:(numImages);
    end
    
    % 2) last2first
    if strcmp(strategy,'last2first')
        if strcmp(split,'y')            
            imgOrder = [flip(1:(ceil(numImages/2))-1), ceil(numImages/2):numImages];
        else
            imgOrder = flip(1:(numImages));
        end
        
    % 3) fromCenter
    elseif strcmp(strategy,'fromCenter')
        fromCenter = zeros(1, numImages);
        if mod(numImages, 2)  == 0 %even number of images    
            fromCenter(1) = numImages/2;
            delta = 1;
            for i = 1:2:(numImages) 

                if numImages/2 - delta > 0
                    fromCenter(i+1) = numImages/2 - delta;
                    fromCenter(i+2) = numImages/2 + delta;
                else
                    fromCenter(i+1) = numImages/2 + delta;
                end
                delta = delta + 1;       
            end
        else %odd number of images
            fromCenter(1) = round(numImages/2);
            delta = 1;
            for i = 1:2:(numImages-1) 

                if numImages/2 - delta > 0
                    fromCenter(i+1) = round(numImages/2) - delta;
                    fromCenter(i+2) = round(numImages/2) + delta;
                end
                delta = delta + 1;          
            end
        end
        imgOrder = fromCenter;
    end 
    
    
end

