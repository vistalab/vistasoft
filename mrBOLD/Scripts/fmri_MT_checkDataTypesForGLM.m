function [go,s1]=fmri_MT_checkDataTypesForGLM(fid,dataTYPES)
% Usage: checkDataTypesForGLM(fid)
%
% Fid = file id for error log text file
%
% Function for use in GLM batch script context. 
% 1. Find 'MotionComp_RefScan1' dataTYPE #
% 2. Find 'MT' scan # for MC dataTYPE
%
% If conditions not met (e.g., EXACT STRING MATCHES for 1,2), will report
% error and return, skipping that subject, and set GO flag to 0. 
%
% DY & AL 2008/ (based on fmri_FFA_checkDataTypesForGLM on 06/08/2008)

if notDefined('fid')    fid=1;   end
go=1; % flag that is set to 0 if any errors in datatype fields
s1=struct;

% Names for particular dataTYPES / scans
mcName = 'MotionComp_RefScan1';
mtExpName = 'mt';

% Only set the mc_dt variable if there is one MC dataTYPE, else log the
% person and find some way to deal with it (for now, we RETURN)
% NOTE: Golijeh usually runs the LO localizer scan first, so these
% scans should always use the MotionComp_RefScan1 dataTYPE.
mcs = zeros(1,length(dataTYPES));
mcs=strcmp({dataTYPES.name},mcName);
if sum(mcs)==1
    mc_dt=find(mcs==1);
    fprintf(fid,'Found %s for dataTYPES %d\n',mcName, mc_dt);
    fprintf('Found %s for dataTYPES %d\n',mcName, mc_dt);
else
    fprintf(fid,'Error: Found %d %s dataTYPES, skipping... \n\n',sum(mcs),mcName);
    fprintf('Error: Found %d %s dataTYPES, skipping... \n\n',sum(mcs),mcName);
    go=0;
    return
end


% Find scans with "mt" in the annotation field
mtScans=zeros(1,length(dataTYPES(mc_dt).scanParams));
for xx=1:length(mtScans)
    tmp=strfind(lower(dataTYPES(mc_dt).scanParams(xx).annotation), mtExpName);
    if ~isempty(tmp)
        mtScans(xx)=1;
    end
end
if sum(mtScans)==1
    mt_scan=find(mtScans==1);
    mtName=dataTYPES(mc_dt).scanParams(mt_scan).annotation;
    fprintf(fid,'Found %s for dataTYPES %d scan %d \n',mtName, mc_dt, mt_scan);
    fprintf('Found %s for dataTYPES %d scan %d\n',mtName, mc_dt, mt_scan);
else
    fprintf(fid,'Error: Found %d %s scans, skipping... \n\n',sum(mtScans),mtName);
    fprintf('Error: Found %d %s scans, skipping... \n\n',sum(mtScans),mtExpName);
    go=0;
    return
end

% Find parfile and scangroup assignments for those scans
% First check if these fields exist. If they do not, print the relevant
% error to file and exit, setting go=0. 

if (~isfield(dataTYPES(mc_dt).scanParams(mt_scan),'parfile')) | ...
        (~isfield(dataTYPES(mc_dt).scanParams(mt_scan),'scanGroup'))
    fprintf(fid,'Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    fprintf('Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    go=0;
    return
end

% Find parfile and scangroup assignments for those scans
parfile=dataTYPES(mc_dt).scanParams(mt_scan).parfile;
fprintf(fid,'Parfile for %s: %s \n',mtName, parfile);
fprintf('Parfile for %s: %s \n',mtName, parfile);

s1.mc=mc_dt;
s1.scan=mt_scan;
s1.parfile=parfile;
s1.scangroup=mt_scan;


return