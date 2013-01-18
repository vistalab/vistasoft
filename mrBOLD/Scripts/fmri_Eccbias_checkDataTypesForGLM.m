function [go,s1,s2]=fmri_Eccbias_checkDataTypesForGLM(fid,dataTYPES)
% Usage: checkDataTypesForGLM(fid)
%
% Fid = file id for error log text file
%
% Function for use in GLM batch script context. 
% 1. Find 'MotionComp_RefScan1' dataTYPE #
% 2. Find 'EccBias_run1' scan # for MC dataTYPE
% 3. Find 'EccBias_run2' scan # for MC dataTYPE
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
s1=struct; s2=struct;

% Names for particular dataTYPES / scans
mcName='MotionComp_RefScan1';
eccName='bias';

% Only set the mc_dt variable if there is one MC dataTYPE, else log the
% person and find some way to deal with it (for now, we RETURN)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find scans with "bias" in the annotation field

eccScans=zeros(1, length(dataTYPES(mc_dt).scanParams));
for ii=1:length(eccScans)
    tmp=strfind(lower(dataTYPES(mc_dt).scanParams(ii).annotation), eccName);
    if ~isempty(tmp)
        eccScans(ii)=1;
    end
end

if sum(eccScans)==2
    ecc_scan=find(eccScans==1);
    ecc_scan1=ecc_scan(1);
    ecc_scan2=ecc_scan(2);
    ecc1Name=dataTYPES(mc_dt).scanParams(ecc_scan1).annotation;
    ecc2Name=dataTYPES(mc_dt).scanParams(ecc_scan2).annotation;
    fprintf(fid,'Found %s for dataTYPES %d scan %d \n',ecc1Name, mc_dt,ecc_scan1);
    fprintf('Found %s for dataTYPES %d scan %d\n',ecc1Name, mc_dt,ecc_scan1);
    fprintf(fid,'Found %s for dataTYPES %d scan %d \n',ecc2Name, mc_dt, ecc_scan2);
    fprintf('Found %s for dataTYPES %d scan %d\n',ecc2Name, mc_dt, ecc_scan2);
else
    fprintf(fid,'Error: Found %d EccBias scans, skipping... \n\n',sum(eccScans));
    fprintf('Error: Found %d EccBias scans, skipping... \n\n',sum(eccScans));
    go=0;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find parfile and scangroup assignments for those scans
% First check if these fields exist. If they do not, print the relevant
% error to file and exit, setting go=0. 

if (~isfield(dataTYPES(mc_dt).scanParams(ecc_scan1),'parfile')) | ...
        (~isfield(dataTYPES(mc_dt).scanParams(ecc_scan2),'parfile')) | ...
        (~isfield(dataTYPES(mc_dt).scanParams(ecc_scan1),'scanGroup')) | ...
        (~isfield(dataTYPES(mc_dt).scanParams(ecc_scan2),'scanGroup'))
    fprintf(fid,'Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    fprintf('Error: Parfile and/or scanGroup fields do not exist for dataTYPES %d... \n\n',mc_dt);
    go=0;
    return
end

parfile1=dataTYPES(mc_dt).scanParams(ecc_scan1).parfile;
parfile2=dataTYPES(mc_dt).scanParams(ecc_scan2).parfile;
scangroup1=dataTYPES(mc_dt).scanParams(ecc_scan1).scanGroup;
scangroup2=dataTYPES(mc_dt).scanParams(ecc_scan2).scanGroup;
fprintf(fid,'Parfile for %s: %s \n',ecc1Name, parfile1);
fprintf('Parfile for %s: %s \n',ecc1Name, parfile1);
fprintf(fid,'ScanGroup for %s: %s \n',ecc1Name, scangroup1);
fprintf('ScanGroup for %s: %s \n',ecc1Name, scangroup1);
fprintf(fid,'Parfile for %s: %s \n',ecc2Name, parfile2);
fprintf('Parfile for %s: %s \n',ecc2Name, parfile2);
fprintf(fid,'ScanGroup for %s: %s \n',ecc2Name, scangroup2);
fprintf('ScanGroup for %s: %s \n',ecc2Name, scangroup2);

% Check that scan group for both Eccbias runs is composed of the scan
% numbers for the run1 and run 2 scans. I use part of er_getScanGroup for
% this check. 
checkThese = [ecc_scan1 ecc_scan2]; scans = [];
for jj=1:length(checkThese)
    txt=dataTYPES(mc_dt).scanParams(ecc_scan1).scanGroup;
    colon = findstr(':',txt);
    dtName = txt(1:colon-1);
    theScans = str2num(txt(colon+2:end));
    scans = [scans theScans];
end

if(scans==[checkThese checkThese])
    fprintf(fid,'Checked scan group assignments: PASS \n');
    fprintf('Checked scan group assignments: PASS \n');
else
    fprintf(fid,'Error: Scan Group Run 1 = [%d %d], Scan Group Run 2 = [%d %d] skipping... \n\n',...
        scans(1),scans(2),scans(3),scans(4));
    fprintf('Error: Scan Group Run 1 = [%d %d], Scan Group Run 2 = [%d %d] skipping... \n\n',...
        scans(1),scans(2),scans(3),scans(4));
    go=0;
end

% Set s1 and s2 struct fields (when have time, rewrite code so this is not
% necessary
[s1.mc,s2.mc]=deal(mc_dt);
s1.scan=ecc_scan1;
s2.scan=ecc_scan2;
s1.parfile=parfile1;
s2.parfile=parfile2;
[s1.scangroup,s2.scangroup]=deal(checkThese);

return