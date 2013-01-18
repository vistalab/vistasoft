function image2mrGray(img, cmap, gLocs2d, gLocs3d, filename)
%  
% image2mrGray([img], [cmap], [gLocs2d], [gLocs3d], [outFilename])
%  
% AUTHOR: Dougherty
% DATE:  99.11.09
% PURPOSE:
%   Takes an image and interpolates it onto the flat map (gLocs2d),
%   and then creates a mrGray overlay file, so that you can render
%   the image onto the brain from which gLocs2d & gLocs3d came 
%   from.
%  
%  All arguments are optional- if you don't provide something, 
%  you will be prompted for it with a file dialog.  (gLocs2d &
%  gLocs3d typically come from flat.mat files.)
%
%  

if ~exist('img','var')
   [fname,pname] = uigetfile('*.*',['Load an image file']);
   if fname == 0
      return;
   end
   pname = [pname fname];
   [img,cmap] = imread(pname);
end
img = double(img);

% Get the colormap for the data, convert it from having
% a range of 0 to 1 to a range of 0 to 255.
%
if ~exist('cmap','var') | isempty(cmap)
   if size(img,3)~=3
      error('No cmap specified and img is not an [m,n,3] truecolor!');
   else
      % turn trucolor into 256-color indexed image
      temp = double(reshape(img,size(img,1)*size(img,2),3));
      [cmap,ii,jj] = unique(temp,'rows');
      img = reshape(jj,size(img,1),size(img,2));
      if max(cmap(:))>1
         % then assume that img was uint8 and thus cmap is 0-255
         cmap = cmap./255;
      end
   end
end
% I'm not sure why, but sometimes the image indices are 0-max-1
% and sometimes they're 1-max.  The following should fix that...
if min(img(:))<1
   img = img + 1;
end
if length(cmap)>256
   disp('You selected a true-color image with more than 256 colors');
   error('I can''t handle that yet!  Please fix you image.');
end

image(img); colormap(cmap); axis image; axis off;

cmap = round(255*cmap);
numColors = size(cmap,1);

if ~exist('gLocs2d','var') | isempty(gLocs2d)
   % load gLocs from a flat.mat file, if not provided
   [fname,pname] = uigetfile('*.mat',['Load a flat file']);
   if fname == 0
      return;
   end
   pname = [pname fname];
   load(pname);
   if ~exist('gLocs3d','var') | ~exist('gLocs2d','var')
      error('Invalid flat file- no gLocs2d and/or gLocs3d!');
   end
end

% Interpolate img onto gLocs2d
%
% rescale gLocs to fit into the image space
[imY,imX] = size(img);
gLocs2d(:,1) = gLocs2d(:,1)-min(gLocs2d(:,1));
gLocs2d(:,1) = gLocs2d(:,1)./max(gLocs2d(:,1)).*(imX-1)+1;
gLocs2d(:,2) = gLocs2d(:,2)-min(gLocs2d(:,2));
gLocs2d(:,2) = gLocs2d(:,2)./max(gLocs2d(:,2)).*(imY-1)+1;
%flatImg = interp2(img, gLocs2d(:,1)', gLocs2d(:,2));
flatImg = img(sub2ind(size(img),round(gLocs2d(:,2)),round(gLocs2d(:,1))));
%[b,m] = unique(gLocs2d,'rows');
%scatter(gLocs2d(m,1),gLocs2d(m,2),16,flatImg(m),'filled');
%      
if ~exist('filename','var') | isempty(filename)
  [fname pname] = uiputfile('*.fun','Save mrGray overlay file...');
  if fname == 0
    return;
  end
  filename = [pname fname];
end

%      
fid = fopen(filename,'w');

% Write out the number of colors
%
fprintf(fid,'%d\n',numColors);

% Write out the colormap [R,G,B]
%
fprintf(fid,'%d %d %d\n', cmap');

% Write out the location and index into the colormap for
% each data point.
%
fprintf(fid,'%d %d %d %d\n', [gLocs3d , flatImg(:)]');

fclose(fid);

fprintf('Finished saving image as overlay.\n');

return;

