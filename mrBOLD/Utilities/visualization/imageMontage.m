function montage = imageMontage(images, nrows, ncols)
% Create a montage from multiple images
% 
%   montage = imageMontage(images, [nrows], [ncols]);
%
% The images are not required to be the same size.
%
% images can be specified in one of 3 formats:
%
% (1) If images is a cell array of image matrices, each cell will
% be taken to be a separate image. The images will all be converted
% to truecolor, and resized to the size of the largest image. The returned
% montage will be truecolor (3D).
%
% (2) If images is a 3-D matrix, each slice of images will be taken
% to be a separate grayscale image in the montage. The returned montage
% will also be grayscale (2D).
%
% (3) If images is a 4-D M by N by 3 by X matrix, then it will be
% taken to be an array of truecolor images of the same size. Each 3-D
% subvolume will be taken to be one image. The returned montage
% will be truecolor (3D).
%
% nrows and ncols are optional input arguments specifying the # of rows
% and columns, respectively. If omitted, they default to producing a 
% square montage, biased towards more columns than rows.
%
% See also: mrViewer
%
% Example
%  niFileName = fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','t1.nii.gz');
%  anat = niftiRead(niFileName);
%  montage = imageMontage(anat.data);
%  imshow(montage)
%
% ras, 10/2005.

if nargin<1, help(mfilename); error('Not enough args.'); end

if iscell(images)
    flag = 1;
    nImages = length(images);
elseif ndims(images)==3
    flag = 2;
    nImages = size(images,3);
elseif ndims(images)==4 & size(images,3)==3
    flag = 3;
    nImages = size(images,4);
else
    help(mfilename); error('Invalid format for images argument.')
end

if nImages==1, 
    if iscell(images), montage = images{1};
    else, montage = images; 
    end
    return
end

if ~exist('nrows','var') | isempty(nrows)
    nrows = round(sqrt(nImages));
end
if ~exist('ncols','var') | isempty(ncols)
    ncols = round(nImages/nrows); 
end

montage = [];

switch flag
    case 1, % cell array
        % make sure all images are truecolor (3D)
        for i = 1:nImages
            if ndims(images{i})<3
                images{i} = repmat(images{i},[1 1 3]);
            end
        end
        
        % need to check image size and reshape to largest image
        for i=1:nImages, sz(i,:) = size(images{i}); end
        maxDims = max(sz);
        for i = 1:nImages, 
            images{i} = imresize(images{i}, ...
                                [maxDims(1) maxDims(2)], ...
                                'nearest'); 
        end
        
        % build the montage
        for r = 1:nrows
            rowIm = [];
            for c = 1:ncols
                n = (r-1)*ncols + c; % index into image
                if n<=nImages
                    rowIm = [rowIm images{n}];
                else
                    rowIm = [rowIm zeros(maxDims)];
                end
            end
            montage = [montage; rowIm];
        end
        
    case 2, % 3-D matrix
        for r = 1:nrows
            rowIm = [];
            for c = 1:ncols
                n = (r-1)*ncols + c; % index into image
                if n<=nImages
                    rowIm = [rowIm images(:,:,n)];
                else
                    rowIm = [rowIm zeros(maxDims)];
                end
            end
            montage = [montage; rowIm];
        end
        
    case 3, % 4-D matrix
        for r = 1:nrows
            rowIm = [];
            for c = 1:ncols
                n = (r-1)*ncols + c; % index into image
                if n<=nImages
                    rowIm = [rowIm images(:,:,:,n)];
                else
                    rowIm = [rowIm zeros(maxDims)];
                end
            end
            montage = [montage; rowIm];
        end        
end
    

return
