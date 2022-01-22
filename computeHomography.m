%Robust computation of the Homography matrix using RANSAC method

function H = computeHomography(img1,img2,X1, X2, matches, numIterations, threshold, speed, showInOutliers)
    

    %Transform to homogeneous coordinates (adding a column of ones)
    numCorrespondences = size(matches,2);
    X1(3,:) = ones(numCorrespondences,1);
    X2(3,:) = ones(numCorrespondences,1);

    %Introducing the RANSAC method for robust homography estimation
    scores = zeros(1, numIterations);
    vecH_all = zeros(9,numIterations);

    for k = 1:numIterations

        A = []; %Build the matrix A = trasp(X1)*kron*[X2]<-matrix of cross product

        %Extract only 5 columns from all the matches (Pixel-Pixel --> 4 constraints)
        randomCols = randi(numCorrespondences,[1,5]);

        for i = randomCols

            a = X2(:,i);   

            %Compute the matrix of cross product (skew symmetric)
            ax = [   0   , -a(3), a(2)  ;
                  a(3) ,   0    , -a(1) ;
                  -a(2), a(1) ,   0    ];

            %Compute the Kronecker product
            KRO = kron(X1(:,i).', ax);

            %Matrix of known terms (Pixel left image + Pixels right image)
            A = [A; KRO(1,:); KRO(2,:)];
        end

        %Singular value decomposition to find the solution of Ax=0
        [U, S, V] = svd(A, 'econ');

        %Vectorization, only the last column of the V matrix
        vecH = V(:,size(A,2));
        vecH_all(:,k) = vecH;

        %Having computed the vector, we need to rearrange it in a matrix form
        H = reshape(vecH, 3, 3);

        %Assign a score to the current homography    
        %compute the estimation error of the homography
        errors = vecnorm(homogToCartesian(X2) - homogToCartesian(H*X1));
        
        %Auxiliar variable for boolean indexing
        aux = errors < threshold;
        scores(k) = sum(aux(:) == 1); %number of acceptable errors caused by the homography

    end

    %Extract the best performing H matrix
    positionBest = find(scores == max(scores));
    if(numel(positionBest) > 1) %only take one "best" homography
        positionBest = positionBest(1);
    end

    H = reshape(vecH_all(:,positionBest), 3, 3);

    clear vecH_all;

    %Repeat the homography estimation only on the inlier matches
    isInlier = zeros(1,numCorrespondences);
    errors = vecnorm(homogToCartesian(X2) - homogToCartesian(H*X1));

    for n = 1:numCorrespondences
        %if error < threshold X1-X2 is an inlier corrispondence     
        if errors(n) < threshold
            isInlier(n) = 1;
        end
    end

    cIn = find(isInlier == 1);
    cOut = find(isInlier == 0);
    numInliers = numel(cIn);
    
    X1_inliers =  X1(:,cIn);   %extract the X1 inliers
    X2_inliers =  X2(:,cIn);   %extract the X2 inliers
    X1_outliers = X1(:,cOut);  %extract the X1 outliers
    X2_outliers = X2(:,cOut);  %extract the X2 outliers

    %To check inliers and outliers on the 2 current images:
    if showInOutliers == true    
        show_inliers_outliers(img1, img2, X1_inliers,X1_outliers, X2_inliers, X2_outliers);
    end

    %% Back to the homography estimation:
    A = []; %Build the matrix A = trasp(X1)*kron*[X2]<-matrix of cross product

    %Repeat the H estimation using a number of inliers (according to the speed)
    usedInliers = ceil(linspace(numInliers,5, 10));
    
    for i = 1:usedInliers(speed)

            a = X2_inliers(:,i);   

            %Compute the matrix of cross product (skew symmetric)
            ax = [   0   , -a(3), a(2)  ;
                  a(3) ,   0    , -a(1) ;
                  -a(2), a(1) ,   0    ];

            %Compute the Kronecker product
            KRO = kron(X1_inliers(:,i).', ax);

            %Matrix of known terms (Pixel left image + Pixels right image)
            A = [A; KRO(1,:); KRO(2,:)];
    end

    [U, S, V] = svd(A);
    vecH = V(:,size(A,2));
    H = reshape(vecH, 3, 3);  %Homography matrix after robust estimation

end

