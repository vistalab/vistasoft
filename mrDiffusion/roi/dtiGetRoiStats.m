function [s, str] = dtiGetRoiStats(handles, roiNum, verbose)
% Calculate statistics for the specified ROI in the current bg image
%
% [s, str] = dtiGetRoiStats(handles, roiNum, [verbose=false]) 
%
% roiNum: Which ROI.  The case roiNum = 0 means use the current position.  
%
% An ROI is a  a set of points on some arbitrary grid (usually 1mm
% isotropic). To produce reasonable stats, we convert these points to the
% native image space and compute the stats for voxels that contain at least
% one ROI point. Thus, the volume measurement for the same ROI may differ
% depending on which background you use to compute the stats. (It will
% generally decrease as the resolution of the background image increases.)
%
% RETURNS:
%  str: a string description of the stats
%    s: a structure with the stats
%
% HISTORY:
% 2003.12.01 RFD (bob@white.stanford.edu) wrote it.
% 2006.12.07 RFD: fixed a bug that caused the voxels selected by this
%   algorithm to not exactly match the ones shown on the display.
% 2012.09.02 BW  Adjust inserted spatial interpolation option
%
% Bob (c) Stanford VISTASOFT, 2003


%% Parameters
if(~exist('roiNum','var') || isempty(roiNum)), roiNum = 0; end
if(~exist('verbose','var') || isempty(verbose)), verbose = false; end

if(roiNum<=0)
  coords = dtiGet(handles, 'acpcPos');
  name = ['ac-pc position [' num2str(coords) ']'];
else    
  if(isempty(handles.rois) || ~roiNum>length(handles.rois) || ...
          isempty(handles.rois(roiNum).coords))
    s = [];
    str = 'Invalid or empty ROI.';
    return;
  end
  coords = handles.rois(roiNum).coords;
  name   = handles.rois(roiNum).name;
end

% Retrieve parameters
n          = dtiGet(handles,'bg num');
anat       = dtiGet(handles,'bg image',n);
mmPerVoxel = dtiGet(handles,'bg mmpervox',n);
xform      = dtiGet(handles,'bg img2acpc xform',n);
imgName    = dtiGet(handles,'bg name',n);
valRange   = dtiGet(handles,'bg range',n);
% [anat,mmPerVoxel,xform,imgName,valRange] = dtiGetCurAnat(handles);

%% Transform ROI coordinates from acpc to image
% We should get the right xform above, rather than invert it here
ic = mrAnatXformCoords(inv(xform), coords);
ic = unique(ceil(ic),'rows');
sz = size(anat);
imgIndices = sub2ind(sz(1:3), ic(:,1), ic(:,2), ic(:,3));

%% Start building up the statistics
s.roiName = name;
s.imgName = imgName;
s.subjectName = handles.subName;
s.n = length(imgIndices);

if(size(coords,1)>1), s.centerOfMass = mean(coords);
else  s.centerOfMass = coords; 
end
s.volume = s.n*prod(mmPerVoxel);

if(length(sz)==3)
    imgVals = anat(imgIndices)';
    fstr = ['\n\n   ROI: %s\n  image: %s\n   sub: %s\nvolume: %0.2f mm^3\n   min: %0.3f\n   max: %0.3f\n' ...
            '  mean: %0.3f\n   std: %0.3f\n   SNR: %0.3f\n     n: %d\n Tal mn: [%0.1f %0.1f %0.1f]\n'];
else
    for ii=1:sz(4)
        imgVals(:,ii) = anat(imgIndices + prod(sz(1:3))*(ii-1));
    end
    fstr = ['\n\n'...
        'ROI: %s\n   '...
        'image: %s\n   '...
        'sub: %s\n   '...
        'volume: %0.2f mm^3\n   '...
        'min: [%0.3f %0.3f %0.3f]\n   '...
        'max: [%0.3f %0.3f %0.3f]\n   ' ...
        'mean: [%0.3f %0.3f %0.3f]\n   '...
        'std: [%0.3f %0.3f %0.3f]\n   '...
        'SNR: [%0.3f %0.3f %0.3f]\n   '...
        'n: %d\n Tal mn: [%0.1f %0.1f %0.1f]\n'];
end

imgVals = imgVals(~isnan(imgVals));

%% Create the stats structure
s.meanNorm = mean(imgVals);
s.mean    = s.meanNorm*(diff(valRange))+valRange(1);
s.stdNorm = std(imgVals);
s.std     = s.stdNorm*(diff(valRange))+valRange(1);
s.snr     = s.mean./s.std;
s.snrNorm = s.meanNorm./s.stdNorm;
s.minNorm = min(imgVals);
s.min     = s.minNorm*(diff(valRange))+valRange(1);
s.maxNorm = max(imgVals);
s.max     = s.maxNorm*(diff(valRange))+valRange(1);

%% Create the string for printing
str = sprintf(fstr, s.roiName, s.imgName, s.subjectName, s.volume, s.min, ...
    s.max, s.mean, s.std, s.snr, s.n, s.centerOfMass);

n = length(imgVals);

[voiCenter,voiLength] = mtrConvertRoiToBox(coords,xform);
str = sprintf('%sROI Bounding Box Pos (ijk): %0.1f, %0.1f, %0.1f\n',str,round(voiCenter*10)/10);
str = sprintf('%sROI Bounding Box Size (ijk): %0.1f, %0.1f, %0.1f\n',str,round(voiLength*10)/10);

%% Verbose flag, adds more information
if(verbose)
    if(n>10)
        figure('name',[s.imgName ' in ' s.roiName ' (' , s.subjectName ')']);
        imgVals = imgVals*(diff(valRange))+valRange(1);
        %nbins = round(3.49*s.std*n.^(1/3));
        nbins = round(n.^(1/3));
        hist(imgVals,nbins);
        set(gca,'fontsize',18);
        xlabel(s.imgName,'FontSize',18);
        ylabel('Voxel Count','FontSize',18);
        setappdata(gcf,'data',imgVals);
        disp('use d=getappdata(gcf,''data''); to get the image values.');
    end

    % Also provide tensor stats summary
    ic = ceil(mrAnatXformCoords(inv(handles.xformToAcpc), coords));
    sz = size(handles.dt6);
    ic = sub2ind(sz(1:3), ic(:,1), ic(:,2), ic(:,3));
    ic = unique(ic);
    dt = reshape(handles.dt6,[prod(sz(1:3)) 6]);
    [vec,val] = dtiEig(dt(ic,:));
    % dtiDirMean collapses across the 'subject' dimension (the last
    % dim), so we need the fancy reshaping to get it to do what we want.
    [dirMn, dirDisp] = dtiDirMean(shiftdim(squeeze(vec(:,:,1))',-1));

    str = sprintf('%sTensor stats:\nPDD mean = [%0.2f %0.2f %0.2f], PDD dispersion = %0.3f\n', ...
        str, dirMn(1), dirMn(2), dirMn(3), dirDisp);
    if(size(val,1)>1), mnVal = mean(val); else mnVal = val; end
    
    % @@TH need more significant places
    str = sprintf('%sMean Eigenvalues = [%0.4f %0.4f %0.4f]\n\n', str, mnVal(1), mnVal(2), mnVal(3));

end

return;

