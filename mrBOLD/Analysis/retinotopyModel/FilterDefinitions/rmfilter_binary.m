function images = rmfilter_binary(images, display)
% binarize image: 
%
%   all pixels other than background = 1, 
%   all other pixels = 0;

try
    % look up background color inded from screen calibration
    bk   = display.backColorIndex;
catch
    % if no calibration file round, take the mean pixel value of all images
    % as the background
    bk   = round(mean(images(:)));
end

images = images ~= bk;

end