function [go,s1]=fmri_loc1_checkDataTypesForGLM(fid,dataTYPES)
% Usage: checkDataTypesForGLM(fid)
%
% Fid = file id for error log text file
%
% Function for use in GLM batch script context. 
% 1. Find 'MotionComp_RefScan1' dataTYPE #
% 2. Find 'loloc_run1' scan # for MC dataTYPE
%
% If conditions not met (e.g., EXACT STRING MATCHES for 1,2,3), will report
% error and return, skipping that subject, and set GO flag to 0. 
%
% DY 06/08/2008
% AL 11/08 Modified for loc1 GLM

if notDefined('fid')    fid=1;   end
go=1; % flag that is set to 0 if any errors in datatype fields
s1=struct; 

% Names for particular dataTYPES / scans
mcName = 'MotionComp_RefScan1';
lo1Name = 'loloc_run1';


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

% Find scans with "loloc_run#" in the annotation field
lo1scans=zeros(1,length(dataTYPES(mc_dt).scanParams));
lo1scans=strcmp({dataTYPES(mc_dt).scanParams.annotation},lo1Name);
if sum(lo1scans)==1
    lo_scan1=find(lo1scans==1);
    fprintf(fid,'Found %s for dataTYPES %d scan %d \n',lo1Name, mc_dt, lo_scan1);
    fprintf('Found %s for dataTYPES %d scan %d\n',lo1Name, mc_dt, lo_scan1);
else
    fprintf(fid,'Error: Found %d %s scans, skipping... \n\n',sum(lo1scans),lo1Name);
    fprintf('Error: Found %d %s scans, skipping... \n\n',sum(lo1scans),lo1Name);
    go=0;
    return
end


% Find parfile and scangroup assignments for those scans
% First check if these fields exist. If they do not, print the relevant
% error to file and exit, setting go=0. 

if (~isfield(dataTYPES(mc_dt).scanParams(lo_scan1),'parfile')) | ...
        (~isfield(dataTYPES(mc_dt).scanParams(lo_scan1),'scanGroup')) 
    fprintf(fid,'Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    fprintf('Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    go=0;
    return
end

parfile1=dataTYPES(mc_dt).scanParams(lo_scan1).parfile;
scangroup1=dataTYPES(mc_dt).scanParams(lo_scan1).scanGroup;
fprintf(fid,'Parfile for %s: %s \n',lo1Name, parfile1);
fprintf('Parfile for %s: %s \n',lo1Name, parfile1);
fprintf(fid,'ScanGroup for %s: %s \n',lo1Name, scangroup1);
fprintf('ScanGroup for %s: %s \n',lo1Name, scangroup1);



% Set s1 struct fields 
s1.mc=mc_dt;
s1.scan=lo_scan1;
s1.parfile=parfile1;
s1.scangroup=scangroup1;

return