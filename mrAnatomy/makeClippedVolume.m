function img = makeClippedVolume(img)
% img = makeClippedVolume(img)
%
% User-interface loop to find optimal clip values for a 3-d image array.
%

disp('Finding optimal clip values...');
minVal = min(img(:));
maxVal = max(img(:));

% set the minumum to zero
if(minVal~=0)
    disp(['Image minimum is not zero (',num2str(minVal),')- adjusting...']);
    img = img-minVal;
end
    
% clip and scale, if necessary
if(maxVal<255)
    disp('Image values are within 8-bit range- no clipping or scaling is necessary.');
else
    figure(99);
    disp('Computing histogram...');
    [n,x] = hist(img(:),100);
    subplot(2,2,1);
    bar(x,n,1);
    lowerClip = 0;
    upperClip = maxVal;
    
    % display some slices
    slice{1} = squeeze(img(round(end/2),:,:));
    slice{2} = squeeze(img(:,round(end/2),:));
    slice{3} = squeeze(img(:,:,round(end/2)));
    for(i=[1:3])
        slice{i}(slice{i}<lowerClip) = lowerClip;
        slice{i}(slice{i}>upperClip) = upperClip;
        slice{i} = slice{i}-lowerClip;
        slice{i} = round(slice{i}./upperClip*255);
        subplot(2,2,2);
        image(slice{1});colormap(gray(256));axis image;axis off;
        subplot(2,2,3);
        image(slice{2});colormap(gray(256));axis image;axis off;
        subplot(2,2,4);
        image(slice{3});colormap(gray(256));axis image;axis off;
    end
    % loop until user says it looks good
    ok = 0;
    while(~ok)
        answer = inputdlg({'lower clip value (min=0): ',...
                ['upper clip value (max=',num2str(maxVal),'):']}, ...
                'Set intensity clip values', 1, ...
                {num2str(lowerClip),num2str(upperClip)}, 'on');
        if ~isempty(answer)
            lowerClip = str2num(answer{1});
            upperClip = str2num(answer{2});
        end
        disp(['intensity clip values are: ' num2str(lowerClip) ', ' num2str(upperClip)]);
    
        % display some slices
        slice{1} = squeeze(img(round(end/2),:,:));
        slice{2} = squeeze(img(:,round(end/2),:));
        slice{3} = squeeze(img(:,:,round(end/2)));
        for(i=[1:3])
            slice{i} = rescale2(slice{i}, [lowerClip, upperClip]);
%             slice{i}(slice{i}<lowerClip) = lowerClip;
%             slice{i}(slice{i}>upperClip) = upperClip;
%             slice{i} = slice{i}-lowerClip;
%             slice{i} = round(slice{i}./upperClip*255);
            subplot(2,2,2);
            image(slice{1});colormap(gray(256));axis image;axis off;
            subplot(2,2,3);
            image(slice{2});colormap(gray(256));axis image;axis off;
            subplot(2,2,4);
            image(slice{3});colormap(gray(256));axis image;axis off;
        end
        
        bn = questdlg('Is this OK?','Confirm clip values','Yes','No','Cancel','Yes');
        if(strcmp(bn,'Cancel'))
            error('Cancelled.');
        else
            ok = strcmp(bn,'Yes');
        end
    end
    % Clip and scale image values to be 0-255
    %
    % I haven't been fully satisfied by just automatically clipping off the top
    % few % of intensities (this is what mrInitRet currently does to the inplanes).
    % So, lately I've been looking at the histogram and picking intensityClip
    % by hand, then viewing the images to see how well it worked.
    disp('Clipping intensities...');
    img = rescale2(img, [lowerClip, upperClip], [0, 255]);
    disp('Scaling to 0-255...');
%     img(img<lowerClip) = lowerClip;
%     img(img>upperClip) = upperClip;
%     img = img-lowerClip;
%     img = round(img./(upperClip-lowerClip)*255);
end
