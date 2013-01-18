function [imX,imY,imZ] = dtiSaveImageSlicesOverlays(handles, overlayFGs, overlayROIs, queryParameters, fname, upSamp, curPosAcpc, bg)
%
%   dtiSaveImageSlicesOverlays(handles,[overlayFGs=[]],[overlayROIs=[]],[queryParameters=0],[fname],[upSamp])
%
%Author: Dougherty, Wandell
%Purpose:
%   Save out image slices.  Potentially we overlay the FGs and ROIs.
%   Potentially we query for the image processing parameters
%
% Examples:
%   dtiSaveImageSlicesOverlays(handles)       %Just slices, no overlays
%   dtiSaveImageSlicesOverlays(handles,1,0)   % Overlay fiber groups
%   dtiSaveImageSlicesOverlays(handles,1,0,1) % Overlay fiber groups and
%              query for imaging parameters

if ieNotDefined('overlayFGs'),  overlayFGs = []; end
if ieNotDefined('overlayROIs'), overlayROIs = []; end
if ieNotDefined('queryParameters'), queryParameters = 1; end
if(~exist('upSamp','var') | isempty(upSamp)) upSamp = 4; end
if(~exist('curPosAcpc','var') | isempty(curPosAcpc)) curPosAcpc = dtiGet(handles, 'acpcpos'); end
skipAxes = isnan(curPosAcpc);
curPosAcpc(skipAxes) = 0;
if(~exist('bg','var') | isempty(bg))
    bg = handles.bg(dtiGet(handles,'curbgnum'));
    bg.acpcToImgXform = dtiGet(handles, 'acpc2imgxform');
    bg.mmPerVox = bg.mmPerVoxel;
end

% May want to interpolate here...
curPosImgInt = round(mrAnatXformCoords(bg.acpcToImgXform, curPosAcpc));

if(size(bg.img,4)==3)
	% Special case for vector images
	z = squeeze(bg.img(:,:,curPosImgInt(3),:));
	y = squeeze(bg.img(:,curPosImgInt(2),:,:));
	x = squeeze(bg.img(curPosImgInt(1),:,:,:));
else
    z = repmat(squeeze(bg.img(:,:,curPosImgInt(3))),[1,1,3]);
    y = repmat(squeeze(bg.img(:,curPosImgInt(2),:)),[1,1,3]);
    x = repmat(squeeze(bg.img(curPosImgInt(1),:,:)),[1,1,3]);
end

curPosImg = mrAnatXformCoords(bg.acpcToImgXform, curPosAcpc);
if(~exist('fname','var')) fname = ''; end

% Maybe the user wanted to set the parameters
roiBlurSize = 0;
fgBlurSize = 0;
if queryParameters
    prompt={'Upsample factor (1,2,4,8,16):','ROI blur size:','Fiber blur size:'};
    def={num2str(upSamp),num2str(roiBlurSize),num2str(fgBlurSize)};
    dlgTitle='Image processing parameters';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);
    if isempty(answer), disp('dtiSaveImageSlice cancelled.'); return;
    else
        upSamp = str2num(answer{1});
        roiBlurSize = str2num(answer{2});
        fgBlurSize = str2num(answer{3});
    end
end

% Figure out the file
persistent imPath;
if(nargout==0 & isempty(fname))
    if(isempty(imPath)) imPath = fullfile(handles.defaultPath,'slice'); end
    [p,f,e] = fileparts(imPath);
    imPath = fullfile(p,f);
    [f, p] = uiputfile({'*.png'}, ['Save current view...'], imPath);
    if(isnumeric(f)), disp('dtiSaveImageSlices cancelled.'); fname = 'show';
    else [junk,f,e] = fileparts(f); fname = fullfile(p, f); end
end
imPath = fname;

% Start image processing code
upSamp = 2^round(log2(upSamp));

% Resizing the image
imX = imageResize(x,upSamp);
imY = imageResize(y,upSamp);
imZ = imageResize(z,upSamp);

% Which order?  Put down the ROI, then overlay the fibers on top of that.
if(~isempty(overlayROIs))
    [imX,imY,imZ] = dtiImageOverlayROIs(overlayROIs,upSamp,roiBlurSize,imX,imY,imZ,curPosImg,bg.acpcToImgXform);
end
if(~isempty(overlayFGs))
    [imX,imY,imZ] = dtiImageOverlayFGs(overlayFGs,upSamp,fgBlurSize,imX,imY,imZ,curPosImg,bg.acpcToImgXform);
end

imX = permute(imX,[2,1,3]);
imY = permute(imY,[2,1,3]);
imZ = permute(imZ,[2,1,3]);

for(ii=1:3)
    imX(:,:,ii) = flipud(imX(:,:,ii));
    imY(:,:,ii) = flipud(imY(:,:,ii));
    imZ(:,:,ii) = flipud(imZ(:,:,ii));
end

% Add a scale bar
cmBarLen = round(1/bg.mmPerVox(1) * 10 * upSamp);
cbarVal = max(imX(:));
imX(end-5, end-cmBarLen-5:end-5, :) = cbarVal;
imX(end-4, end-cmBarLen-5:end-5, :) = cbarVal;
cmBarLen = round(1/bg.mmPerVox(2) * 10 * upSamp);
cbarVal = max(imY(:));
imY(end-5, end-cmBarLen-5:end-5, :) = cbarVal;
imY(end-4, end-cmBarLen-5:end-5, :) = cbarVal;
cmBarLen = round(1/bg.mmPerVox(3) * 10 * upSamp);
cbarVal = max(imZ(:));
imZ(end-5, end-cmBarLen-5:end-5, :) = cbarVal;
imZ(end-4, end-cmBarLen-5:end-5, :) = cbarVal;

if(~isempty(fname))
    if(strcmp(fname,'show'))
        figure; image(imX./max(imX(:))); axis image; truesize;
        figure; image(imY./max(imY(:))); axis image; truesize;
        figure; image(imZ./max(imZ(:))); axis image; truesize;
    else
        imwrite(imX, [fname '_X.png']);
        disp(['Wrote X slice to ' fname '_X.png']);
        imwrite(imY, [fname '_Y.png']);
        disp(['Wrote Y slice to ' fname '_Y.png']);
        imwrite(imZ, [fname '_Z.png']);
        disp(['Wrote Z slice to ' fname '_Z.png']);
    end
end
return;

%------------------------------------------------
function imOut = imageResize(im,m)
%
%   imOut = imageResize(im,m)
%
%Author: Wandell, Dougherty
%Purpose:
%   Resize an RGB image.  Uses the local upSample/upConv code.
%

sz = size(im);
m = round(log2(m));
for ii=1:3, imOut(:,:,ii) = upSample(im(:,:,ii),m); end

% Old, slow code
% sz = size(im);
% newSize = [sz(1), sz(2)]*m;
% imOut = zeros(newSize); 
% for ii=1:3
%     imOut(:,:,ii) = imresize(im(:,:,ii),newSize,'bilinear');
% end
% return;


return;


%-----------------------------------------------------
function [imX,imY,imZ] = dtiImageOverlayFGs(overlayFGs,upSamp,blurSize,imX,imY,imZ,curPosImg,acpcToImgXform)
%
%        [imX,imY,imZ] = dtiImageOverlayFGs(handles,upSamp,blurSize,imX,imY,imZ,curPosImg,acpcToImgXform)
%
%Author: Dougherty, Wandell
%Purpose:
%   Add the fiber group positions to the image
%   It might be possible to upsample differently in the three dimensions.
%   But for now, we only upsample the whole data set with a single upSamp
%   value.
%

if ieNotDefined('upSamp'), upSamp = 1; end
if ieNotDefined('blurSize'), blurSize = 0; end

fpX = []; fpColorX = [];
fpY = []; fpColorY = [];
fpZ = []; fpColorZ = [];
for(grpNum=1:length(overlayFGs))
    if(overlayFGs(grpNum).visible)
        fp = horzcat(overlayFGs(grpNum).fibers{:});
        fp = mrAnatXformCoords(acpcToImgXform, fp');
        fiberColor = overlayFGs(grpNum).colorRgb/255;
        if(~isempty(fp))
            % Select those fiber points that are in this slice
            sfpX = fp(round(fp(:,1))==round(curPosImg(1)), [2,3])-1;
            sfpX = unique(round(sfpX.*upSamp),'rows');
            if(~isempty(sfpX))
                [mem,loc] = ismember(sfpX, fpX, 'rows');
                if(any(mem))
                    overlap = loc(loc>0);
                    for(ii=1:3)
                        fpColorX(overlap,ii) = fpColorX(overlap,ii)*0.5 + fiberColor(ii);
                    end
                end
                fpX = vertcat(fpX,sfpX(~mem,:));
                fpColorX = vertcat(fpColorX, repmat(fiberColor, sum(~mem), 1));
            end
            
            sfpY = fp(round(fp(:,2))==round(curPosImg(2)), [1,3])-1;
            sfpY = unique(round(sfpY.*upSamp),'rows');
            if(~isempty(sfpY))
                [mem,loc] = ismember(sfpY, fpY, 'rows');
                if(any(mem))
                    overlap = loc(loc>0);
                    for(ii=1:3)
                        fpColorY(overlap,ii) = fpColorY(overlap,ii)*0.5 + fiberColor(ii);
                    end
                end
                fpY = vertcat(fpY,sfpY(~mem,:));
                fpColorY = vertcat(fpColorY, repmat(fiberColor, sum(~mem), 1));
            end
            
            sfpZ = fp(round(fp(:,3))==round(curPosImg(3)), [1,2])-1;
            sfpZ = unique(round(sfpZ.*upSamp),'rows');
            if(~isempty(sfpZ))
                [mem,loc] = ismember(sfpZ, fpZ, 'rows');
                if(any(mem))
                    overlap = loc(loc>0);
                    for(ii=1:3)
                        fpColorZ(overlap,ii) = fpColorZ(overlap,ii)*0.5 + fiberColor(ii);
                    end
                end
                fpZ = vertcat(fpZ,sfpZ(~mem,:));
                fpColorZ = vertcat(fpColorZ, repmat(fiberColor, sum(~mem), 1));
            end
        end
    end
end

imX = dtiAddImageOverlay(imX, fpX, fpColorX, blurSize);
imY = dtiAddImageOverlay(imY, fpY, fpColorY, blurSize);
imZ = dtiAddImageOverlay(imZ, fpZ, fpColorZ, blurSize);

return;

%-----------------------------------------------------
function [imX,imY,imZ] = dtiImageOverlayROIs(overlayROIs,upSamp,blurSize,imX,imY,imZ,curPosImg,acpcToImgXform)
%
%   [imX,imY,imZ] = dtiImageOverlayROIs(overlayROIs,upSamp,blurSize,imX,imY,imZ,curPosImg,acpcToImgXform)
%
%Author: Dougherty, Wandell
%Purpose:
%   Add the ROI positions to the image
%

if ieNotDefined('upSamp'), error('upSamp required.'); end
if ieNotDefined('blurSize'), error('blurSize required.');; end

for(roiNum=1:length(overlayROIs))
    if(overlayROIs(roiNum).visible)
        roiPos = mrAnatXformCoords(acpcToImgXform, overlayROIs(roiNum).coords);
        roiColor =  dtiRoiGetColor(overlayROIs(roiNum));
        
        sroiPos = roiPos(round(roiPos(:,1))==round(curPosImg(1)),[2,3])';
        sroiPos = sroiPos.*upSamp;
        %sroiPosDilate = zeros(size(sroiPos,1)*upSamp,3);
        if(~isempty(sroiPos))
            % dilate up and to the left
            sroiPosDilate = [];
            for(ii=0:upSamp)
                for(jj=0:upSamp)
                    sroiPosDilate = [sroiPosDilate, [sroiPos(1,:)-ii; sroiPos(2,:)-jj]];
                end
            end
            imX = dtiAddImageOverlay(imX, round(sroiPosDilate)', roiColor, blurSize);
        end
        
        sroiPos = roiPos(round(roiPos(:,2))==round(curPosImg(2)),[1,3])';
        sroiPos = sroiPos.*upSamp;
        if(~isempty(sroiPos))
            sroiPosDilate = [];
            for(ii=0:upSamp)
                for(jj=0:upSamp)
                    sroiPosDilate = [sroiPosDilate, [sroiPos(1,:)-ii; sroiPos(2,:)-jj]];
                end
            end
            imY = dtiAddImageOverlay(imY, round(sroiPosDilate)', roiColor, blurSize);
        end

        sroiPos = roiPos(round(roiPos(:,3))==round(curPosImg(3)),[1,2])';
        sroiPos = sroiPos.*upSamp;
        if(~isempty(sroiPos))
            sroiPosDilate = [];
            for(ii=0:upSamp)
                for(jj=0:upSamp)
                    sroiPosDilate = [sroiPosDilate, [sroiPos(1,:)-ii; sroiPos(2,:)-jj]];
                end
            end
            imZ = dtiAddImageOverlay(imZ, round(sroiPosDilate)', roiColor, blurSize);
        end
        
    end
end

return;

%-----------------------------------------------------------
function newPts = dtiOverlayCoordXform(ax,upSamp,pts)
% Transform from acpc coordinates into image coordinates
newPts(2,:) = (-(ax(1,1) - pts(2,:)) + 1) *upSamp;
newPts(1,:) =  (ax(2,2) + (pts(1,:)  + 1)) *upSamp;
return;


