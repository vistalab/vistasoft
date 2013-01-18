%function [havg_fsfast, havg_mrv] = er_compareBfloat2hAvg(scan,slice);
% 
% This is a tool for checking that the calling 
% of fs-fast tools from mrLoadRet produces maps
% that looks the same as if you just ran it from
% fs-fast.
%
% 04/03/04 ras.
global dataTYPES;

if ~exist('scan','var')     scan = 4;   end
if ~exist('slice','var')    slice = 4;  end
if ~exist('fsd','var')  fsd = 'bold_lo/lo1';    end

crop = dataTYPES(1).scanParams(scan).cropSize;
nrows = crop(1);
ncols = crop(2);

h = figure('Name',sprintf('Scan %i, Slice %i',scan,slice));
% load the files
bfname = sprintf('h_%03i.bfloat',slice-1);
bfloatPath = fullfile(pwd,fsd,bfname);
[havg_fsfast,evar_fsfast,dat] = fast_ldsxabfile(bfloatPath);
havg_fsfast = havg_fsfast(:,:,1); 
havg_fsfast = evar_fsfast;

haname = sprintf('Scan%i%shAvg%i.mat',scan,filesep,slice);
havgPath = fullfile(pwd,'Inplane','Original','TSeries',haname);
load(havgPath);
havg_mrv = reshape(tSeries(2,:),nrows,ncols);
havg_mrv = havg_mrv.*havg_mrv;

% % optional: restrict both images at 0
% havg_fsfast(havg_fsfast < 0) = 0;
% havg_mrv(havg_mrv < 0) = 0;

% get a scale that includes both images
bothImgs = [havg_fsfast(:); havg_mrv(:)];
clipMin = min(bothImgs);
clipMax = max(bothImgs);

% plot the fs-fast bfloat
subplot(2,2,1);
% imshow(havg_fsfast,[clipMin clipMax]);
imagesc(havg_fsfast);
set(gca,'XTick',[],'YTick',[]);
title('Fs-fast hAvg')
colorbar horiz;

% plot the mrLoadRet hAvg
subplot(2,2,2);
% imshow(havg_mrv,[clipMin clipMax]);
imagesc(havg_mrv);
set(gca,'XTick',[],'YTick',[]);
title('mrVista hAvg')
colorbar horiz;

% plot the difference
subplot(2,2,3);
% imshow(havg_fsfast(1:nrows,1:ncols,1)-havg_mrv,[clipMin clipMax]);
imagesc(havg_fsfast(1:nrows,1:ncols,1)-havg_mrv);
set(gca,'XTick',[],'YTick',[]);
title('Difference')
colorbar horiz;
% colormap hot;

% plot a line through the center row of each
subplot(2,2,4);
lineA = havg_fsfast(nrows/2,:,1);
lineB = havg_mrv(nrows/2,:);
X = 1:ncols;
plot(X,lineA,'r',X,lineB,'k');
title('Center line')

return