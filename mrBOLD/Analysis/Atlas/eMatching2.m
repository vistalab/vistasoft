function [u, v, M, errorTimeSeries] = eMatching2(measured1, atlas1, measured2, atlas2, overlay, cmap, weights)
%
% [u, v, M, errorTimeSeries] = eMatching2(measured1, atlas1, measured2, atlas2, overlay, cmap, weights)
%
% Author:  RFD
% Purpose:
%    Simultaneous elastic matching of two pairs of images (measured & atlas
% pairs). The atlas images are simultaneously warped to best-fit the
% measured images.
%
% If an overlay is provided, then it will be warped along with the atlas
% and the display will be of measured + overlay. Otherwise, the display is
% simply the warped atlas.
%
% If weights is not empty, the force field will be weighted by these
% values. Must be the same size as the images.
%
% PARAMETERS:
%   measured1, atlas1, measured2, atlas2: single-channel ("grayscale")
%   images that contain the phase (radians) of the data.  In principle, the
%   algorithm should work on a complex-valued phase encoding.  But it
%   doesn't.  So, we try to keep the phase values away from the wrapping
%   boundaries.
%
%   overlay (optional): a single-channel image used only for display
%   purposes. It is warped along with the atlases and displayed superimposed on the
%   measured images.
%
%   cmap (optional): color LUT used to display measured images.
%
% RETURNS:
%   u and v: the cumulative displacement fields
%
%   M: Matlab movie or sequence of images: Tnew(0)...Tnew(k) 
%
%   errorTimeSeries: Frobeniusnorm of each timestep
%
% USES: 	
%   jmfft.m      This is the Fischer/Moderitski algorithm. 
%   updateTinC.c (has to be compiled with "mex updateTinC.c" in Matlab)
%
% HISTORY:
%   2001.07.13: core matching algorithm from Bernd Fischer <fischer@math.mu-luebeck.de>
%   2001.07.15 Dougherty, Wandell and Fischer: adapted algorithm to Volker
%   Koch's mrFindBorders code.
%   2001.07.20 Dougherty & Wandell: simultaneous warping of second image pair
%   using a simple weighted average of the two force fields (as suggested by Fischer).
%   2001.08.07 Dougherty: 
%   - revised documentation and cleaned code
%   - we now ignore image regions where the measured data are set to NAN
%     (force field is set to zero).
%   - we also apply a smoothed force field weighting map based on
%   the atlas, where atlas regions that are set to NAN are weighted less
%   than non-NAN regions. 
%   2003.09.04 Dougherty: more code & comment cleaning.
%   2005.02.15 Schira made little changes in the imaging function
%   eMatchRender.



if ieNotDefined('cmap'), cmap = hsv(64); end
if ieNotDefined('overlay'), overlay = []; end
if ieNotDefined('weights'), weights = []; end

imSize = size(atlas1);
atlasRow = imSize(1); atlasCol = imSize(2);
if(size(atlas2)~=imSize | size(measured1)~=imSize | size(measured2)~=imSize)
    error('All images must be the same size!');
end

% Switches
% plotflag = 1;            % view image of intermediate solutions at each step?

% on output: M is a Matlab movie (filmflag=1) or a sequence of images (filmflag=0)
filmflag=0;   if ~filmflag, M = []; end    
kmax = 1000;            % max number of iteration steps (calls the jmfft).
answer = setDefaultMatchingValues(atlas1);

if max(size(answer))>0
    mu = str2num(answer{1});
    lambda = str2num(answer{2});
    checkStopRange = str2num(answer{3});   
    p = str2num(answer{4});
    alpha = str2num(answer{5});
    eps_norm = str2num(answer{6});
    forceWeight1 = str2num(answer{7});
    forceWeight2 = str2num(answer{8});
    dataBlurFactor = str2num(answer{9});
    weightsBlurFactor = str2num(answer{10});
    forceBlurFactor = str2num(answer{11});
else
    error('operation cancelled in eMatching2');
end

% Initialize
%
k = 0;	% step counter
t = 0;	% time of flow
atLeastToHere = 0;  % Parameter controls a loop prior to querying the user about continuing.

% We need to understand a little more about para, this parameters
% structure.
% n = length(atlas1)-2;
para = struct('m', length(atlas1), 'n', length(atlas1), 'lambda', 0, 'mu', 1, 'BC', 'periodic');
jmfft('init', para);	% init equation solver

[X,Y] = ndgrid(1:max(imSize));

% Initialize displacement field and error time series
nullImg = zeros(imSize);
u1 = nullImg; u2 = nullImg;      
fx1 = nullImg; fy1 = nullImg; fx2 = nullImg; fy2 = nullImg; 
fmax1 = 0; fmax2 = 0;
errorTimeSeries = zeros(kmax,1);	

% The force weights are masks between 0 and 1 that define where the error
% is measured.  The current settings include the atlas and data regions.
% Relative weights are assigned to the error of each atlas by the scalars,
% forceWeight1 and forceWeight2.
force1WeightMask = (1-isnan(atlas1)).*(1-isnan(measured1)).*forceWeight1;
force2WeightMask = (1-isnan(atlas2)).*(1-isnan(measured2)).*forceWeight2;

% The point-by-point weights can be also sent in, sometimes these are set
% to be the correlation values.  If so, they are sometimes blurred and then
% combined with the forceWeight mask here.
if(~isempty(weights))
    weights(isnan(weights)) = 0;
    if(weightsBlurFactor>0)
        disp('Blurring weight image...');
        blurKernel = fspecial('gauss',9,weightsBlurFactor);
        weights = conv2(weights, blurKernel, 'same');
    end
    force1WeightMask = force1WeightMask .* weights;
    force2WeightMask = force2WeightMask .* weights;
end

% In earlier versions, we displayed the forceWeightMasks.  This is useful
% for debugging, so leave the comments here.  But the image is not
% particularly helpful when things are working.
% figure; 
% subplot(2,1,1); image(force1WeightMask*255+1); axis image; colormap(gray(256)); colorbar;
% title('Force weight mask for image 1');
% subplot(2,1,2); image(force2WeightMask*255+1); axis image; colormap(gray(256)); colorbar;
% title('Force weight mask for image 2');
% figure; image(measured1Scale); colormap(hsv(128));

% For computational purposes, we convert the NaNs to zeros.
%measured1(isnan(measured1)) = mean(measured1(~isnan(measured1(:))));
%measured2(isnan(measured2)) = mean(measured2(~isnan(measured2(:))));
%atlas1(isnan(atlas1)) = mean(atlas1(~isnan(atlas1(:))));
%atlas2(isnan(atlas2)) = mean(atlas2(~isnan(atlas2(:))));

% Blur data images
if(dataBlurFactor>0)
    disp('Blurring data images...');
    blurKernel = fspecial('gauss',9,dataBlurFactor);
    measured1 = conv2(measured1, blurKernel, 'same');
    measured2 = conv2(measured2, blurKernel, 'same');
end

atlas1New = atlas1;
atlas2New = atlas2;
imFig = figure;
errFig = 0;
overlayNew = overlay;

% Iterate (MAIN LOOP)
%
while k <= kmax   %kmax steps maximum
    % We weight the error with the forceWeightMasks.
    % if norm(atlas-measured,'fro')<eps_norm then STOP
    notNan1 = ~isnan(atlas1New)&~isnan(measured1);
    notNan2 = ~isnan(atlas2New)&~isnan(measured2);
    fronorm = norm((atlas1New(notNan1)-measured1(notNan1)).*force1WeightMask(notNan1) ...
                 + (atlas2New(notNan2)-measured2(notNan2)).*force2WeightMask(notNan2),'fro');
    if (fronorm < eps_norm)
        mhandle = msgbox(['precision reached, ||atlas-data|| = ',num2str(fronorm,8)]);
        waitfor(mhandle);
        break;
    end;

    % evaluate f(x,u(x,t))=-(atlas(x-u(x,t))-measured(x))* grad atlas(x-u(x,t))
    % fx1,fy1 and fx2,fy2 are forces in two different directions for the two different
    % data sets. Remove alpha- it has no effect?
    % May want to take edge image into account here (Gradient of reference image Gx^2 + Gy^2)
        
    fx1(2:end-1,2:end-1) = -alpha*(atlas1New(2:end-1,2:end-1)-measured1(2:end-1,2:end-1)) ...
        .*(atlas1New(3:end,2:end-1)-atlas1New(1:end-2,2:end-1))/2;
    fy1(2:end-1,2:end-1) = -alpha*(atlas1New(2:end-1,2:end-1)-measured1(2:end-1,2:end-1)) ...
        .*(atlas1New(2:end-1,3:end)-atlas1New(2:end-1,1:end-2))/2;
    fx2(2:end-1,2:end-1) = -alpha*(atlas2New(2:end-1,2:end-1)-measured2(2:end-1,2:end-1)) ...
        .*(atlas2New(3:end,2:end-1)-atlas2New(1:end-2,2:end-1))/2;
    fy2(2:end-1,2:end-1) = -alpha*(atlas2New(2:end-1,2:end-1)-measured2(2:end-1,2:end-1)) ...
        .*(atlas2New(2:end-1,3:end)-atlas2New(2:end-1,1:end-2))/2;   
    fx = force1WeightMask.*fx1 + force2WeightMask.*fx2;
    fy = force1WeightMask.*fy1 + force2WeightMask.*fy2;
 
   %getting rid of the NaN in force fields
   fx(isnan(fx))=0;
   fy(isnan(fy))=0;   
   
   % May want to smooth force fields
    if(forceBlurFactor>0)
        disp('Blurring force fields...');
        blurKernel = fspecial('gauss',9,forceBlurFactor);
        fx = conv2(fx, blurKernel, 'same');
        fy = conv2(fy, blurKernel, 'same');
    end
    
    % Useful for stopping criterion?
    fmax1 = max([fmax1,max(max(abs(fx)))]);
    fmax2 = max([fmax2,max(max(abs(fy)))]);   
    
    % ERROR CALCULATION WAS HERE
    
    % compute actual displacement field
    [u1,u2] = jmfft('solve',para,fx,fy);
    
    % update deformed image and boundaries
    maxu = max([max(max(u1)),max(max(u2))]);
    u1 = p*u1/maxu;  u2 = p*u2/maxu;
    X = X-u1;        Y = Y-u2;	
    
    
    atlas1New = updateTinC(atlas1,X,Y);
    atlas2New = updateTinC(atlas2,X,Y);
    
    % If this current error is the smallest one to date, calculate the
    % displacement fields that will be returned.
    if fronorm < min(errorTimeSeries)
        [u,v] = calculateUVFields(X,Y,atlasCol,atlasRow);
    end
    errorTimeSeries(k+1) = fronorm;
    
    % Stopping criterion
    if (k > checkStopRange) & (k > atLeastToHere)
        
        % Display the results
        eMatchRender(imFig,overlay,X,Y,measured1,atlas1New,measured2,atlas2New,cmap,errorTimeSeries);

        recent = mean(errorTimeSeries((k - checkStopRange/2):k));
        earlier = mean(errorTimeSeries((k-checkStopRange):(k - checkStopRange/2)));
        if recent/earlier > 0.90,  
            resp = questdlg(sprintf('Continue? (%.02f)',recent/earlier),'Continue minimization','Yes','No','No');
            switch resp
                case 'Yes'
                    atLeastToHere = k + checkStopRange/2;
                case 'No'
                    break;
            end
        end
    end
    
    if filmflag, M(k+1) = getframe;  end;
    
    
    % if(get(imFig,'UserData')==1), break; end
    % What is this pause about?
    % pause(0);
    
    k = k+1;
    errorTimeSeries = errorTimeSeries(1:k);
%     if (k>=kmax )
%         txt = 'Maximum steps reached..';
%     else 
%         txt = ['Number of timesteps used: ',num2str(k)];
%     end;
    
end;

% [u,v] = calculateUVFields(X,Y,atlasCol,atlasRow);

% We need to do the following because Bernd's routine above assumes
% that the grid has already been added to the deformation values, but 
% all of the other code assumes that it has not. 
% [x,y] = meshgrid(1:size(atlas1,2),1:size(atlas1,1));
% v = X-y;
% u = Y-x;

% close(imFig);
return;

%----------------------------------------------
function [u,v] = calculateUVFields(X,Y,atlasCol,atlasRow)
%
% Bernd's routine assumes that the grid has already been added to the
% deformation values, but  all of the local code assumes that it has not.
% So, this routine corrects for this difference so that the returned
% values, [u,v], are consistent with the other code.

[x,y] = meshgrid([1:atlasCol],[1:atlasRow]);
v = X-y;
u = Y-x;

return;

%---------------------------------------------------------
function  imFig = eMatchRender(imFig,overlay,X,Y,measured1,atlas1New,measured2,atlas2New,cmap,errorTimeSeries)
%
% This puts up the window with the atlas display.

if ieNotDefined('imFig'), imFig = figure; end

overlayNew = updateTinC(overlay,X,Y);
%indicies to crop the figures to the FLAT map part with data. Makes the
%very tini graphs a little big bigger. See changes in line 294 too
indi=find(sum(~isnan(measured1),2));
indj=find(sum(~isnan(measured1),1));

if(~isempty(overlayNew))
    figure(imFig);
    a=mergedImage(measured1(indi,indj), overlayNew(indi,indj), cmap);
    b=mergedImage(atlas1New(indi,indj), overlayNew(indi,indj), cmap);
    c=mergedImage(measured2(indi,indj), overlayNew(indi,indj), cmap);
    d=mergedImage(atlas2New(indi,indj), overlayNew(indi,indj), cmap); 
    
    ysize=length(indi);
    xsize=length(indj);
 
    set(imFig,'position',[10  300 xsize*4.2 ysize*4.2]);
    axes('units','pixels','position',[-20 -1 ysize*2 xsize*2]);
    image(a);axis off; axis equal;
    axes('units','pixels','position',[ysize*2+5 -1 ysize*2 xsize*2]);
    image(b);axis off; axis equal;
    
    axes('units','pixels','position',[-20 xsize*2.4 ysize*2 xsize*2]);
    image(c);axis off; axis equal;
    axes('units','pixels','position',[ysize*2+5 xsize*2.4 ysize*2 xsize*2]);
    image(d);axis off; axis equal;
    axes('units','pixels','position',[ysize*1.5 xsize*1.7 ysize*1 xsize*1]);
    plot(errorTimeSeries); axis square; 
end
return;

%-------------------------------------------
function rgb = mergedImage(img, overlay, cmap)
% transform the image into RGB
img = floor(img);
img(isnan(img)) = 1;
img(img<1) = 1;
img(img>size(cmap,1)) = size(cmap,1);
rgb(:,:,1) = reshape(cmap(img,1),size(img));
rgb(:,:,2) = reshape(cmap(img,2),size(img));
rgb(:,:,3) = reshape(cmap(img,3),size(img));
rgb(:,:,1) = rgb(:,:,1).*overlay;
rgb(:,:,2) = rgb(:,:,2).*overlay;
rgb(:,:,3) = rgb(:,:,3).*overlay;

return;

%-------------------------------------------
function answer = setDefaultMatchingValues(atlas1);

% Set default values
%
checkStopRange = 30;	% Compare first half and second half of this many steps
p = 0.25;               % max. 0.5 pixels of displacement per timestep
mu = 1;		            % 1554 	(quick-silver 20ƒC)
lambda = 0;             % 0.0834	(quick-silver 20ƒC)
alpha = 10;             % weighting parameter
eps_norm = 0.1;         % error precision
forceWeight1 = 1.0;     % weight factor for atlas1 
forceWeight2 = 1.0;     % weight factor for atlas2
dataBlurFactor = 0;   % kernel size for data blur filter
weightsBlurFactor = 0;% kernel size for weights blur filter
forceBlurFactor = 0.0;  % kernel size for weights forcefield filter

% dialog box
prompt = {'mu','lambda', ...
        'Break after how many steps?',...
        'Maximum displacement in pixels per timestep',...
        'Weighting parameter alpha',...
        'Tolerance in error (||atlasNew-measured||_F)',...
        'Force weight for image 1','Force weight for image 2',...
        'Data Blur (0-3)','Weights Blur (0-3)','Force Blur (0-3)'};

def = {num2str(mu),num2str(lambda),...
        num2str(checkStopRange),...
        num2str(p),...
        num2str(alpha),num2str(eps_norm),num2str(forceWeight1),num2str(forceWeight2),...
        num2str(dataBlurFactor),num2str(weightsBlurFactor),num2str(forceBlurFactor)};

lineSpacing = 1;

answer = inputdlg(prompt,'List of parameters',lineSpacing,def);

return;