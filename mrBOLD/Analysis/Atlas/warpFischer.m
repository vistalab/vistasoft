function [u,v,M,errorTimeSeries] = warpFischer(measured1, atlas1, measured2, atlas2, areasImg, cmap, weights)
%  
% [u,v,M,errorTimeSeries] = ...
%    warpFischer(measured1, atlas1, measured2,atlas2, areasImg, [cmap], [weights])
%
%  AUTHOR:  B. Fischer, RF Dougherty
%  PURPOSE:
%    Pre-processing wrapper for eMatching, written by Bernd Fischer.
%
%  Weights describes how much to emphasize each point in the image.  Often, weights is the 'co' field.
%  If weights is not empty, the force field will be weighted by these%  values. Must be the same size as the images.
% 
% data = vGetUd('data')
% atlas = data.atlasWedge.im;
% measured = data.processed.phWedge;
% l = hsv(128);
% l = l(55:118,:);
% figure; colormap(l); imagesc(atlas)
% figure; imagesc(measured)

if~exist('cmap','var'),  cmap = [];  end
if(~exist('weights','var')),  weights = [];
elseif(any(size(weights)~=size(measured1))), 
    error('weights image is not the same size as measured1 image.');
end

if(~exist('areasImg','var') | isempty(areasImg))
    overlay = zeros(size(atlas1));
else
    % The following code will create a simple image that is 0 on the 
    % ROI boundaries, .8 within the ROIs and 1 everywhere else. Useful
    % for making a transparent overlay.
    % The following line creates an image with 1's at the boundaries, 
    % 5's in the ROIs, and zeros everywhere else. 
    overlay = double(edge(areasImg, 'sob', .0050));
    % % now we change to our desired values:
    overlay(overlay>1) = 0.2;
    overlay = 1-overlay;
end

imSize = size(measured1);
imSize = 2.^ceil(log2(imSize));
imSize = max(imSize);
borderPix = 3;
% atlas1 = data.atlasWedge.im;
% measured1 = data.processed.phWedge;
% atlas2 = data.atlasRing.im;
% measured2 = data.processed.phRing;
padVal = NaN;

% Ensure that the images are imSize x imSize, and add a
% small border around the images to eliminate edge effects. 
padCols = (imSize-size(atlas1,1))/2;
padRows = (imSize-size(atlas1,2))/2;

% If the input images are too big, we crop them.
% If they are too small, we pad.
%
%   Replace this stuff with the Matlab function "padarray" when you get the
%   chance.
if(padCols>0)
    atlas1 = [padVal.*ones(floor(padCols),size(atlas1,2)); atlas1; ...
        padVal.*ones(ceil(padCols),size(atlas1,2))];
    atlas2 = [padVal.*ones(floor(padCols),size(atlas2,2)); atlas2; ...
        padVal.*ones(ceil(padCols),size(atlas2,2))];
    measured1 = [padVal.*ones(floor(padCols),size(measured1,2)); ...
        measured1; padVal.*ones(ceil(padCols),size(measured1,2))];
    measured2 = [padVal.*ones(floor(padCols),size(measured2,2)); ...
        measured2; padVal.*ones(ceil(padCols),size(measured2,2))];
    overlay = [ones(floor(padCols),size(overlay,2)); ...
        overlay; ones(ceil(padCols),size(overlay,2))];
    weights = [ones(floor(padCols),size(weights,2)); ...
        weights; ones(ceil(padCols),size(weights,2))];
else
    atlas1 = atlas1(floor(-padCols)+1:end-ceil(-padCols), :);
    atlas2 = atlas2(floor(-padCols)+1:end-ceil(-padCols), :);
    measured1 = measured1(floor(-padCols)+1:end-ceil(-padCols), :);
    measured2 = measured2(floor(-padCols)+1:end-ceil(-padCols), :);
    overlay = overlay(floor(-padCols)+1:end-ceil(-padCols), :);
    weights = weights(floor(-padCols)+1:end-ceil(-padCols), :);
end

if(padRows>0)
    atlas1 = [padVal.*ones(size(atlas1,1),floor(padRows)), atlas1, ...
	    padVal.*ones(size(atlas1,1),ceil(padRows))];
    atlas2 = [padVal.*ones(size(atlas2,1),floor(padRows)), atlas2, ...
	    padVal.*ones(size(atlas2,1),ceil(padRows))];
    measured1 = [padVal.*ones(size(measured1,1),floor(padRows)), ...
    	measured1, padVal.*ones(size(measured1,1),ceil(padRows))];
    measured2 = [padVal.*ones(size(measured2,1),floor(padRows)), ...
    	measured2, padVal.*ones(size(measured2,1),ceil(padRows))];
    overlay = [ones(size(overlay,1),floor(padRows)), ...
	    overlay, ones(size(overlay,1),ceil(padRows))];
    weights = [ones(size(weights,1),floor(padRows)), ...
	    weights, ones(size(weights,1),ceil(padRows))];
else
    atlas1 = atlas1(:, floor(-padRows)+1:end-ceil(-padRows));
    atlas2 = atlas2(:, floor(-padRows)+1:end-ceil(-padRows));
    measured1 = measured1(:, floor(-padRows)+1:end-ceil(-padRows));
    measured2 = measured2(:, floor(-padRows)+1:end-ceil(-padRows));
    overlay = overlay(:, floor(-padRows)+1:end-ceil(-padRows));
    weights = weights(:, floor(-padRows)+1:end-ceil(-padRows));
end

% If we didn't pad at least borderPix, then we 
% have to padVal data along the edges.
if(borderPix<padCols)
    atlas1([1:borderPix,end-borderPix-1:end],:) = padVal;
    atlas2([1:borderPix,end-borderPix-1:end],:) = padVal;
    measured1([1:borderPix,end-borderPix-1:end],:) = padVal;
    measured2([1:borderPix,end-borderPix-1:end],:) = padVal;
    overlay([1:borderPix,end-borderPix-1:end],:) = padVal;
    weights([1:borderPix,end-borderPix-1:end],:) = padVal;
end
if(borderPix<padRows)
    atlas1(:,[1:borderPix,end-borderPix-1:end]) = padVal;
    atlas2(:,[1:borderPix,end-borderPix-1:end]) = padVal;
    measured1(:,[1:borderPix,end-borderPix-1:end]) = padVal;
    measured2(:,[1:borderPix,end-borderPix-1:end]) = padVal;
    overlay(:,[1:borderPix,end-borderPix-1:end]) = padVal;
    weights(:,[1:borderPix,end-borderPix-1:end]) = padVal; 
end

% Scale the image values to match the colormap.
scale = size(cmap,1)./max([measured1(:)' measured2(:)' atlas1(:)' atlas2(:)']);
atlas1Scale = atlas1*scale+1;
atlas2Scale = atlas2*scale+1;
measured1Scale = measured1*scale+1;
measured2Scale = measured2*scale+1;

% apply elastic matching for matching the boundaries of atlas onto 
% measured 
%
[u,v,M,errorTimeSeries] = eMatching2(measured1Scale, atlas1Scale, measured2Scale, atlas2Scale, overlay, cmap, weights);

% unpad the important images
% 
if(padRows<0)
    u = [zeros(size(u,1),floor(-padRows)), u, zeros(size(u,1),ceil(-padRows))];
    v = [zeros(size(v,1),floor(-padRows)), v, zeros(size(v,1),ceil(-padRows))];
%     atlas1 = [zeros(size(atlas1,1),floor(-padRows)), atlas1,%     zeros(size(atlas1,1),ceil(-padRows))];
%     atlas2 = [zeros(size(atlas2,1),floor(-padRows)), atlas2,%     zeros(size(atlas2,1),ceil(-padRows))];
else
    u = u(floor(padCols)+1:end-ceil(padCols), :);
    v = v(floor(padCols)+1:end-ceil(padCols), :);
%     atlas1 = atlas1(floor(padCols)+1:end-ceil(padCols), :);
%     atlas2 = atlas2(floor(padCols)+1:end-ceil(padCols), :);
end
if(padCols<0)
    u = [zeros(floor(-padRows),size(u,2)); u; zeros(ceil(-padRows),size(u,2))];
    v = [zeros(floor(-padRows),size(v,2)); v; zeros(ceil(-padRows),size(v,2))];
%     atlas1 = [zeros(floor(-padRows),size(atlas1,2)); atlas1;%     zeros(ceil(-padRows),size(atlas1,2))];
%     atlas2 = [zeros(floor(-padRows),size(atlas2,2)); atlas2;%     zeros(ceil(-padRows),size(atlas2,2))];
else
    u = u(:, floor(padRows)+1:end-ceil(padRows));
    v = v(:, floor(padRows)+1:end-ceil(padRows));
%     atlas1 = atlas1(:, floor(padRows)+1:end-ceil(padRows));
%     atlas2 = atlas2(:, floor(padRows)+1:end-ceil(padRows));
end

% *** PROBLEM: How to translate Fischer's u,v into Volker's coordiante% frame? To translate Bernd's X,Y into something that Volker's codes can % handle, we need to remove the x,y mesh that he has added to X,Y. But, % that is now done for us in eMatching2.% Play the movie
% 
%figure;
%disp('Displaying movie in new figure');
%movie(M,1);

return;