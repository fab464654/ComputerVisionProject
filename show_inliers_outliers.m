%Show the inliers and outliers detected through RANSAC, on the
%images

function show_inliers_outliers(img1,img2,X1_inliers,X1_outliers, X2_inliers, X2_outliers)

    figure; subplot(1,2,1);

    %Show the first image
    imshow(img1); hold on; 

    %Scatter the points over the first image
    plot(X1_inliers(1,:), X1_inliers(2,:),  'g+', 'MarkerSize', 2, 'LineWidth', 0.2); 
    plot(X1_outliers(1,:),X1_outliers(2,:), 'r*', 'MarkerSize', 2, 'LineWidth', 0.2); 

    %Show the second image
    subplot(1,2,2); imshow(img2); hold on;

    %Scatter the points over the second image
    plot(X2_inliers(1,:), X2_inliers(2,:),  'g+', 'MarkerSize', 2, 'LineWidth', 0.2);
    plot(X2_outliers(1,:),X2_outliers(2,:), 'r*', 'MarkerSize', 2, 'LineWidth', 0.2); 
    
    %Repetitive code just to save the two images as .png
    figInliers = figure('WindowState','maximized');
    imshow(img1); hold on; 
    plot(X1_inliers(1,:), X1_inliers(2,:),  'g+', 'MarkerSize', 2, 'LineWidth', 0.2); 
    plot(X1_outliers(1,:),X1_outliers(2,:), 'r*', 'MarkerSize', 2, 'LineWidth', 0.2); 
    %This command works after 2020a
    exportgraphics(figInliers,'outputMosaics/InliersOutliers_1.png');
    
    clf(figInliers); %clear the figure after saving the first part
    imshow(img2); hold on;
    plot(X2_inliers(1,:), X2_inliers(2,:),  'g+', 'MarkerSize', 2, 'LineWidth', 0.2);
    plot(X2_outliers(1,:),X2_outliers(2,:), 'r*', 'MarkerSize', 2, 'LineWidth', 0.2); 
    %This command works after 2020a
    exportgraphics(figInliers,'outputMosaics/InliersOutliers_2.png');
    close(figInliers); %close the figure after saving the second part
    
end
