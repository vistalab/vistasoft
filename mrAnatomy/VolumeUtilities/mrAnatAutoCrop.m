function [img,cropVals] = mrAnatAutoCrop(img, borderPix, thresh)
% 
% img = mrAnatAutoCrop(img, [borderPix=1], [thresh=0])
%
% 2008.02.27 RFD: wrote it.

if(~exist('borderPix','var')||isempty(borderPix))
    borderPix = 1;
end
if(~exist('thresh','var')||isempty(thresh))
    thresh = 0;
end

sz = size(img);
m = img>thresh;
if(numel(sz)>2)
    tmp = sum(m,3);
    x = find(sum(tmp,1)); x = [x(1) x(end)];
    y = find(sum(tmp,2)); y = [y(1) y(end)];
    tmp = squeeze(sum(m,1));
    z = find(sum(tmp,1)); z = [z(1) z(end)];
    clear tmp;
    pad = [-borderPix borderPix];
    x = x+pad; y = y+pad; z = z+pad;
    x(1) = max(1,x(1)); y(1) = max(1,y(1)); z(1) = max(1,z(1));
    x(2) = min(sz(2),x(2)); y(2) = min(sz(1),y(2)); z(2) = min(sz(3),z(2));
    img = img(y(1):y(2),x(1):x(2),z(1):z(2));
    cropVals = [x; y; z];
else
    x = find(sum(~isnan(img)&img~=0,1)); x = [x(1) x(end)];
    y = find(sum(~isnan(img)&img~=0,2)); y = [y(1) y(end)];
    pad = [-borderPix borderPix];
    x = x+pad; y = y+pad;
    x(1) = max(1,x(1)); y(1) = max(1,y(1));
    x(2) = min(sz(2),x(2)); y(2) = min(sz(1),y(2));
    img = img(y(1):y(2),x(1):x(2));
    cropVals = [x; y; 1,1];
end
return;

