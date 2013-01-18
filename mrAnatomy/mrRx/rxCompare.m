function [compareImg, rng, ttltxt] = rxCompare(A,B,method);
%
% [compareImg, rng, ttltxt] = rxCompare(A,B,method);
%
% Compare two images (generally an interpolated 
% slice and reference slice) and generate an
% image reflecting the similarity between the
% two, using the selected method (an integer).
%
% Methods:
%
%
%            1) Subtract
%            2) Overlay (red / green)
%            3) Checkerboard
%			 4) threshold A and overlay on top of B
%				(like a mean map on an inplane in mrVista)
%
%
%
% 02/05 ras.
compareImg = [];
rng = [];

switch method
               
    case 1, % color overlay (red/blue)
        compareImg = B;
        compareImg(:,:,2) = A;
        compareImg(:,:,3) = A;
        rng = [0 1];
        ttltxt = 'Blue-Green: Interpolated; Red: Reference';

    case 2, % subtract
        compareImg = A-B;
        rng = [-1 1];
        ttltxt = 'Interpolated Minus Reference';
        
    case 3, % make checkerboard
        compareImg = regMosaic(A,B,10);
        rng = [min(compareImg(:)) max(compareImg(:))];
        ttltxt = 'Interpolated / Reference Mosaic';
		
	case 4, % thresholded vol as overlay
% 		compareImg = repmat(B, [1 1 3]);
% 		overlay = ind2rgb(A.*255, hot(256));
% 		thresh = min(A(:)) + 0.1*max(A(:));
% 		for z = 1:3
% 			tmp = compareImg(:,:,z);
% 			tmp(A > thresh) = overlay(A > thresh);
% 			compareImg(:,:,z) = tmp;
% 		end

		[A B] = swap(A, B);

		thresh = min(A(:)) + 0.1*max(A(:));
		C = B .* 127; % map underlay to grayscale range, 0-127
		C(A > thresh) = [128 + A(A > thresh).*128]; % overlay range 128-256
		compareImg = ind2rgb(round(C), [gray(128); hot(128)]);
		
        rng = [0 1];
        ttltxt = 'Reference Slice, w/ Interp Volume Overlay';
		
end

% now check if stats are requested,
% and if so display them:
hstats = findobj('Tag','quantifyMenu');

if isempty(hstats)
    showStats = 0;
else
    showStats = isequal(get(hstats(end),'Checked'),'on');
end

if showStats
    % (I only do this now, so the code could
    % conceivably be used outside mrRx):
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
    
    % test for valid text fields
    if isfield(rx.ui,'compareStats') && any(A(:)>0) && any(B(:)>0)
        if ishandle(rx.ui.compareStats.corrcoefVal) 
            % compute correlation coefficient
            R = corrcoef(A(:),B(:));
            set(rx.ui.compareStats.corrcoefVal,'String',num2str(R(2)));            
            
            % compute Root Mean-Squared Error
            RMSE = sqrt(mse(A,B));
            set(rx.ui.compareStats.rmseVal,'String',num2str(RMSE));
        else
            rx.ui = rmfield(rx.ui,'compareStats');
        end
    end
end

return



function [B A] = swap(A, B);
% switch variable values -- (shortest function ever!).
return
