function cleanClass = cleanSingletonWhitePoints(class);
%
%Author:  RFD, BW
%Date:
%Purpose:
%   Remove singleton white matter points from each plane
%

% Mask will find points that are singletons
mask = -1*ones(3,3);
mask(2,2) = 1;

%
im = class.data;
imSize = size(im);
cleanIm = im;

%

changes = [];
for ii=1:imSize(1);
    curSlice = squeeze(cleanIm(ii,:,:));
    tst = conv2(curSlice,mask,'same');
    changes = [changes, sum(sum(tst > 0))];
    curSlice(tst > 0) = class.type.unknown;
    cleanIm(ii,:,:) = curSlice;
end
changes, sum(changes)

changes = [];
for ii=1:imSize(2);
    curSlice = squeeze(cleanIm(:,ii,:));
    tst = conv2(curSlice,mask,'same');
    changes = [changes, sum(sum(tst > 0))];
    curSlice(tst > 0) = class.type.unknown;
    cleanIm(:,ii,:) = curSlice;
end
changes, sum(changes)

changes = [];
for ii=1:imSize(3);
    curSlice = squeeze(cleanIm(:,:,ii));
    tst = conv2(curSlice,mask,'same');
    changes = [changes, sum(sum(tst > 0))];
    curSlice(tst > 0) = class.type.unknown;
    cleanIm(:,:,ii) = curSlice;
end
changes, sum(changes)

% Assign results to returned structure
cleanClass = class;
cleanClass.data = cleanIm;

