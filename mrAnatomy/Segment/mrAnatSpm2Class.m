function mrAnatSpm2Class(spmClassMatFile,WhiteThreshold,smoothSigma,minClusterSize);
% mrAnatSpm2Class - convert spm classification maps to .class files
%  mrAnatSpm2Class(spmClassMatFile,thresholds,smoothSigma,minClusterSize);
%  Options to do some thresholding and smoothing
%    Gray-white border falls at pobability white + WhiteThreshold = Probability Gray
%    Probability maps are smoothed by smoothSigma
%    Isolated clusters smaller than minClusterSize are removed
%
%  16-Jun-2005 SOD: split off from mrAnatClassifyVAnatomy

if ieNotDefined('spmClassMatFile'),
  spmClassMatFile = 'spmClass.mat';
end;
if ieNotDefined('WhiteThreshold'),
  WhiteThreshold = 0;
end;
if ieNotDefined('smoothSigma'),
  smoothSigma = 0;
end;
if ieNotDefined('minClusterSize'),
  minClusterSize = 0;
end;

% variable definitions
type.unknown = 0;
type.csf = 48;
type.gray = 32;
type.white = 16;

% load classifications
load(spmClassMatFile);
[p classFileNoExt]=fileparts(spmClassMatFile);
classFileName = fullfile(p,sprintf('%s_P0-%d_S%d_C%d.class',...
                                   classFileNoExt,...
                                   WhiteThreshold*100,...
                                   smoothSigma,minClusterSize));

% White matter threshold:  SPM returns uint8.  We assume that scales on a
% probability range, so 255/2 is half.  We might want to be a little more
% conservative.
threshold = WhiteThreshold*255;

% Create the classification structure. Initialize with the code for unknown. 
data = type.unknown*ones(size(wm));

% Optional smoothing of wm probability map
% Smoothing and keeping the same threshold will increase the white volume.
% So we might want to get the volume so we can adjust theshold to
% keep the volume the same.
if(smoothSigma > 0)
  wmVolume = length(find(wm(:)>threshold));
  wm  = dtiSmooth3(double(wm) /255, smoothSigma)*255;
  threshold = findMatrixThreshold(wm,wmVolume);
end

% This ordering is important. Apparently these classifications overlap from
% SPM -> if they are probablility maps they should  because the sum
% should be 100%.
% So we might want to define the wm threshold relative to gm and
% csf (and then the order "should" not matter). This however leads to an marked
% underestimation of the white/gray border, so i've abandoned it.
% Now of course the order matters again.
 
data(csf>threshold) = type.csf;
data(gm>threshold)  = type.gray;
% data(wm>threshold) = type.white;
if minClusterSize<=0,
  data(wm>threshold) = type.white;
else,
  
  % In principle, we could put some image processing in there to improve 
  % the white matter mask.  This is an example, but it didn't work to our
  % satisfaction.  The problem was that the thin tendrils in the occipital
  % lobe were lost.
  % 
  %  mask = wm>threshold;
  % mask = dtiCleanImageMask(mask, 2);
  % data(mask > 0.5)  = type.white;
  
  % Filling in some holes in both foreground and background
  data_clean = wm>threshold;
  data_clean = mrAnatClassifyCleanMask(data_clean,minClusterSize);
  data(data_clean==1) = type.white;
end;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up .class struct     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% flip axes to agree with mrGray conventions
data = permute(data,[2 1 3]);

szX = size(data,1);
szY = size(data,2);
szZ = size(data,3);

hdr.version = 2;
hdr.minor = 1;
hdr.voi = [1 szX 1 szY 1 szZ];
hdr.xsize = szX;
hdr.ysize = szY;
hdr.zsize = szZ;
hdr.params = [0 1 240 4 0 0]; % dummy values

class.type = type;
class.header = hdr;

[a b] = fileparts(classFileName);
class.filename = b;
class.data = data;

writeClassFile(class,classFileName);

return;
