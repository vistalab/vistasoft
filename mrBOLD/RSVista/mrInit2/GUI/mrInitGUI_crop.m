function params = mrInitGUI_crop(params);
% Set crop positions for cropping inplanes and functionals for 
% a mrVista session. 
%
%  params = mrInitGUI_crop(params);
%
% This function brings up a GUI displaying a montage of the inplanes 
% for a session. The user can click on the corners of one of the images to
% specify a crop range. This range is then set in the params.crop field.
% It is also checked against the functional voxel size; if the crop corners
% do not lie evenly on a functional voxel corner, they are nudged to the
% nearest functional voxel.
% 
% The sequence of events in this GUI is as follows:
%  1.  Show all full-sized inplanes as subplots
%  2.  Let the user select one with the mouse
%  3.  Show the selected full-sized inplane
%  4.  Let the user crop it.
%  5.  Show all cropped inplanes as subplots
%  6.  Query the user if crop looks OK.
%  7.  If user is unhappy with crop, go back to step 1.
%
% This code is adapted from the previous CropInplanes code by GB and DBR.
%
% ras, 05/2007

% ensure the inplane is loaded
params.inplane = mrParse(params.inplane);

anat0 = params.inplane.data;

nImages = size(anat0, 3);
aSize = [size(anat0,1) size(anat0,2)];

%% open the GUI figure
h = figure('Color', [.9 .9 .9], 'MenuBar', 'none', ...
		'Name', 'Crop Inplanes', 'NumberTitle', 'off');
centerfig(h, 0);

OK = 0;    % Flag to accept chosen crop
while ~OK
	%%  1.  Show all full-sized inplanes as subplots
    clf
    m = round(sqrt(nImages));
    n = ceil(nImages/m);
    for sliceNum = 1:nImages
        h_slice = subplot(m, n, sliceNum);
		slice = histoThresh( anat0(:,:,sliceNum) );
        h_image = imagesc(slice, 'Tag', sprintf(' %d', sliceNum));
        colormap(gray)
        axis off
        axis equal
    end
    brighten(0.6);
    subplot(m, n, 1)
    
	%%  2.  Let the user select one with the mouse
	set(h, 'Name', 'Crop Inplanes: Click on an image to crop.')

    sliceNum = 0;
    while sliceNum == 0
        waitforbuttonpress
        tag = get(gco, 'Tag');
        if ~isempty(tag)
            sliceNum = str2num(tag);
        end
	end

	%%  3.  Show the selected full-sized inplane	
    clf
    imagesc( histoThresh( anat0(:,:,sliceNum) ) );
    colormap(gray)
    brighten(0.6);
    axis off
    axis equal
	
	%%  4.  Let the user crop it.	
	set(h, 'Name', 'Crop Inplanes')
    title('Crop the image. (Select the two corners of the crop rectangle.)')

    [x,y] = ginput(2);
    x = sort(round(x));
    y = sort(round(y));

    x = max(1, min(x, size(anat0, 2)));
    y = max(1, min(y, size(anat0, 1)));
    crop = [x(1), y(1); x(2), y(2)];

	%%  5.  Show all cropped inplanes as subplots
	% specify the cropped subset of the anatomies
    anat = anat0([crop(1,2):crop(2,2)],[crop(1,1):crop(2,1)],:);

	msg = sprintf('Crop: X %i-%i, Y %i-%i', x(1), x(2), y(1), y(2)); 
	set(h, 'Name', msg)
    for sliceNum = 1:nImages
        subplot(m, n, sliceNum)

        h_slice(sliceNum) = imagesc( histoThresh(anat(:,:,sliceNum)) );
        colormap(gray)
        axis off
        axis equal
    end
    brighten(0.6);

	%%  6.  Query the user if crop looks OK.
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

% Update the crop parameter:
params.crop = crop;

return
