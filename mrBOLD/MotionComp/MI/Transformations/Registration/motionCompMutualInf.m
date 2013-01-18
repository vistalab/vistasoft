 function [coregRotMatrix, tSeries, paramB] = motionCompMutualInf(view, tSeries, baseImage, baseScan, ROI, saveDir, actions, options)

%    [coregRotMatrix, tSeries] = motionCompMutualInf(view, tSeries,baseImage, baseScan, ROI, saveDir, actions, options)
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Revised version of mrSPM_coreg to include ROI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% gb 02/25/05
%
%
% Between modality coregistration for multiple scans/frames using information theory
% FORMAT coregRotMatrix = mrSPM_coreg(view, [scans], [frames], ...
%    [baseScan], [baseFrames], [correctedDir], [actions], [flags])
% view      - a view passed from mrLoadRet
% scans     - a vector of scan (session) numbers (e.g. [1,2,5]).
% frames    - a vector of frame numbers (1-based, e.g. [1:5] for image files 
%             from 000 through 004), or
%             a cell-array of scan-specific frame numbers (e.g. {[1,2],[1:3],[1,3]})
% baseScan  - a target scan - the basis that all other scans are corrected to
%             (default is min(scans))
% baseFrames- a vector of target frame numbers that all other frames are corrected to
%             (default = min(frames) or baseFrame = min(frames{min(scans)})
% saveDir   - a Directory where Scan folders containing the tSeries-files for
%             spatially realigned images must be written;
%             for now we assume that this Directory must exist on hard-drive;
%             (default = fullfile(viewGet(view,'subdir'),'SPM_coreg','TSeries'))
% actions   - a vector, defining the actions to do - coregister, reslice, or both
%             (default - [1,1] = coregister & reslice).
% options   - a vector of flags, passing into mrSPM_coregTwoFrames
%             (defaults - defined in the code below).
% coregRotMatrix - the parameters describing the rigid body rotation.
%   such that a mapping from voxels in frameA_img to voxels in frameB_img
%   is attained by:  matB\spm_matrix(coregRotMatrix(:)')*matA
%
% This function loads the 4D tSeries for each scan, then gets out the 3D matrix 
%   for each frame to be corrected, and finally saves the corrected results as tSeries 
%
% The registration method used here is based on the work described in:
% A Collignon, F Maes, D Delaere, D Vandermeulen, P Suetens & G Marchal
% (1995) "Automated Multi-modality Image Registration Based On
% Information Theory". In the proceedings of Information Processing in
% Medical Imaging (1995).  Y. Bizais et al. (eds.).  Kluwer Academic
% Publishers.
%_______________________________________________________________________
% MA, 11/11/2004: based on SMP2 coregistration code
% needs SPM2 toolbox to run

%_______________________________________________________________________
% gb 01/14/05
%
% Modification of the way to call this function (input and output
% arguments)

if ~exist('actions'); actions = [1,1]; end;
coreg = actions(1);
reslice = actions(2);
if length(actions)>1; reslice = actions(2); end;

if ieNotDefined('baseScan')
    baseScan = viewGet(view,'curscan');
end

global defaults
spm_defaults;
flags = defaults.coreg;

% SPM Defaults for Coreg:
% flags.estimate.cost_fun = 'nmi';
% flags.estimate.sep = [4 2];
% flags.estimate.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
% flags.estimate.fwhm = [7 7];
if exist('options', 'var');
    if isfield(options, 'cost_fun'), flags.estimate.cost_fun = options.cost_fun, end;
    if isfield(options, 'sep'), flags.estimate.sep = options.sep, end;
    if isfield(options, 'tol'), flags.estimate.tol = options.tol, end;
    if isfield(options, 'fwhm'), flags.estimate.fwhm = options.fwhm, end;
end;

% flags.estimate.cost_fun = 'mi';
% flags.estimate.params = [0 NaN 0 0 0 0];

mrGlobals; % Needs mrSESSION information
mmPerVox = mrSESSION.functionals(baseScan).voxelSize;
curDataType = viewGet(view,'curdatatype');

nFrames  = size(tSeries,1);
nVoxelsX = size(tSeries,2);
nVoxelsY = size(tSeries,3);
nSlices  = size(tSeries,4);

if ~isequal(size(baseImage),size(tSeries))
    try
        baseImage = reshape(baseImage,size(tSeries));
    catch
        error('The reference image does not have the correct size');
    end
end

imgA = squeeze(baseImage);

if ieNotDefined('ROI')
    ROI = ones(size(imgA));
end

origin = (size(imgA)+1)/2;
paramA.mat = inv([diag(1./mmPerVox), origin'; [0 0 0 1]]);
paramA.scale = 0.0232; paramB = paramA;

for curFrame = 1:nFrames;
    myDisp(['Frame #' int2str(curFrame)]);
    imgB = squeeze(tSeries(curFrame,:,:,:));

	if coreg;
        myDisp('Coregister...');
        coregRotMatrix = mrSPM_coregTwoFrames(imgA, imgB, paramA, paramB, flags.estimate,ROI);
    end;
    if reslice;
        %rotate the image:
        myDisp('Rotate and reslice...');
        imgB = mrSPM_rotateFrame(imgB, coregRotMatrix, paramB);
                
        %put it back into tSeries:
        tSeries(curFrame,:,:,:) = imgB;
    end;
end;

return;
%_______________________________________________________________________

