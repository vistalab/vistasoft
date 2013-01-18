function images = rmfilter_thresholdedBinary(images, display)
% binarize image: 
%
%   all pixels that differ from background by more than 1% = 1, 
%   all other pixels = 0;


try
    % look up background color inded from screen calibration
    bk   = display.backColorIndex;
catch
    % if no calibration file round, take the mean pixel value of all images
    % as the background
    bk   = round(mean(images(:)));
end

thresh = 1/100 * bk;

images = (abs(images - bk) > thresh);

end