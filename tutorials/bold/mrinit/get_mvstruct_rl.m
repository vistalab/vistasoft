function [h mv]= get_mvstruct_rl(dt,scan,roi, v,cmprss)

% function [h mv]=get_mvstruct(dt,scan,roi,v,cmprss)
% initializes an roi and runs the glm on each voxel
% arguments are
%  dataType
%  scans
%  name of an roi
%  roifolder: absolute path where rois are stored
%  view  should be 'gray' or 'inplane'
% cmprss 0 to keep timeseries and voxData, 1 to remove them
% assumes you are in the correct subject directory
% edited version of get_mvstruct in 

if notDefined('cmprss') cmprss=0; end


%get rid of any extraneous variables
clear dataTYPES mrSESSION vANATOMYPATH



% if the roi doesn't exist then quit
if ~exist(roi)
    display([roi 'does not exist. skipping subject ' pwd]);
    %return failure to find roi
    h = 0;
    mv=0;
    %if it does get the data
else
    % initalize the view
    if strcmp(v,'inplane')
        h = initHiddenInplane(dt, scan, roi);
    else
        h = initHiddenGray(dt, scan,roi);
    end

    disp('in get mvstruct dt is');
    dt
    %set params for glm just to be sure
    % enforce consistent preprocessing / event-related parameters
    % want to add params as an argument
    params = er_getParams(h,scan(1),dt);
    params.glmHRF = 3; % flag for spm HIRF
    params.ampType = 'betas';
    er_setParams(h, params,scan(1),dt);


    display('initializing mv');
    % get data from the voxels
    mv = mv_init(h, roi, scan, dt, 0);
    display('applying glm to voxels');
    % apply the glm to the voxels
    mv = mv_applyGlm(mv);

    % get the amplitudes
    % will probably want to put this elsehwere so that we can specify which
    % amplitudes
    display('getting mv amps');
    mv.amps = mv_amps(mv);

    %  add some fields to help keep track of the anatomy indices
    [mv.roiInd, mv.coords] = roiIndices(h, mv.roi.coords, 1);

    
    %should add a flag in case we want to strip the tSeries and voxData which makes
    %the files very large and is maybe not necessary to keep
    if cmprss == 1
        display('stripping tSeries and voxData fields');
        rmfield(mv,'tSeries');
        rmfield(mv,'voxData');
    end
end


end