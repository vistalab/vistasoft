function rmSpawn(view,execute,whichmodel)
% rmSpawn - run analysis in a separate (background) matlab session
%
% rmSpawn(view,execute);
%
% Inputs:
%  view:    mrVista view structure
%  execute: actually execute [default = 1 (true)]
%           0 (false) will just print the command. This is useful
%           if you want to create a script analysing several
%           sessions.
%
% Basically a wrapper for rmMain (the shell script) and will thus
% only work on unix/linux/macosx.
%
%
% Potentially dangerous function because it makes it easy for the
% user to start loads of matlab-processes. This may slow all
% processes down and hog matlab-licences. These matlab processes
% can only be killed using 'kill -9 pid' where pid can be found
% using ps (e.g. ps -elf | grep matlab) or top.
%
% 2006/07 SOD: wrote it. 

if ~isunix, 
    errordlg('Run in background only works for Unix'); 
    return; 
end

if ieNotDefined('view'); error('Need view struct'); end;
if ieNotDefined('execute'), execute = true; end;
if ieNotDefined('whichmodel'), whichmodel = 1; end;

% find rmMain path
spawnvar.function = fullfile(fileparts(which('rmMain')),'rmMain');

% Warning: for random clickers
bn = questdlg(sprintf(['WARNING: This will start a separate matlab session in the background.\n\nThis new background matlab session will not die if you quit this current matlab session nor if you log out of this machine. This new background matlab session will only quit once the fitting is done (or if you explicitly kill it - kill "pid"). \n\nAre you sure that you wish to continue?']),...
              'Are you sure?','Yes','No','Yes but do not execute','No');
switch lower(bn),
 case 'no',
  return;
 case 'yes but do not execute',
  % don't actually quit but set execute to zero
  execute = false;
 otherwise,
  % continue
end;
 
% make view pointers for rmMain
switch lower(view.viewType),
 case 'inplane',
  spawnvar.view(1) = 0;
 case 'gray',
  spawnvar.view(1) = 1;
 otherwise,
  disp(sprintf('[%s]:ERROR:viewtype (%s) not incorporated yet.',...
               mfilename,view.viewType));
end;

% datatype
spawnvar.view(2) = viewGet(view,'curdatatype');

% store roi file name
if view.selectedROI>0,
  spawnvar.roifilename = view.ROIs(view.selectedROI).name;
else,
  spawnvar.roifilename = '0';
end;

% dataset path
spawnvar.path     = pwd;

if whichmodel == 1
  % only 1 gaussian model
  % now we are ready to call rmMain (shell script)
  functioncall = sprintf('%s ''[%d %d]'' ''[]'' %s %s &',...
                         spawnvar.function,...
                         spawnvar.view(1),spawnvar.view(2),...
                         spawnvar.roifilename,...
                         spawnvar.path);
else,
  % both models
  functioncall = sprintf('%s ''[%d %d]'' ''[2 4 6 8]'' %s %s &',...
                         spawnvar.function,...
                         spawnvar.view(1),spawnvar.view(2),...
                         spawnvar.roifilename,...
                         spawnvar.path);
end;

  
disp(functioncall);
if execute,
  [s w]=system(functioncall);
  if s==0,
    disp(sprintf(['[%s]:Succesfully spawned matlab process.'], ...
                 mfilename));
  else,
    disp(sprintf('[%s]:Failed: %s',mfilename,w));
  end;
else,
  disp(sprintf('[%s]:Not executed.',mfilename));
end;

% done
return;
