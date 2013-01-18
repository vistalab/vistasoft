function [imgRgb, overlayImg, overlayMaskImg, anatImg] = mrAnatOverlayMontage(overlayImg, xform, anatImg, anatXform, cmap, overlayClipRng, acpcSlices, fname, plane, alpha, labelFlag, upsamp, numAcross, clusterThresh, autoCropBorder)
% imgRgb = mrAnatOverlayMontage(overlayImg, xform, anatImg, anatXform, cmap, overlayClipRng, acpcSlices, [fname], [plane=3], [alpha=1], [labelFlag=true], [upsamp=0], [numAcross=[]], [clusterThresh=0], [autoCropBorder=0])
%
% Quick hack for displaying nice overlay montages.
% plane: presents sagittal (1) coronal (2) or axial (3) slices. default is
% axials.   STILL A PROBLEM WITH THE SLICE SELECTION!!!
%
% HISTORY:
% 2006.08.07 RFD: wrote it.
% 2006.08.10 MBS: added plane flag

if(~exist('cmap','var')) cmap = []; end
if(~exist('fname','var')) fname = ''; end
if(~exist('plane','var')||isempty(plane)) plane = 3; end
if(~exist('alpha','var')||isempty(alpha)) alpha = 1; end
if(~exist('labelFlag','var')||isempty(labelFlag)) labelFlag = true; end
if(size(overlayImg,4)~=3&&size(overlayImg,4)~=1)
    error('overlay must be XxYxZ or XxYxZx3!');
end
if(~exist('upsamp','var')||isempty(upsamp)) upsamp = 0; end
if(~exist('numAcross','var')) numAcross = []; end
overlayInterp = [0 0 0 0 0 0];
if(~exist('clusterThresh','var')||isempty(clusterThresh)) clusterThresh = 0; end
clusterConnectivity = 18;

% Set to Inf for no autocropping
if ~exist('autoCropBorder', 'var') || isempty(autoCropBorder)
autoCropBorder = 0;
end

[t,r,s,k] = affineDecompose(xform);
if(size(anatXform,1)==1 || size(anatXform,2)==1)
    % assume it's not a full xform but just mmPerVox. To convert it to a
    % full xform, we have to assume that it is the same as the overlay
    % xform except for maybe a scale difference.
    anatMmPerVox = anatXform(:)';
    anatXform = xform*diag([anatXform./s 1]);
else
    [at,ar,anatMmPerVox,ak] = affineDecompose(anatXform);
end

if(isfinite(autoCropBorder))
    tmp = sum(anatImg,3);
    x = find(sum(tmp,1)); x = [x(1) x(end)];
    y = find(sum(tmp,2)); y = [y(1) y(end)];
    tmp = squeeze(sum(anatImg,1));
    z = find(sum(tmp,1)); z = [z(1) z(end)];
    clear tmp;
    pad = [-autoCropBorder autoCropBorder];
    x = x+pad; y = y+pad; z = z+pad;
    anatImg = anatImg(y(1):y(2),x(1):x(2),z(1):z(2));
    anatXform = inv(inv(anatXform)*[1 0 0 -y(1); 0 1 0 -x(1); 0 0 1 -z(1); 0 0 0 1]);
end

anatSz = size(anatImg);
if(alpha>0)
    overlaySz = size(overlayImg);
    if(size(overlayImg,4)>1)
        overlayMaskImg = repmat(double(mean(overlayImg,4)>overlayClipRng(1)),[1 1 1 size(overlayImg,4)]);
    else
        overlayMaskImg = double(overlayImg>overlayClipRng(1));
    end
    if(clusterThresh>0)
        overlayMaskImg = double(bwareaopen(overlayMaskImg,clusterThresh,clusterConnectivity));
    end
    if(~all(xform(:)==anatXform(:)) || ~all(anatSz(1:3)==overlaySz(1:3)))
        %bb = dtiGet(0,'defaultBoundingBox');
        bb = anatXform*[1,1,1,1;[anatSz,1]]';
        bb = bb(1:3,:)';
        disp('Resampling overlay image to match background image resolution...');
        overlayImg = mrAnatResliceSpm(overlayImg, inv(xform), bb, anatMmPerVox, overlayInterp, false);
        overlayMaskImg = mrAnatResliceSpm(overlayMaskImg, inv(xform), bb, anatMmPerVox, overlayInterp, false);
    end
    overlayImg(overlayImg>overlayClipRng(2)) = overlayClipRng(2);
    overlayImg = (overlayImg-overlayClipRng(1))./(overlayClipRng(2)-overlayClipRng(1));
else
    overlayImg = [];
end
slXform = inv(anatXform);
if plane==3
    % axials, reorient so that the eyes point up
    perm = [2 1 3 4]; 
    flip = 1;
    for(ii=1:length(acpcSlices)) slLabel{ii} = sprintf('Z = %d',acpcSlices(ii)); end
    slImg = slXform*[zeros(length(acpcSlices),2) acpcSlices' ones(length(acpcSlices),1)]';
    slImg = round(slImg(3,:));
elseif plane==1
    % sagittals, looking left
    perm = [3 2 1 4];
    flip = [2,1];
    for(ii=1:length(acpcSlices)) slLabel{ii} = sprintf('X = %d',acpcSlices(ii)); end
    slImg = slXform*[acpcSlices' zeros(length(acpcSlices),2) ones(length(acpcSlices),1)]';
    slImg = round(slImg(1,:));
elseif plane==2
    % coronals
    perm = [3 1 2 4];
    flip = 1;
    for(ii=1:length(acpcSlices)) slLabel{ii} = sprintf('Y = %d',acpcSlices(ii)); end
    slImg = slXform*[zeros(length(acpcSlices),1) acpcSlices' zeros(length(acpcSlices),1) ones(length(acpcSlices),1)]';
    slImg = round(slImg(2,:));
end
anatImg = flipdim(permute(anatImg,perm),flip(1));
if(numel(flip)>1), anatImg = flipdim(anatImg,flip(2)); end
if(~isempty(overlayImg))
    overlayImg = flipdim(permute(overlayImg,perm),flip(1));
    overlayMaskImg = flipdim(permute(overlayMaskImg,perm),flip(1));
    if(numel(flip)>1)
        overlayImg = flipdim(overlayImg,flip(2));
        overlayMaskImg = flipdim(overlayMaskImg,flip(2)); 
    end
end
 
if(~labelFlag) slLabel = ''; end

[imgRgb,junk,numColsRows] = makeMontage3(anatImg, slImg, anatMmPerVox(1), upsamp, [], numAcross, 0);
if(~isempty(overlayImg))
    overlayMask = makeMontage3(overlayMaskImg, slImg, anatMmPerVox(1), upsamp, [], numAcross, 0);
    overlayMask = overlayMask>=0.5;
    overlay = makeMontage3(overlayImg, slImg, anatMmPerVox(1), upsamp, [], numAcross, 0);
    if(size(overlayImg,4)==3)
        if(alpha>1)
            % alpha>1 applies a gamma to the transparency map
            g = 1/alpha;
            alpha = 1;
            lum = repmat(mean(overlay,3).^g,[1,1,3]);
            imgRgb(overlayMask) = (1-lum(overlayMask).*alpha).*imgRgb(overlayMask) + lum(overlayMask).*alpha.*overlay(overlayMask);
        else
            imgRgb(overlayMask) = (1-alpha).*imgRgb(overlayMask) + alpha.*overlay(overlayMask);
        end
    else
        if(isempty(cmap)), cmap = autumn(256); end
        overlay = mean(overlay,3);
        %n = isnan(overlay);
        %overlay(n) = 0;
        %if(size(overlay,3)>1)
        %    n = sum(n,3); n(n==0) = NaN;
        %    overlay = sum(overlay,3)./sum(n,3);
        %    overlay(isnan(n)) = 0;
        %end
        inds = round(overlay*255+1);
        inds(isnan(inds)) = 1;
        overlay = reshape(cmap(inds,:),[size(overlay) 3]);
        overlay(~overlayMask|isnan(overlay)) = 0;
        imgRgb(overlayMask) = (1-alpha).*imgRgb(overlayMask) + alpha.*overlay(overlayMask);
    end
end
figure;
if(exist('imshow.m','file'))
  iptsetpref('ImshowBorder','tight')
  imshow(imgRgb);
else
  image(imgRgb); axis equal; axis off;
  set(gca,'Position',[0,0,1,1]);
end
set(gcf,'userData',imgRgb);
disp('im=get(gcf,''userData''); % get the raw image data');
mrUtilLabelMontage(slLabel, numColsRows, gcf, gca);

if(~isempty(fname)) mrUtilPrintFigure(fname); end
if(~isempty(overlayImg))
    legendLabels = explode(',',sprintf('%0.0f,',linspace(overlayClipRng(1),overlayClipRng(2),5)));
    legendLabels = legendLabels(1:end-1);
    legendLabels{end} = ['>=' num2str(overlayClipRng(2),'%0.3g')];
    if(~isempty(cmap))
        %if(~isempty(fname)) mrUtilMakeColorbar(cmap, legendLabels, '', [fname '_legend']);
        %else  mrUtilMakeColorbar(cmap, legendLabels, ''); end
    end
end

% be kind to those who forget a semicolon:
if(nargout<1) clear imgRgb; end
return;
