function fg = dtiLoadFiberGroup(fgFileName)
% Loads a single fiber group from a file
%
%    fg = dtiLoadFiberGroup(fgFileName)
%
% This is the preferred routine for loading fibers in a script.
%
% It can handle .mat (vista), .pdb (vista), .Bfloat (camino) fibers' files.
%
% Example:
%   fgname = fullfile(mrvDataRootPath,'diffusion','sampleData','fibers','leftArcuate.pdb')
%   fg = dtiLoadFiberGroup(fgname);
%
% See Also: dtiReadFibers
%
% (c) 2012 Stanford VISTA team.

% OLD help:
%
% dtiLoadFiberGroup differs from dtiReadFibers: When there are N subgroups
% of fibers, dtiLoadFiberGroup does NOT create N fibergroups. That
% functionality is used by dtiReadFibers to help interactions with the GUI.
% This function is written in a mode that works better with scripts.
%
% Fiber group files sometimes contain the complete data set, and sometimes
% they contain a reference to the parent file and the indices in that file
% of some fibers. This routine handles both cases.
%
% It is necessary for the parent file be in the same directory as the
% fgFileName.

[FgLocation, FgFile, ext] = fileparts(fgFileName);

% Depending on the type of file we use different lines of code.
switch ext
  case {'.mat'}
    load(fgFileName);
    if exist('fg', 'var')
      return
    elseif exist('fghandle','var')
      [ParentLocation, ParentFile, ParentExt]=fileparts(fghandle.parent);
      if ~isempty(ParentLocation)
        warning('Parent filename should not contain path');
      end
      fg=dtiLoadFiberGroup(fullfile(FgLocation, [ParentFile ParentExt]));
      fg.name=fghandle.name;
      fg.fibers=fg.fibers(fghandle.ids);
      if ~isempty(fg.seeds)
        fg.seeds=fg.seeds(fghandle.ids);
      end
      if isfield(fghandle, 'subgroup')
        fg.subgroup=fghandle.subgroup;
        fg.subgroupNames=fghandle.subgroupNames;
      elseif isfield(fg, 'subgroup')&&~isempty(fg.subgroup)
        fg.subgroup=fg.subgroup(fghandle.ids);
      end
    else
      error('No fghandle or fg in the fgFileName');
      
    end
    
  case {'.pdb','.Bfloat'}
    fg = mtrImportFibers(fgFileName);
    
  otherwise
    keyboard
end

return