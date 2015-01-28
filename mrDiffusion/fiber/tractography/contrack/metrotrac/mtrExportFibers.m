function mtrExportFibers(fg, fileName, xformToAcPc, xform, fiberToStrFlag, version)
% Exports fiber group to .pdb format file  
%
%  mtrExportFibers(fg, fileName, [xformToAcPc], [xform=eye()],[fiberToStrFlag=true],[version=3])
% 
% Writes a mrDiffusion fiber group structure to a pdb file.  You should
% always write to a version 3 file (the default) unless you know what you
% are doing and really need a version 2 file.
%
% If your fibers are already in AcPc space then you probably want to store
% them that way in the file as it makes everything else easier.  In that
% case don't set xformToAcPc and xform.  They will default to identity and
% leave your fibers in the AcPc space.
% 
% fg:             Fiber group to save into PDB file
% fileName:       Filename for PDB file
% xformToAcPc:    Transform current fiber coordinates into AcPc space
% xform:          Transforms current fiber coordinates into the space we would like
%                 to store on file
% fiberToStrFlag: set to zero if want to use legacy code for saving pdb
%                 file
% version:        PDB 3 (default) or 2 (not desired)
%
% Examples: (See Debug configuration for testing)
%   fgName = fullfile(mrvDataRootPath,'quench','fibers','LeftArcuate_ver3.pdb');
%   fg = mtrImportFibers(fgName);
%   v = 3; mtrExportFibers(fg, 'deleteMe.pdb', [], [], [], v);
%
% Stanford VISTA Team

if ~exist('fiberToStrFlag', 'var')|| isempty(fiberToStrFlag) || fiberToStrFlag~=0
    fiberToStrFlag=true; %By defaultconvert the Matlab fiber data structure into one big contiguous array.  
end

if ~exist('fileName','var') || isempty(fileName)
    fileName = mrvSelectFile('w', 'pdb', 'Write pdb fibers');
end

% Make sure extension is pdb
[p,n] = fileparts(fileName);
fileName = [fullfile(p,n),'.pdb'];

if ~exist('version', 'var')|| isempty(version), version = 3; end
    
if version ~= 2 && version ~= 3
	error('PDB version should be 2 or 3');
end

if(~exist('xformToAcPc','var') || isempty(xformToAcPc))
    xformToAcPc = eye(4);
end

% comment and explain, please
if(exist('xform','var') && ~isempty(xform) && (isstruct(xform) || ~all(all(xform==eye(4)))))
    fg = dtiXformFiberCoords(fg, xform);
    % xformToAcPc = xformToAcPc*inv(xform);
    xformToAcPc = xformToAcPc/xform;
end

% Create blank database for finding some of the sizes to write out
pdb = mtrPathwayDatabase();
% PDB structure will have stat header info, but fg will retain the actual
% statistics per path to record

%fg.params = {};
% This routine (see below) is empty.  If we want to check something, then
% let's figure out what and then check it. For now, I am commenting it out.
% [pdb,fg] = enforceRightStats(pdb,fg);  
numstats = length( pdb.pathway_statistic_headers );
numalgs = 0;

% Set offset and open the file.
% Tragically the getAlgorithms... function is a single number that doesn't
% depend on the input argument.
%
offset = 4*4 + 16*8 + numstats * getStatisticsHeaderSize(pdb) + ...
    numalgs * getAlgorithmsHeaderSize(pdb); % 4 uint, 16 doubles
fid = fopen(fileName, 'wb');

% Writing header
fwrite(fid,offset,'uint');  % An integer that points to something ...
xformToAcPc = xformToAcPc';
fwrite(fid,xformToAcPc(:),'double');  % The xform
fwrite(fid,numstats,'uint');          % The number of statistics saved with the fibers

% Write statistics to the PDB header
saveStatisticsHeader(pdb,fid);

fwrite(fid,numalgs,'uint');  % Well, this is weird.  I guess numalgs is always zero.
% Write algorithm header
% saveAlgorithmHeader(pdb,fid);

fwrite(fid,version,'uint');

% Writing path info
numpaths = length(fg.fibers);
fwrite(fid,numpaths,'uint');
fileOffsets = zeros(1,numpaths);
for ff = 1:numpaths
    % Record current file position to write later
    fileOffsets(ff) = ftell(fid);
    
    path_offset = 3 * 4  + numstats*8; % 4 int, numstats double
    fwrite(fid,path_offset,'int');    
    nn = size( fg.fibers{ff}, 2 );    
    fwrite(fid,nn,'int');
    fwrite(fid,0,'int'); % algo type HACK
    fwrite(fid,1,'int'); % seedpointindex HACK ???
    
    % Write stats per path
    for as = 1:numstats
        fwrite(fid,fg.params{as}.stat(ff),'double');
    end 
    
    % Writing path nodes
    %pos = fg.fibers{ff}.coords;
    pos = fg.fibers{ff};
    %pos = mrAnatXformCoords(xformFromAcpc, pos')';
    % Change from 1 based to 0 based positions in mm space
    %pos = pos - repmat([2,2,2]',1,size(pos,2));
    fwrite(fid,pos,'double');
    
    % Writing stats values per position
    for as = 1:numstats
        % Just write garbage as fiber groups can't handle per point stats
        if( pdb.pathway_statistic_headers(as).is_computed_per_point )
            error('Cannot export fiber group with per point statistics!');
            %fwrite(fid,this.pathways(p).point_stat_array(as,:),'double');
        end
    end   
end

% Database Footer
fwrite(fid,fileOffsets,'uint64');
fclose(fid);

% Convert to string depending on the version.
if fiberToStrFlag
	if version == 2, str=fiberToStr(fg); end
	if version == 3, str=fiberToStr3(fg);end
    myf = fopen(fileName,'wb');fwrite(myf,str,'uint8');fclose(myf);%fclose(fid);return;
end
return;

%-----
function [pdb,fg] = enforceRightStats(pdb,fg)
%if ~isempty(fg.params) && ~ieNotDefined('fg.params{1}.name') && strcmpi(fg.params{1}.name,'weight') 
% The above check is wrong because ieNotDefined cant work this way. This
% wrong check ends up destroying the params. Nor do I understand why this
% function always ends up overwriting the fibers. 
return;

if ~isempty(fg.params) && isfield(fg.params{1},'name') && ~isempty(fg.params{1}.name)
    tempFGParams = fg.params(1);
    fg.params = {};
    fg.params{1}.name = 'Length';
    for ff=1:length(fg.fibers)
        fiber = fg.fibers{ff};
        if(size(fiber,2)<size(fiber,1)); fiber=fiber'; end
        mmPerStep = sqrt(sum((fiber(:,1)-fiber(:,2)).^2));
        fg.params{1}.stat(ff) = mmPerStep*(size(fiber,2)-1);
    end
    s=length(pdb.pathway_statistic_headers)+1;
    pdb = addStatisticHeader(pdb,fg.params{1}.name,'NA', 1, 0, 1, 8877+s);
    fg.params(2) = tempFGParams;
    s=length(pdb.pathway_statistic_headers)+1;
    pdb = addStatisticHeader(pdb,fg.params{2}.name,'NA', 1, 0, 1, 8877+s);
    for ii=3:3
        pdb = addBlankStat(pdb,'Blank');
        fg.params{ii}.name = 'Blank';
        fg.params{ii}.stat = zeros(1,length(fg.fibers));
    end
else
    fg.params = {};
    fg.params{1}.name = 'Length';
    for ff=1:length(fg.fibers)
        fiber = fg.fibers{ff};
        if(size(fiber,2)<size(fiber,1)); fiber=fiber'; end
        mmPerStep = sqrt(sum((fiber(:,1)-fiber(:,2)).^2));
        fg.params{1}.stat(ff) = mmPerStep*(size(fiber,2)-1);
    end
    for ii=2:3
        pdb = addBlankStat(pdb,'Blank');
        fg.params{ii}.name = 'Blank';
        fg.params{ii}.stat = zeros(1,length(fg.fibers));
        %     if numstats>=ii
        %         pdb = addBlankStat(pdb,fg.params{ii}.name);
        %     else
        %         pdb = addBlankStat(pdb,'Blank');
        %         fg.params{ii}.stat = zeros(1,length(fg.fibers));
        %     end
    end
end
return;

%-----
function pdb = addBlankStat(pdb,agg_name)
s=length(pdb.pathway_statistic_headers)+1;
pdb = addStatisticHeader(pdb,agg_name,'NA', 1, 0, 1, 8877+s);
return;