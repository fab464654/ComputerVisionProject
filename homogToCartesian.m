% Function that transforms a homogeneous coordinates vector
% to the cartesian coordinate system.
%
% X = 3xN matrix, composed by N columns to be transformed

function cart = homogToCartesian(X)
    if size(X,1) == 3
        cart = X(:,:)./X(3,:);
        cart(3,:) = [];
    else
        error("Error: check the vector size!");
    end
end