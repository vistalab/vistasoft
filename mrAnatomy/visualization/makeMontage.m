function  [img,coords] = makeMontage(imgCube, sliceList, fileName, numAcross, backVal)
%img = makeMontage(imgCube, [sliceList], [fileName], [numAcross], [backVal])
%
% Compiles a montage image from the images in imgCube.  
% (imgCube is x by y by sliceNum)
% sliceList, if specified, determines which slices to extract.
% (it defaults to all slices if it's empty or omitted)
% The image can be displayed with something like:
%
%  figure; imagesc(img); colormap(gray); axis equal; axis off;
%
% If a fileName is specified, the image will be saved to that file.
% Note that the image file format type depends on the filename extension
% (see imwrite).
%
% see also makeMontageIfiles
if(~exist('sliceList', 'var')) sliceList = []; end
if(~exist('numAcross', 'var')) numAcross = []; end
if(~exist('fileName', 'var')) fileName = []; end
if(~exist('backVal', 'var')) backVal = []; end
if(size(imgCube,4)==3)
   [img(:,:,1),coords] = makeMontage(imgCube(:,:,:,1), sliceList, fileName, numAcross,backVal);
   img(:,:,2) = makeMontage(imgCube(:,:,:,2), sliceList, fileName, numAcross,backVal);
   img(:,:,3) = makeMontage(imgCube(:,:,:,3), sliceList, fileName, numAcross,backVal);
   return;
end

% Sanity check
if(any(size(imgCube)>10000))
    error('At least one dimension of input image is >10,000- refusing to continue...');
end

header = 0;
if(isempty(sliceList))
   sliceList = [1:size(imgCube, 3)];
end
sz = size(imgCube);
r = sz(1); c = sz(2);

nImages = length(sliceList);
if(isempty(numAcross))
    numAcross = ceil(sqrt(nImages)*sqrt((r/c)));
end
numDown = ceil(nImages/numAcross);
if(isempty(backVal)) backVal = 0; end
img = ones(r*numDown,c*numAcross)*backVal;
eval(['img = ',class(imgCube),'(img);']);
count = 0;
for ii = 1:length(sliceList)
    curSlice = sliceList(ii);
    count = count+1;
    x = rem(count-1, numAcross)*c;
    y = floor((count-1)/ numAcross)*r;
    img(y+1:y+r,x+1:x+c) = imgCube(:,:,curSlice);
    coords(ii,:) = [x+1,y+1];
end


if(~isempty(fileName))
    imgMin = min(img(:));
    imgMax = max(img(:));
    img2 = uint8(floor((double(img)+imgMin)./(imgMax-imgMin)*255));
    
    %figure; colormap(repmat([0:1/255:1]',1,3)); image(img2); axis image; axis off;
    [p,f,e] = fileparts(fileName);
    if(isempty(e))
        fileName = [fileName, '.jpg'];
    end
    imwrite(img2, fileName);
    disp(['Wrote montage to ' fullfile(pwd, fileName)]);
end




















































































































