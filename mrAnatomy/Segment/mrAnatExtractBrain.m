function [brainMask,checkSlices] = mrAnatExtractBrain(img, mmPerVox, betLevel, outFile)
%Uses the FSL BET tool to compute a brain mask for the given image volume.
%
% [brainMask,checkSlices] = mrAnatExtractBrain([img], [mmPerVox=[1,1,1]], [betLevel=0.5], [outFile])
%
% The betLevel is the BET fractional intensity threshold parameter. It
% should be [0-1]. The default of 0.5 usually works well. Smaller values
% will yield a larger brain estimate. If you get brain stuff chopped off,
% try a lower value. If you get non-brain stuff included, try a larger
% value.
%
% If you provide an array of betLevel values, you'll get a cell array of
% length(betLevel) brain masks back.
%
% checkSlices is a montage of every 3rd slice with the mask shown in blue
% and the underlying anatomy on yellow. Again, for length(betLevels)>1,
% you'll get a cell array.
%
% img can be a string, in which case it is assumed to be a NIFTI filename.
% or, it can be a NIFTI struct (as from niftiRead). In both cases,
% mmPerVox is ignored and instead gleaned from the NIFTI header.
%
% If no output arguments are captured, the brain mask is saved in the same
% place as the input file, but with '_mask' appended to the name.
%
% HISTORY:
% 2006.02.02 RFD: wrote it.
%
% Bob (c) Stanford VISTASOFT, 2006

if(~exist('betLevel','var') || isempty(betLevel)), betLevel = 0.5; end
if(~exist('mmPerVox','var') || isempty(mmPerVox)), mmPerVox = [1 1 1]; end

if(~exist('img','var') || isempty(img))
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a t1-weighted NIFTI file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    img = fullfile(p,f);
end

if(isstruct(img))
    % It's a nifti image
    ni = img;
    mmPerVox = ni.pixdim;
    img = ni.data;
elseif(ischar(img))
    % It's a nifti filename
    ni = niftiRead(img);
    mmPerVox = ni.pixdim;
elseif(nargout==0)
    error('If you pass in raw image data, you must capture at least one output!');
end

% TODO: more robust way to find cygwin on PC
if(ispc), bash = 'c:/cygwin/bin/bash.exe';
else      bash = 'bash';
end


% First try the shell for the preferrred FSL location, if it is not found
% then we'll test to see if the user is running OSX, if so then we'll point
% to an OSX version of bet2 (bet2_osx) else we'll point to the linux
% version.
[stat,res] = system('which bet2');
if(stat==0 && ~isempty(res))
    bet = res(1:end-1);
else
    if(ismac)
        bet = fullfile(fileparts(which(mfilename)), 'bet2_osx');
    else
        bet = fullfile(fileparts(which(mfilename)), 'bet2');
    end
end

bet = strtrim(bet); % The name of the bet funciton on the system

% Set temporary file names for the out file and bet script. These will be
% removed at the end of the function run.
out = [tempname, '_bet_temp'];
betScript = [tempname, '_bet_script.sh'];

if(ischar(img))
    out = img;
else
    img = double(img);
    mx = max(abs(img(:)));
    img = int16(round(img./mx.*32767));
    analyzeWrite(img, out, mmPerVox);   % Why not write a nifti?
end

% We could specify a better starting position for the BET surface
% sphere estimate, e.g., by using the talairach landmarks.
if(nargout==0)
    [p,f,e] = fileparts(ni.fname);
    [x,f,e2] = fileparts(f);
    imBaseName = fullfile(p,f);
end

%% Run brain extraction tool for each level
for ii=1:numel(betLevel)
    betOut = tempname;
    betCmd = [bet ' ' out ' ' betOut ' -mnf ' num2str(betLevel(ii))];
    fid = fopen(betScript,'wt');
    fprintf(fid,'#!/bin/bash\nexport FSLOUTPUTTYPE=NIFTI_GZ\n%s\n',betCmd);
    fclose(fid);
    unix([bash ' ' betScript]);
    betOut = [betOut '_mask.nii.gz'];
    if(nargout==0)
        if(numel(betLevel)>1)
            movefile(betOut, sprintf('%s_mask_f%02d',imBaseName,betLevel(ii)*100));
        else
            movefile(betOut, [imBaseName '_mask.nii.gz']);
        end
    else
        brainMaskFile{ii} = betOut;
    end
end

%% Manage outputs, but not sure about the logic here.
if(nargout>0)
    tmp = niftiRead(betOut);
    brainMask{ii} = logical(tmp.data);
    if(nargout>1)
        slices = [1:3:size(brainMask{ii},3)-6];
        if(ischar(img))
            im = double(makeMontage(ni.data, slices));
        else
            im = double(makeMontage(img, slices));
        end
        im = mrAnatHistogramClip(im, 0.4, 0.99);
        im = uint8(round(im./max(im(:)).*255));
        im(:,:,2) = im(:,:,1);
        im(:,:,3) = uint8(double(makeMontage(brainMask{ii},slices)).*255);
        checkSlices{ii} = im;
    end
end

if(nargout>0)
    if(length(betLevel)==1)
        brainMask = brainMask{1};
        if(exist('checkSlices','var')), checkSlices = checkSlices{1}; end
    end
else
    clear all;
end


%% Clean up

% Remove the betScript from the tempdir
delete(betScript)

% If img and out are the same then it is a temporary file and should be removed.
% If not, then it was passed in from a location on disk and should be preserved
if ~strcmp(img, out) && strfind(out, tempdir) && exist(out,'file')
    delete(out)
end


%% Return

return




%% Example script

bd = pwd;
d = dir('*0*');
subDirs = {d.name};
betLevel = 0.45;

for(ii=1:length(subDirs))
    t1 = fullfile(bd,subDirs{ii},'t1','t1');
    if(exist([t1 '.nii.gz'],'file'))
        t1Ni = niftiRead([t1 '.nii.gz']);
        [brainMask,checkSlices] = mrAnatExtractBrain(t1Ni.data, t1Ni.pixdim, betLevel);
        figure(99); image(checkSlices); axis image tight off;
        dtiWriteNiftiWrapper(uint8(brainMask), t1Ni.qto_xyz, [t1 '_mask.nii.gz']);
        ccPerPixel = prod(t1Ni.pixdim(1:3))/1000;
        brainVolumeCc(ii) = numel(find(brainMask)) * ccPerPixel;
    end
end

outFile = 'brainVolumes.txt';
fid = fopen(outFile,'wt');
for(ii=1:length(subDirs))
    %t1Mask = niftiRead(fullfile(bd,subDirs{ii},'t1','t1_mask.nii.gz'));
    %ccPerPixel = prod(t1Mask.pixdim(1:3))/1000;
    %brainVolumeCc(ii) = numel(find(t1Mask.data)) * ccPerPixel;
    fprintf(fid,'%s\t%0.1f\n',subDirs{ii},brainVolumeCc(ii));
end
fclose(fid);

