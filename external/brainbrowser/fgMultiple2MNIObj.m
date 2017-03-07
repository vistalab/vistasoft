function [coords, lineList,startPoints] = fg2MNIObj(fg,varargin)
% Convert fg data to MNI Obj format that can be viewed in brainbrowser.
%
%   [coords, lineList,startPoints] = fg2MNIObj(fg,'fname',fname,'color',c)
%
% Example:
%     rd = RdtClient('vistasoft');
%     rd.crp('/vistadata/diffusion/sampleData/fibers');
%     rd.readArtifact('leftArcuate','type','pdb','destinationFolder',pwd);
%     fg = fgRead('leftArcuate.pdb');
%
%     fg2MNIObj(fg,'fname','remoteFiber.obj','color',[0.8 0.4 0.9 1]);
% Or,
%     [~,lineList] = fg2MNIObj(fg,'fname','myTest.obj');
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
p.addParameter('fname','test.obj',@ischar);      % Output file
p.addParameter('color',[.8 .4 .8 .4],@isvector); % RGBa
p.addParameter('overwrite',false);               % Forces overwrite
p.addParameter('jitterColor',true);              % Jitter the colors or not
p.addParameter('jitterDev', 0.2);              % Jitter the colors or not

p.parse(fg,varargin{:});
fname = p.Results.fname;
color = p.Results.color;
if ~isequal(length(color),4)
    error('Color parameter should be RGBalpha, a 4D vector');
end
overwrite   = p.Results.overwrite;
jitterColor = p.Results.jitterColor;
jitterDev = p.Results.jitterDev;

%% For a big group we subsample the fibers

nGroups = length(fg);
subSample = 8;
for ii=1:nGroups
    keep = 1:subSample:length(fg(ii).fibers);
    fg(ii) = fgExtract(fg(ii),keep,'keep');
end

%%
nFibers = 0; 
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
if ~jitterColor,     jitterDev = 0;
else                 jitterDev = 0.1;
end

% Jitter the color for each line
% Make some random numbers to add to the color
randColors = color + randn(size(color))*jitterDev;
randColors = min(randColors,1);
randColors = max(randColors,0);

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
