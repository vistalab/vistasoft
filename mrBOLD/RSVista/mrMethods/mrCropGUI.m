function crop = mrCropGUI(mr, crop);
%
% crop = mrCropGUI(mr, [initialCrop=full size]);
%
% Get the crop values for an mr object using a GUI.
% Based on CropInplanes in mrInitRet.
%
% ras, 02/02/07.
if notDefined('mr'),    mr = mrLoad;    end

mr = mrParse(mr);

if notDefined('crop')
    crop = [1 1; mr.dims(1:2)];
end


h = figure('MenuBar', 'none');
OK = 0;    % Flag to accept chosen crop
while ~OK
    clf
    m = round(sqrt(mr.dims(3)));
    n = ceil(mr.dims(3)/m);
    for sliceNum = 1:mr.dims(3)
        h_slice = subplot(m, n, sliceNum);
        tag = sprintf(' %d', sliceNum);
        h_image = imagesc(mr.data(:,:,sliceNum,1), 'Tag', tag);
        colormap(gray)
        axis off
        axis image
		set(gca, 'OuterPosition', get(gca, 'Position'));
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
    imagesc(mr.data(:,:,sliceNum,1));
    colormap(gray)
    brighten(0.6);
    axis off
    axis equal
    title('Crop the image.')

    [x,y] = ginput(2);
    x = sort(round(x));
    y = sort(round(y));

    x = max(1, min(x, size(mr.data, 2)));
    y = max(1, min(y, size(mr.data, 1)));
    crop = [x(1), y(1); x(2), y(2)];

    croppedData = mr.data([crop(1,2):crop(2,2)],[crop(1,1):crop(2,1)],:,:);

    for sliceNum = 1:mr.dims(3)
        subplot(m, n, sliceNum)

        h_slice(sliceNum) = imagesc(croppedData(:,:,sliceNum));
        colormap(gray)
        axis off
        axis equal
    end
    brighten(0.6);

    switch askQuestion('Does this look OK?', 'Yes', 'Cancel');
        case 2
            % Cancel
            crop = [];
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

return
