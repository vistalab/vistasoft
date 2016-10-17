function [coords, lineList,startPoints] = fg2MNIObj(fg,varargin)
% Convert fg data to MNI Obj format that can be viewed in brainbrowser.
%
%   [coords, lineList,startPoints] = fg2MNIObj(fg)
%
% Example:
%
% RF/BW

%% Parse file name and other parameters that may arise
p = inputParser;

p.addRequired('fg');
p.addParameter('fname','test.obj',@ischar);
p.parse(fg,varargin{:});
fname = p.Results.fname;

%%

nFibers = length(fg.fibers);  % How many fibers are we writing out?
nPoints = zeros(nFibers,1);   % How many points in each fiber?
for jj=1:nFibers
    nPoints(jj)  = size(fg.fibers{jj},2);
end

%% Store the coords and list of points in each line
coords = zeros(sum(nPoints),3);
startPoints = [0; cumsum(nPoints)];
lineList = cell(1,nFibers);
for ii=1:nFibers
    lineList{ii} = (startPoints(ii)+1):startPoints(ii+1);
    coords(lineList{ii},:) = fg.fibers{ii}';
end

%% Open the file for writing

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
fprintf(fileID,'\n%d\n',length(lineList));
fprintf(fileID,'0 .5 .6 .7 1\n\n');

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
