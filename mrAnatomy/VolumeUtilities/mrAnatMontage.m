function img = mrAnatMontage(img, xform, acpcSlices, fname, figHandle)
% montageRgbImg = mrAnatMontage(img, xform, acpcSlices, fname, figHandle)
%
% Quick hack for displaying nice anatomy montages with ac-pc slice
% labels. Must be a volume, but can be an intensity image (will be
% displayed as grayscale) or an [x,y,z,3] rgb volume.
%
% HISTORY:
% 2006.08.08 RFD: wrote it.
%

if(~exist('fname','var')) fname = ''; end
if(~exist('figHandle','var')) figHandle = figure; end

if(size(img,4)==1)
  img = repmat(img,[1,1,1,3]);
end
% reorient so that the eyes point up
img = flipdim(permute(img,[2 1 3 4]),1);
for(ii=1:length(acpcSlices)) slLabel{ii} = sprintf('Z = %d',acpcSlices(ii)); end
[t,r,s] = affineDecompose(xform);
slImg = inv(xform)*[zeros(length(acpcSlices),2) acpcSlices' ones(length(acpcSlices),1)]';
slImg = round(slImg(3,:));
img = makeMontage3(img, slImg, s(1), 0, slLabel,[],figHandle);
if(~isempty(fname)) mrUtilPrintFigure(fname); end

% be kind to those who forget a semicolon:
if(nargout<1) clear img; end
return;
