function [anat, inplanes] = CropInplanes(rawDir, anat0, inplanes, cropRatio)
%
% [anat, inplanes] = CropInplanes(rawDir, anat0, inplanes, cropRatio);
%
% Loads the inplane anatomies from the Inplane directory of the
% root directory structure [rootName]. Then allows the user to
% crop the full-sized inplane anatomies in these steps:
%  1.  Show all full-sized inplanes as subplots
%  2.  Let the user select one with the mouse
%  3.  Show the selected full-sized inplane
%  4.  Let the user crop it.
%  5.  Show all cropped inplanes as subplots
%  6.  Query the user if crop looks OK.
%  7.  If user is unhappy with crop, go back to step 1.
%
% 4/98  DBR  Mostly stolen from GB, with minor rewrites.
% $Author: sayres $
% $Date%
anat = anat0;

nImages = size(anat0,3);
aSize = [size(anat0,1) size(anat0,2)];
if nImages ~= inplanes.nSlices | ...
        ~all(inplanes.fullSize == aSize)
    FatalInitError('mrSESSION.inplanes structure does not match raw anatomy.');
end

h = figure('MenuBar', 'none');
OK = 0;    % Flag to accept chosen crop
while ~OK
    clf
    m = round(sqrt(nImages));
    n = ceil(nImages/m);
    for sliceNum = 1:nImages
        h_slice = subplot(m, n, sliceNum);
        h_image=imagesc(anat0(:, :, sliceNum), 'Tag', sprintf(' %d', sliceNum));
        colormap(gray)
        axis off
        axis equal
    end
    brighten(0.6);
    subplot(m, n, 1)
    title('Click on an image to crop.')

    sliceNum = 0;
    while sliceNum == 0
        waitforbuttonpress
        tag = get(gco, 'Tag');
        if ~isempty(tag)
            sliceNum = str2num(tag);
        end
    end

    clf
    imagesc(anat0(:, :, sliceNum));
    colormap(gray)
    brighten(0.6);
    axis off
    axis equal
    title('Crop the image.')

    [x,y] = ginput(2);
    x = sort(round(x));
    y = sort(round(y));

    x = max(1, min(x, size(anat0, 2)));
    y = max(1, min(y, size(anat0, 1)));
    inplaneCrop = [x(1), y(1); x(2), y(2)];

    % Adjust crop
    inplaneCrop(1,:) = floor(inplaneCrop(1,:)/cropRatio)*cropRatio + 1;
    inplaneCrop(2,:) = ceil(inplaneCrop(2,:)/cropRatio)*cropRatio;

    %anat = anat0([y(1):y(2)], [x(1):x(2)], :);
    anat = anat0([inplaneCrop(1,2):inplaneCrop(2,2)], [inplaneCrop(1,1):inplaneCrop(2,1)], :);

    for sliceNum = 1:nImages
        subplot(m, n, sliceNum)

        h_slice(sliceNum) = imagesc(anat(:, :, sliceNum));
        colormap(gray)
        axis off
        axis equal
    end
    brighten(0.6);

    switch askQuestion('Does this look OK?', 'Yes', 'Cancel');
        case 2
            % Cancel
            inplaneCrop = [];
            close(h);
            disp('Crop aborted');
            return
        case 1
            % Okay
            OK = 1;
        otherwise
            % No
            disp('Repeating crop');
    end
end  %if ~OK

close(h)

% Add the crop information to the inplanes structure and update files:
inplanes.cropSize = diff(fliplr(inplaneCrop)) + 1;
inplanes.crop = inplaneCrop;
