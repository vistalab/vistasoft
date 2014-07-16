function mtrCreateConTrackOptionsFromROIs(bInteractive,bOnlyPDF,localSubDir, roi1File, roi2File, roiWayFile, inSamplerOptsFile, outSamplerOptsFile, fgFile, roisMaskFile, xMaskFile, wmProbFile, scriptFileName, remoteSubDir, machineList)
% Creates options file that is necessary for either using ConTrack scoring
% or ConTrack pathway creation.
%
%  mtrCreateConTrackOptionsFromROIs(bInteractive,bOnlyPDF,localSubDir,
%  roi1File, roi2File, roiWayFile, inSamplerOptsFile, outSamplerOptsFile, fgFile, roisMaskFile, xMaskFile, wmProbFile, scriptFileName, remoteSubDir, machineList)
%
% INPUT
% roi1File, roi2File: List of coordinates in ACPC space that specify two
%   regions of interest in our DTI data that we would like to find pathways
%   connecting between.  These points are turned into a binary mask image by
%   setting all voxels, with diffusion image resolution, to 1 that contain
%   an roi point. At this time the ROIs must not have any voxels in common.
% inSamplerOptsFile: Contains the parameters to run the ConTrack algorithm.
%   Can use mtrCreate() in order to make a default file.
%
% OUTPUT
% fgFile: Pathway file for storing the database of pathways that connect
%   the two ROIs.
% roisMaskFile: Binary image containing non-zero voxels where the ROIs were
%   defined and zero elsewhere.
% pdfFile: Probability distribution function file that
%  is used during tractography in order to represent scanner noise per
%  voxel as well as shape information of the tensor fit per voxel. Data
%  stored: EVec3,EVec2,EVec1,k1,k2,Cl,EVal2,EVal3.
%
% Examples:
%
% Author: AJS
%
if( ieNotDefined('bOnlyPDF') )
    bOnlyPDF = 0;
end
if( ieNotDefined('bInteractive') )
    bInteractive = 1;
end
% If not interactive assume we are in dt6 directory



%% Get Input Files
bParallelScript = 0;
if( ~ieNotDefined('scriptFileName') )
    bParallelScript = 1;
end

% Get filenames needed
if (ieNotDefined('localSubDir'))
    if bInteractive
        [f,p] = uigetfile('*.mat', 'Point to the dt6 file ...');
        if(isnumeric(f)); error('User cancelled.'); end
        localSubDir = p;
    else
        localSubDir = pwd;
    end
end
% Get the directory above this one
% f=[];
% while isempty(f)
%     keyboard;
%     [localSubDir, f, foo, foo] = fileparts(localSubDir);
% end
%dt6Dir = f;
dt6Dir = localSubDir;

if (ieNotDefined('roi1File'))
    %[f,p] = uigetfile('*.mat', 'Load the ROI 1 file ...', fullfile(localSubDir,'ROIs','roi1.mat'));
    if bInteractive
        [f] = uigetfile('*.mat', 'Load the ROI 1 file ...', fullfile(localSubDir,'ROIs','roi1.mat'));
        if(isnumeric(f)); error('User cancelled.'); end
        roi1File = f;
    else
        roi1File = 'none';
    end
end
if (ieNotDefined('roi2File'))
    %[f,p] = uigetfile('*.mat', 'Load the ROI 2 file ...', fullfile(localSubDir,'ROIs','roi2.mat'));
    if bInteractive
        [f] = uigetfile('*.mat', 'Load the ROI 2 file ...', fullfile(localSubDir,'ROIs','roi2.mat'));
        if(isnumeric(f)); error('User cancelled.'); end
        roi2File = f;
    else
        roi2File = 'none';
    end
end

if(0)
    if (ieNotDefined('roiWayFile'))
        %[f,p] = uigetfile('*.mat', 'Load the ROI 2 file ...', fullfile(localSubDir,'ROIs','roi2.mat'));
        if bInteractive
            [f] = uigetfile('*.mat', 'Load the ROI Waypoint file ...', fullfile(localSubDir,'ROIs','roiWay.mat'));
            if(~isnumeric(f));
                roiWayFile = f;
            else
                roiWayFile = 'none';
            end
        else
            roiWayFile = 'none';
        end
    end

    if (ieNotDefined('inSamplerOptsFile'))
        if bInteractive
            [f,p] = uigetfile('*.txt', 'Load the tracking parameters file ...', fullfile(localSubDir,'fibers','conTrack','met_params.txt'));
            inSamplerOptsFile = fullfile(p,f);
        else
            inSamplerOptsFile = fullfile(localSubDir,'fibers','conTrack','met_params.txt');
        end
    end
    if (ieNotDefined('outSamplerOptsFile'))
        if bInteractive
            [f] = uiputfile('*.txt', 'Save new tracking parameters file ...', fullfile(localSubDir,'fibers','conTrack','met_params.txt'));
            %[f,p] = uiputfile('*.txt', 'Save new tracking parameters file ...', fullfile(localSubDir,'conTrack','met_params.txt'));
            outSamplerOptsFile = f;
        else
            outSamplerOptsFile = 'met_params.txt';
        end
    end
    if (ieNotDefined('xMaskFile'))
        if bInteractive
            resp = questdlg('Would you like to specify an exclusion mask image?','Exclusion Mask','No');
            if(strcmpi(resp,'Yes'))
                [f] = uigetfile('*.nii.gz', 'Exclusion mask image ...', fullfile(localSubDir,'bin','xMask.nii.gz'));
                if(isnumeric(f)); error('User cancelled.'); end
                xMaskFile = f;
            elseif(strcmpi(resp,'No'))
                xMaskFile = 'none';
            else
                error('User cancelled.');
            end
        else
            xMaskFile = 'none';
        end
    end
end

   if (ieNotDefined('roisMaskFile'))
        %outPathName = pwd;
        %[f,p] = uiputfile('*.nii.gz', 'Output file for ROIs mask image ...', fullfile(localSubDir,'bin','roisMask.nii.gz'));
        if bInteractive
            [f] = uiputfile('*.nii.gz', 'Output file for ROIs mask image ...', fullfile(localSubDir,'bin','roisMask.nii.gz'));
            if(isnumeric(f)); error('User cancelled.'); end
            roisMaskFile = f;
        else
            roisMaskFile = 'none';
        end
    end

if (ieNotDefined('wmProbFile'))
    if bInteractive
        [f] = uiputfile('*.nii.gz', 'WM Probability image ...', fullfile(localSubDir,'bin','wmProb.nii.gz'));
        if(isnumeric(f)); error('User cancelled.'); end
        wmProbFile = f;
    else
        wmProbFile = 'wmProb.nii.gz';
    end
end


%% Handling of WM Mask
if ~bInteractive || queryOverwrite(fullfile(localSubDir,'bin',wmProbFile))
    disp('Creating wmProb file...');
    bm = niftiRead(fullfile(localSubDir,'bin','brainMask.nii.gz'));
    %bm = double(bm.data);
    %bm(bm>0)=1;
    b0 = niftiRead(fullfile(localSubDir,'bin','b0.nii.gz'));
    xformToAcpc = b0.qto_xyz;
    b0 = double(b0.data);
    dt6 = niftiRead(fullfile(localSubDir,'bin','tensors.nii.gz'));
    dt6 = double(squeeze(dt6.data(:,:,:,1,[1 3 6 2 4 5])));
    wmProb = dtiFindWhiteMatter(dt6,b0,xformToAcpc);
    %wmProb = wmProb .* bm;
    dtiWriteNiftiWrapper(wmProb,xformToAcpc,fullfile(localSubDir,'bin',wmProbFile))
    clear wmProb dt6 b0 xformToAcpc;
end

%% Handling of pdf file
pdfFile = fullfile(localSubDir,'bin','pdf.nii.gz');
if ~bInteractive || queryOverwrite(pdfFile);
    disp('Creating pdf file.');
    niTensors = niftiRead(fullfile(localSubDir,'bin','tensors.nii.gz'));
    imgTensors = double(squeeze(niTensors.data(:,:,:,1,[1 3 6 2 4 5])));
    niPDDD = niftiRead(fullfile(localSubDir,'bin','pddDispersion.nii.gz'));
    niBM = niftiRead(fullfile(localSubDir,'bin','brainMask.nii.gz'));
    [eigVec, eigVal] = dtiSplitTensor(imgTensors);
    [imgCl, imgCp, imgCs] = dtiComputeWestinShapes(eigVal);
    imgEVec1 = squeeze(eigVec(:,:,:,[1 2 3],1));
    imgEVec2 = squeeze(eigVec(:,:,:,[1 2 3],2));
    imgEVec3 = squeeze(eigVec(:,:,:,[1 2 3],3));
    
    imgPDF = zeros([size(imgTensors,1),size(imgTensors,2),size(imgTensors,3), 3*3+5]);
    imgPDF(:,:,:,1:3) = imgEVec3;
    imgPDF(:,:,:,4:6) = imgEVec2;
    imgPDF(:,:,:,7:9) = imgEVec1;
    % Convert dispersion to Watson concentration parameter
    % HACK to see if PDD is in degrees or radian format
    if(max(niPDDD.data(:))>2*pi)
        % Degrees
        imgPDDC = - 1 ./ sin(double(niPDDD.data).*pi./180).^2;
    else
        % Radians
        imgPDDC = - 1 ./ sin(double(niPDDD.data)).^2;        
    end
    imgPDDC(isinf(imgPDDC)) = min(imgPDDC(~isinf(imgPDDC)));
    imgPDF(:,:,:,10:11) = repmat(double(imgPDDC),[1,1,1,2]);
    imgPDF(:,:,:,12) = imgCl;
    imgPDF(:,:,:,13:14) = eigVal(:,:,:,2:3);
    
    % Write pdf file for scanner fit uncertainty estimates
    % Make pdf 0 where it is outside of brain mask, this is necessary for
    % ConTrac program
    imgPDF( repmat(double(niBM.data), [1 1 1 size(imgPDF,4)]) == 0 ) = 0;
    dtiWriteNiftiWrapper(imgPDF,niTensors.qto_xyz,pdfFile);
    
    clear niBM niTensors niPDDD;
    clear imgTensors imgEVec1 imgEVec2 imgEVec3 imgPDF eigVal eigVec imgCl imgCp imgCs;
end

if ~bOnlyPDF
    %% Initialization
    %dt6 = load(fullfile(localSubDir,dt6Dir,'dt6.mat'));
    % Get dimensions for mask image
    ni = niftiRead(fullfile(localSubDir,'bin','b0.nii.gz'));
    xformToAcpc = ni.qto_xyz;
    img_mask = zeros(size(ni.data));
    clear ni;
    
    if(0)
        if (exist(fullfile(localSubDir,'fibers','conTrack',inSamplerOptsFile),'file'))
            % Load parameters file
            mtr = mtrLoad(fullfile(localSubDir,'fibers','conTrack',inSamplerOptsFile),xformToAcpc);
        else
            % Create new parameters
            mtr = mtrCreate();
        end
    end
    mtr = mtrCreate();

    %% Create mask images from ROI files
    % ROI1
    roi = dtiReadRoi(fullfile(localSubDir,'ROIs',roi1File));
    mtr = mtrSet(mtr,'roi',roi.coords,1,'coords');
    roi.coords = mrAnatXformCoords(inv(xformToAcpc), roi.coords);
    for ii = 1:size(roi.coords,1)
        if (round(min(roi.coords(ii,:))) > 0 && all(round(roi.coords(ii,:))<=size(img_mask)))
            img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 1;
        end
    end

    % ROI2
    roi = dtiReadRoi(fullfile(localSubDir,'ROIs',roi2File));
    mtr = mtrSet(mtr,'roi',roi.coords,2,'coords');
    roi.coords = mrAnatXformCoords(inv(xformToAcpc), roi.coords);
    for ii = 1:size(roi.coords,1)
        if (round(min(roi.coords(ii,:))) > 0 && all(round(roi.coords(ii,:))<=size(img_mask)))
            img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 2;
        end
    end

    % ROI Waypoint
    if(0)
        if (~ieNotDefined('roiWayFile') && ~strcmpi(roiWayFile,'none'))
            roi = dtiReadRoi(fullfile(localSubDir,'ROIs',roiWayFile));
            roi.coords = mrAnatXformCoords(inv(xformToAcpc), roi.coords);
            for ii = 1:size(roi.coords,1)
                if (round(min(roi.coords(ii,:))) > 0 && all(round(roi.coords(ii,:))<=size(img_mask)))
                    img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 3;
                end
            end
        end
    end

    % Write binary mask of all ROIs
    dtiWriteNiftiWrapper(uint8(img_mask),xformToAcpc,fullfile(localSubDir,'bin',roisMaskFile));

    % Create pdf file from pddDispersion and tensors file
    
    if (0)
        % Write volume names to options file and save
        if bParallelScript
            exeConTracFile = '/radlab_share/home/tony/src/dtivis/DTIPrecomputeApp/dtiprecompute_met';
            disp(['Assuming ConTrac executable is located at ' exeConTracFile]);
            if (ieNotDefined('fgFile'))
                %outPathName = pwd;
                %[f,p] = uiputfile('*.pdb', 'Output file for the tracts ...', fullfile(localSubDir,'conTrack','paths.pdb'));
                [f] = uiputfile('*.pdb', 'Output file for the tracts ...', fullfile(localSubDir,'fibers','conTrack','paths.pdb'));
                if(isnumeric(f)); error('User cancelled.'); end
                fgFile = f;
            end
            [pathstr, pathsRoot, ext, versn] = fileparts(fgFile); %#ok<NASGU>
            % Update parameters file with ROI bounding box and mask image file
            mtr = mtrSet(mtr, 'tensors_filename', fullfile(remoteSubDir,dt6Dir,'bin','tensors.nii.gz'));
            mtr = mtrSet(mtr, 'fa_filename', fullfile(remoteSubDir,dt6Dir,'bin','wmMask.nii.gz'));
            mtr = mtrSet(mtr, 'pdf_filename', fullfile(remoteSubDir,dt6Dir,'bin','pdf.nii.gz'));
            mtr = mtrSet(mtr, 'mask_filename', fullfile(remoteSubDir,dt6Dir,'bin',roisMaskFile));
            mtrSave(mtr,fullfile(localSubDir,'fibers','conTrack',outSamplerOptsFile),xformToAcpc);
            % Write the script
            mtrCreateConTracParallelScript(machineList, remoteSubDir, exeConTracFile, fullfile(localSubDir,'conTrack',scriptFileName), outSamplerOptsFile, pathsRoot);
        else
            mtr = mtrSet(mtr, 'tensors_filename', fullfile(localSubDir,dt6Dir,'bin','tensors.nii.gz'));
            mtr = mtrSet(mtr, 'fa_filename', fullfile(localSubDir,dt6Dir,'bin',wmProbFile));
            mtr = mtrSet(mtr, 'pdf_filename', fullfile(localSubDir,dt6Dir,'bin','pdf.nii.gz'));
            mtr = mtrSet(mtr, 'mask_filename', fullfile(localSubDir,dt6Dir,'bin',roisMaskFile));
            mtr = mtrSet(mtr, 'xmask_filename', fullfile(localSubDir,dt6Dir,'bin',xMaskFile));
            if(ieNotDefined('roiWayFile') || strcmpi(roiWayFile,'none'))
                mtr = mtrSet(mtr, 'require_way', 'false');
            else
                mtr = mtrSet(mtr, 'require_way', 'true');
            end
            mtrSave(mtr,fullfile(localSubDir,'fibers','conTrack',outSamplerOptsFile),xformToAcpc);
        end
    end
end % ~bOnlyPDF

return;

%% Query the overwriting of a file
function val = queryOverwrite(fileName)
val = 1;
if ~isempty(dir(fileName))
    [pathstr, strippedFileName, ext, versn] = fileparts(fileName);
    msg = sprintf('Do you want to overwrite %s ? Y/N [N]: ', [strippedFileName ext]);
    reply = input(msg, 's');
    if isempty(reply) || reply == 'n' || reply == 'N'
        val = 0;
    end
end
return;
