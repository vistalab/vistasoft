function [fg,filename] = mtrImportFibers(filename,xform,bEndOnly, coordspace)
%
% [fg,filename] = mtrImportFibers(filename, [xform], [bEndOnly], [coordspace])
%
% Imports non-mrDiffusion fiber/path file formats. Currently supports:
%
% 1. PDB (pathway data base)
% 2. Bfloat (ConTrack/Camino)
% 3. tck (MRtrix)
%
% Parameters
% ----------
% filename: Full path to the file containing the fiber group. Currently
% supports:
%   1. PDB (pathway data base)
%   2. Bfloat (ConTrack/Camino)
%   3. MRtrix (MRtrix fibers)
% xform: A transformation matrix to apply to the coordinates of all the
% fibers in the fiber group, optional. 
% bEndOnly: For Bfloat files, whether to read in only the end points,
% optional, default to read the full fibers.  
% coordspace: string {'acpc' | 'img' | ...}, the coordinate space in which
% the fiber coordinates are defined. optional. Defaults to an empty matrix
% 
% 2011.07.21 - LMP changed the call for Bfloat file types to
% dtiLoadBfloatPaths
%
% 2009 Stanford, Vista

if notDefined('bEndOnly'), bEndOnly = 0; end
if notDefined('xform'),    xform = eye(4); end

%persistent defaultPath;
defaultPath = pwd;

if (~exist('filename','var') || isempty(filename))
    if(isempty(defaultPath)), filename = pwd;
    else                      filename = defaultPath;
    end
end

if (~exist('xform','var') || isempty(xform)), xform = eye(4); end

% Read the file name from the user
if(isdir(filename)) || ~exist(filename,'file')
    if(~isempty(defaultPath)), filename = defaultPath; end
    [f,p] = uigetfile({'*.pdb','ConTrack PDB *.pdb';'*.Bfloat','ConTrack/Camino *.Bfloat';'*.*','all files'},'Select fiber file...',filename);
    if(isnumeric(f)), disp('Cancel.'); return; end
    % defaultPath = p;
    filename = fullfile(p,f);
end

%
[p,f,e] = fileparts(filename); %#ok<ASGLU>
if(isempty(e)), e = '.pdb'; end

fg = [];
switch(e)
    case '.pdb',
        %disp('Trying to import PDB paths...');
        
        % Read the whole file into a string, str.  The str is decoded in
        % the function below.
        fid = fopen(filename, 'r');
        str = fread(fid, inf,'uint8');
        fclose(fid);
        
        % MetroTrack is the old name.  It reads the pdb file.
        mt = dtiLoadMetrotracPathsFromStr(str,xform);
        
        % Copy the loaded data in the mrDiffusion format
        if ~isempty(mt)
            fg = dtiNewFiberGroup;
            fg.fibers = mt.pathways;
            fg.name = f;
            fg.colorRgb = [200 200 100];
            fg.pathwayInfo = mt.pathwayInfo;
            for ss = 1:length(mt.statHeader)
                statstruct.name = mt.statHeader(ss).agg_name;
                statstruct.uid=mt.statHeader(ss).uid;
                statstruct.ile=mt.statHeader(ss).is_luminance_encoding;
                statstruct.icpp=mt.statHeader(ss).is_computed_per_point;
                statstruct.ivs=mt.statHeader(ss).is_viewable_stat;
                statstruct.agg=mt.statHeader(ss).agg_name;
                statstruct.lname=mt.statHeader(ss).local_name;
                for pp = 1:length(mt.pathwayInfo)
                    statstruct.stat(pp) = mt.pathwayInfo(pp).pathStat(ss);
                end
                fg.params{ss} =  statstruct;
            end
        end
        
    case '.Bfloat',
        mt = dtiLoadBfloatPaths(filename,xform,bEndOnly);
        if ~isempty(mt)
            fg = fgCreate;
            fg.fibers = mt.pathways;
            fg.name = f;
            fg.colorRgb = [200 200 100];
            for ss = 1:length(mt.statHeader)
                statstruct.name = mt.statHeader(ss).agg_name;
                for pp = 1:length(mt.pathwayInfo)
                    statstruct.stat(pp) = mt.pathwayInfo(pp).pathStat(ss);
                end
                fg.params{ss} =  statstruct;
            end
        end
        
    case '.tck'
        fg = dtiImportFibersMrtrix(filename);
        
    otherwise,
        error('unknown format: %s\n',e);
end

% These are always going to be in acpc space, so there we go: 
if ~notDefined('coordspace')
    fgSet(fg, 'coordspace', coordspace);
else
    fgSet(fg, 'coordspace', []);
end

fprintf('Fibers loaded from file %s\n',f);

return;
