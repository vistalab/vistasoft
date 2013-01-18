function [go,s2]=fmri_loc2_checkDataTypesForGLM(fid,dataTYPES)
% Usage: checkDataTypesForGLM(fid)
%
% Fid = file id for error log text file
%
% Function for use in GLM batch script context. 
% 1. Find 'MotionComp_RefScan1' dataTYPE #
% 2. Find 'loloc_run1' scan # for MC dataTYPE
% 3. Find 'loloc_run2' scan # for MC dataTYPE
% 4. Check that scan group for both scans = [lo_run1# lo_run2#] that the
% user previously set in the mrVista GUI is composed on the scan numbers
% that we expect there to be. Critically, this depends on the user having
% set the scan groups in the first place!
%
% If conditions not met (e.g., EXACT STRING MATCHES for 1,2,3), will report
% error and return, skipping that subject, and set GO flag to 0. 
%
% DY 06/08/2008

if notDefined('fid')    fid=1;   end
go=1; % flag that is set to 0 if any errors in datatype fields
s2=struct; 

% Names for particular dataTYPES / scans
mcName = 'MotionComp_RefScan1';
lo2Name = 'loloc_run2';

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

% Find scans with "loloc_run2" in the annotation field
lo2scans=zeros(1,length(dataTYPES(mc_dt).scanParams));
lo2scans=strcmp({dataTYPES(mc_dt).scanParams.annotation},lo2Name);
if sum(lo2scans)==1
    lo_scan2=find(lo2scans==1);
    fprintf(fid,'Found %s for dataTYPES %d scan %d \n',lo2Name, mc_dt, lo_scan2);
    fprintf('Found %s for dataTYPES %d scan %d\n',lo2Name, mc_dt, lo_scan2);
else
    fprintf(fid,'Error: Found %d %s scans, skipping... \n\n',sum(lo2scans),lo2Name);
    fprintf('Error: Found %d %s scans, skipping... \n\n',sum(lo2scans),lo2Name);
    go=0;
    return
end

% Find parfile and scangroup assignments for those scans
% First check if these fields exist. If they do not, print the relevant
% error to file and exit, setting go=0. 

if   (~isfield(dataTYPES(mc_dt).scanParams(lo_scan2),'parfile')) | ...
        (~isfield(dataTYPES(mc_dt).scanParams(lo_scan2),'scanGroup'))
    fprintf(fid,'Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    fprintf('Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    go=0;
    return
end

parfile2=dataTYPES(mc_dt).scanParams(lo_scan2).parfile;
scangroup2=dataTYPES(mc_dt).scanParams(lo_scan2).scanGroup;
fprintf(fid,'Parfile for %s: %s \n',lo2Name, parfile2);
fprintf('Parfile for %s: %s \n',lo2Name, parfile2);
fprintf(fid,'ScanGroup for %s: %s \n',lo2Name, scangroup2);
fprintf('ScanGroup for %s: %s \n',lo2Name, scangroup2);


% Set s1 and s2 struct fields (when have time, rewrite code so this is not
% necessary
s2.mc=mc_dt;
s2.scan=lo_scan2;
s2.parfile=parfile2;
s2.scangroup=scangroup2;

return