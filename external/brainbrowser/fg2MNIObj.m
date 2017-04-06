function [coords, lineList, startPoints] = fg2MNIObj(fg,varargin)
% FG2MNIOBJ - Convert array of fg to MNI Obj file for visualization
%
% Required Inputs
%   fg:  An array of vistasoft fiber groups
% Optional inputs
%  fname:      Full path to output file name
%  overwrite:  Overwrite existing file
%  jitter:     Jitter the RGB colors by this random amount (0,1)
%
%  You can view the MNI OBJ data in brainbrowser by loading the file to
%  this site:  https://brainbrowser.cbrain.mcgill.ca/surface-viewer#dti
%
% See also: obj<> files.  Perhaps this should be grouped with those, but I
% am not sure this format is viewable by meshlab.app, and a legitimate OBJ
% file.
%
%
% RF/BW, Vistasoft Team 2016

%% Parse file name and other parameters that may arise
p = inputParser;

p.addRequired('fg');
p.addParameter('fname','test.mni.obj',@ischar);  % Output file
p.addParameter('overwrite',false);               % Forces overwrite
p.addParameter('jitter', 0.1);                  % Jitter the colors

p.parse(fg,varargin{:});
fname     = p.Results.fname;
overwrite = p.Results.overwrite;
jitter    = p.Results.jitter;

%%
nFibers = 0;
nGroups = length(fg);
for ii=1:nGroups, nFibers = nFibers + length(fg(ii).fibers); end

color = zeros(nFibers,4);     % Initialize a color for each group
nPoints = zeros(nFibers,1);   % How many points in each fiber?

kk = 0;
for ff = 1:nGroups
    for jj=1:length(fg(ff).fibers)
        kk = kk + 1;
        color(kk,:) = [fg(ff).colorRgb/255,1];
        nPoints(kk)  = size(fg(ff).fibers{jj},2);
    end
end

fgAll = fg(1);
for ff = 2:nGroups
    fgAll = fgMerge(fgAll,fg(ff),'all');
end

%% Store the coords and list of points in each line
coords = zeros(sum(nPoints),3);
startPoints = [0; cumsum(nPoints)];
lineList = cell(1,nFibers);
for ii=1:nFibers
    lineList{ii} = (startPoints(ii)+1):startPoints(ii+1);
    coords(lineList{ii},:) = fgAll.fibers{ii}';
end

%% Open the file for writing

if exist(fname,'file') && ~overwrite
    disp('The file already exists.  Press space bar to over-write');
    pause
end

% We should probably test if the file exists already!
fileID = fopen(fname,'w');
fprintf(fileID,'L 1 %d\n', size(coords,1));

% Write out the coords
fprintf(fileID,'%.4f %.4f %.4f\n',coords');

% Write the color of all the lines.
% We need to figure out how to do each line, or ...
% And this should become a parameter
% And we should figure out what the 0 at the front means.  Renzo knows, and
% it is important.
% The others are R G B alpha
nLines = length(lineList);
fprintf(fileID,'\n%d\n',nLines);

% Jitter the color for each line
% Make some random numbers to add to the color
randColors = color;
if jitter > 0
    theseColors = randColors(:,1:3);
    scale = mean(theseColors,2);
    randFactor = 1 + randn(size(scale))*jitter;
    theseColors = diag(randFactor)*theseColors ;
    randColors = [theseColors,ones(nFibers,1)];
    randColors = min(randColors,1);
    randColors = max(randColors,0);
end

fprintf(fileID,'1\n');
for ii=1:nLines
    fprintf(fileID,'%.2f %.2f %.2f %.2f\n',...
        randColors(ii, 1),randColors(ii, 2),randColors(ii, 3),randColors(ii, 4));
end
% In principle, we could have '2\n' and then a color per vertex

% Now a list that counts the number of points in each fiber.
fprintf(fileID,'%d ',startPoints(2:end));
fprintf(fileID,'\n\n');

% Write out the lineLists (points in each line)
for ii=1:nFibers
    fprintf(fileID,'%d ',lineList{ii}-1);
    fprintf(fileID,'\n');
end

% Close the file and go home
fclose(fileID);

end
