function dtiShowAlignFigure(fig, t1, b0, bb, slice, figName)
%
% dtiShowAlignFigure(fig, t1, b0, bb, slice, figName)
%
% HISTORY:
% 2006.?? RFD wrote it.

if(~exist('bb','var')|isempty(bb))
  bb = [-80,80; -120,90; -60,90]';
end
if(~exist('slice','var')|isempty(slice))
  slice = [0,0,0];
end
if(~isfield(t1,'data')) t1.data = double(t1.uint8)./255; end
if(~isfield(b0,'data')) b0.data = double(b0.uint8)./255; end
if(~isfield(t1,'acpcXform')) 
  if(isfield(t1,'mat')) t1.acpcXform = t1.mat;
  else  t1.acpcXform = t1.qto_xyz; end
end
if(~isfield(b0,'acpcXform')) 
  if(isfield(b0,'mat')) b0.acpcXform = b0.mat;
  else  b0.acpcXform = b0.qto_xyz; end
end
t1.data(t1.data<0) = 0;
b0.data(b0.data<0) = 0;
if(~exist('figName','var')) figName = 'Alignment'; end
% Get X,Y and Z (L-R, A-P, S-I) slices from T1 and b0 volumes
[t1Xsl] = dtiGetSlice(t1.acpcXform,t1.data,3,slice(3),bb);
[t1Ysl] = dtiGetSlice(t1.acpcXform,t1.data,2,slice(2),bb);
[t1Zsl] = dtiGetSlice(t1.acpcXform,t1.data,1,slice(1),bb);
[b0Xsl] = dtiGetSlice(b0.acpcXform,b0.data,3,slice(3),bb);
[b0Ysl] = dtiGetSlice(b0.acpcXform,b0.data,2,slice(2),bb);
[b0Zsl] = dtiGetSlice(b0.acpcXform,b0.data,1,slice(1),bb);
% Max values for image scaling
t1mv = max([t1Xsl(:); t1Ysl(:); t1Zsl(:)])+0.000001;
b0mv = max([b0Xsl(:); b0Ysl(:); b0Zsl(:)])+0.000001;
% Create XxYx3 RGB images for each of the axis slices. The green and 
% blue channels are from the T1, the red channel is an average of T1 
% and b=0.
Xsl(:,:,1) = t1Xsl./t1mv.*.5 + b0Xsl./b0mv.*.5;
Xsl(:,:,2) = t1Xsl./t1mv.*.5; Xsl(:,:,3) = t1Xsl./t1mv.*.5;
Ysl(:,:,1) = t1Ysl./t1mv.*.5 + b0Ysl./b0mv.*.5;
Ysl(:,:,2) = t1Ysl./t1mv.*.5; Ysl(:,:,3) = t1Ysl./t1mv.*.5;
Zsl(:,:,1) = t1Zsl./t1mv.*.5 + b0Zsl./b0mv.*.5;
Zsl(:,:,2) = t1Zsl./t1mv.*.5; Zsl(:,:,3) = t1Zsl./t1mv.*.5;

% Show T1 slices
figure(fig); set(fig, 'NumberTitle', 'off', 'Name', figName);
figure(fig); subplot(3,3,1); imagesc(bb(:,1), bb(:,2), t1Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,2); imagesc(bb(:,3), bb(:,1), t1Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,3); imagesc(bb(:,3), bb(:,2), t1Zsl); 
colormap(gray); axis equal tight xy; 
axis equal tight;

% Show b=0 slices
figure(fig); subplot(3,3,4); imagesc(bb(:,1), bb(:,2), b0Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,5); imagesc(bb(:,3), bb(:,1), b0Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,6); imagesc(bb(:,3), bb(:,2), b0Zsl); 
colormap(gray); axis equal tight xy; 
axis equal tight;

% Show combined slices
figure(fig); subplot(3,3,7); imagesc(bb(:,1), bb(:,2), Xsl); 
axis equal tight xy;
figure(fig); subplot(3,3,8); imagesc(bb(:,3), bb(:,1), Ysl); 
axis equal tight xy;
figure(fig); subplot(3,3,9); imagesc(bb(:,3), bb(:,2), Zsl); 
axis equal tight xy; 
axis equal tight;

return;
