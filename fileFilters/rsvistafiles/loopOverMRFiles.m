function [img, hdr1, hdr2] = loopOverMRFiles(parent,pattern,func);
% Read many MR files in a directory.
%
% [img, hdr1, hdr2] = loopOverMRFiles(parent,pattern,func);
%
% Within the specified parent directory, find all files
% of the specified pattern and load them with the specified
% function. Also returns the header of the first file and 
% last files read, if requested.
% 
% ras, 07/2005: broken off into separate function.
img = []; hdr1 =[]; hdr2 = [];
if ~exist(parent,'dir')
    warning(sprintf('Directory %s not found.',parent));
    return
end
flag4D = 0;
callingDir = pwd;
cd(parent);
w = dir(pattern);
fnames = {w.name};
cd(callingDir);
h = mrvWaitbar(0,'Looping over MR files in directory...');
for i = 1:length(fnames)
    filepath = fullfile(parent,fnames{i});
    subvol = eval(sprintf('%s(''%s'');',func,filepath));
    if size(subvol,3) <= 1 % 2D image
        img(:,:,i) = subvol;
    else
        % try to build up a 4D matrix --
        % assume 3rd dimension is time
        img(:,:,:,i) = subvol;
        flag4D = 1; % will permute later
    end
    mrvWaitbar(i/length(fnames),h);
end
close(h);

if flag4D==1
    img = permute(img,[1 2 4 3]);
end
if nargout>1
    % get the header from the first file
    filepath = fullfile(parent,fnames{1});
    [tmp, hdr1] = eval(sprintf('%s(''%s'');',func,filepath));
    
    % get the header from the last file
    filepath = fullfile(parent,fnames{end});
    [tmp, hdr2] = eval(sprintf('%s(''%s'');',func,filepath));
end


return