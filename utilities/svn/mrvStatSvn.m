function svnHtmlIndex = mrvStatSvn(svnRootPath,outDir,statExe)
% svnIndexPath = svnStatsHtml([svnRootPath],[outDir],[statExe]);
% 
%  This function uses the StatSVN package to create HTML reports from SVN
%  log files, which can then be loaded into your browser for easy viewing.
%  This function will attempt to create and launch the files for you in
%  your browser. It returns the full path to the html index file that you
%  can load in your browser. This funciton will create a svn log file
%  (using svn log -v --xml) one level above svnRootPath. This function can
%  take a few minutes to run. 
% 
%  ** Users should update their SVN repo prior to running this function. 
% 
%  INPUTS:
%    svnRootPath - This is the path to the repository you want to create
%                  the report for. 
%    outDir      - Directory where the files will be saved. If you don't
%                  pass in an outDir then it will also create a directory
%                  one level above svnRootPath (named with the date (e.g.
%                  '12-Sep-2011') where it will save the *many* files that
%                  are created by statSVN (~16MB).
%    statExe     - Path to the statsSVN jar. 
% 
%  OUTPUTS:
%    svnHtmlIndex - The full path to the html index file that you
%                   can load in your browser.
% 
%  
%  USAGE NOTES:
%    Given the current state of affairs, namely the statSVN build, this
%    code can only be run on vistalab linux machines and macs with stat svn
%    installed. **If you're running on MAC then you must provide the path
%    to statsvn.jar, or select it later**.
% 
%  WEB RESOURCES:
%    mrvBrowseSVN('mrvStatSvn');
%    http://wiki.statsvn.org/ - for help downloading stat SVN.
%  
% 
%  (C) Stanford VISTA Lab, 2011 [lmp]
% 


%% Check inputs

if notDefined('svnRootPath')
    svnRootPath = vistaRootPath;
end

% This is the path to the statSVN executable for vistalab machines
if notDefined('statExe') || ~exist(statExe,'file')
    statExe = '/white/u8/lmperry/software/statSVN/statsvn-0.7.0/statsvn.jar';
    if ismac || ~exist(statExe,'file')
        statExe = mrvSelectFile('r','*','Select the statsvn executable.');
    end
end

disp('Running StatSVN ...');


%% Remind user to update svn before running this function & Confirm

prompt = sprintf('Running statSVN on: %s. \n For best results run this function ONLY after running svn update.\nWould you like to update the SVN root directory?\n',svnRootPath);
resp   = questdlg(prompt,'mrvStatsSvnHtml','Yes','No','Yes');
if(strcmpi(resp,'yes'))
    disp('Updating svn repo....'); 
    cmd = ['svn up ' svnRootPath];
    system(cmd);
end


%% Create the svn log file/dir name and build the command to create it

cd(svnRootPath); 
date = getDateAndTime; date = date(1:11); 

% Name the log file
logName = ['svn_' date '.log'];

% Create the command
logCmd = ['svn log -v --xml > ' logName];

fprintf('Creating svn log file...');
status = system(logCmd);

% If the logfile was not created throw an error. 
if status ~= 0
    error('Could not create the logfile'); 
else
    fprintf('Done.\n');
end

% Full path to the svn log file. 
svnLog = fullfile(svnRootPath,logName);


%% Create the directory where all the files will be saved.

if notDefined('outDir')
    dName   = ['statSvn_' date];
    statDir = fullfile(svnRootPath,dName);
else
    statDir = outDir;
end
if ~exist(statDir,'dir'), mkdir(statDir); end


%% Build and run the svnStat command in the statDir

cd(statDir);

% Create the statsvn command. I exclude fslabel.txt because that text file
% was initially checked with with around 1million lines beyond the text
% (not sure why) which was inflating the line count for lmperry. 
svnStatCmd = ['java -jar ' statExe ' -exclude "**/fslabel.txt" ' svnLog ' ' svnRootPath];

% Run the statsvn command
fprintf('Creating the stats files...');
status = system(svnStatCmd);

% If the stat command was not run properly throw an error. 
if status ~= 0
    error('Problem running statsvn command!'); 
else
    fprintf('Done.\n');
end


%% Return the path to the index file & load it in a browser

svnHtmlIndex = fullfile(statDir,'index.html');

% Launch the index using the user's default browser. 
fprintf('Loading results in your browser...');
stat = web(svnHtmlIndex,'-browser');

% If it does not load in the browser throw the path to the matlab window.
if stat ~= 0
    fprintf('Copy and paste this path into your browser to view the results \n %s', ...
        svnHtmlIndex);
else
    fprintf('Done.\n');
end


%% Remove the svnLog for cleanliness

rmCmd = ['rm ' svnLog];
system(rmCmd);


return



%% To run this on the typical vistasoft repos and display on lmperry's site

wbased  = '/white/u8/lmperry/public_html/code/devstats/'; %#ok<UNRCH>
rbased = '/white/u8/lmperry/svn/';
repos  = {'vistasoft','vistaproj','vistadata','kendrick','vistadisp','vistasrc'};

disp('Updating svn repos...');
cd(rbased);
cmd = 'svn up *'; 
system(cmd);

for i = 1:numel(repos)
    
    svnroot = fullfile(rbased,repos{i});
    outDir = fullfile(wbased,repos{i});
    mrvStatSvn(svnroot,outDir);
    
end






















