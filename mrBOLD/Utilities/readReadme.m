function info = readReadme(filePath);
%
% readReadme: read a Readme.txt file for mrLoadRet / KGS analysis tools
% 
% Usage: info = readReadme([filePath]);
% 
% ras, 09/10/03

% Programming Notes.
%   We should change mrInitRet to write out the info variable directly.
%   Then we would not have to parse this text file.  Most people (is this
%   true?) are just using the mrInitRet procedure to create the readMe file
%   anyway. -- BW/MBS

if ~exist('filePath','var') filePath = fullfile(pwd,'Readme.txt');      end

if ~exist(filePath,'file')
    fprintf('ERROR: File %s could not be found.\n',filePath);
    return;
end

info = [];
fid = fopen(filePath,'r');

%%%%% Read header

% ignore 'session code:' string
ignore = fscanf(fid,'%s',2);
info.session = fscanf(fid,'%s',1);

% ignore 'Description' string
ignore = fscanf(fid,'%s',1);
info.description = fgetl(fid);

% remove leading and trailing spaces
if ~isempty(info.description) & ~all(info.description==' ')
	while info.description(1) == ' '
        info.description = info.description(2:end);
	end
	while info.description(end) == ' '
        info.description = info.description(1:end-1);
	end
end

% ignore 'Subject:'
ignore = fscanf(fid,'%s',1);
info.subject = rmWhitespace(fgetl(fid));

% ignore 'Operator:'
ignore = fscanf(fid,'%s',1);
info.operator = rmWhitespace(fgetl(fid));

% ignore entire 'Recon/Readme by' line
ignore = fgetl(fid);

% ignore 'Magnet':
ignore = fscanf(fid,'%s',1);
info.magnet = rmWhitespace(fgetl(fid));

% ignore 'Coil':
ignore = fscanf(fid,'%s',1);
info.coil = rmWhitespace(fgetl(fid));

% ignore 'Exam Number':
ignore = fscanf(fid,'%s',2);
info.examNumber = fscanf(fid,'%i',1);

% ignore 'Slice Orientation':
ignore = fscanf(fid,'%s',2);
info.sliceOrientation = rmWhitespace(fgetl(fid));

% ignore 'Protocol Name':
ignore = fscanf(fid,'%s',2);
info.protocol = rmWhitespace(fgetl(fid));

% ignore the next two blank lines
fgetl(fid);
fgetl(fid);

% ignore the two description title lines
fgetl(fid);
fgetl(fid);

% init scans struct (will end up adding this to info struct)
scans = [];

% scan in the descriptions for each scan (and get numScans)
scannum = fscanf(fid,'%i',1);
while ~isempty(scannum)
    scans(scannum).name = [info.session ' scan ' num2str(scannum)];
    scans(scannum).description = rmWhitespace(fgetl(fid));
    
    scannum = fscanf(fid,'%i',1);
end
info.numScans = length(scans);

% ignore the next blank line
fgetl(fid);

% ignore the two pulse seq param title lines
fgetl(fid);

for i = 1:info.numScans
    check = fscanf(fid,'%i',1);
    if ~isequal(check,i)
        error('Huh? Non matching scan numbers in the pulse seq area.');
    end
    scans(i).Pfile = fscanf(fid,'%s',1);
    
    % a heuristic:
    % for several scans the TR, TE, and framePeriod fields are omitted
    % (some quirk w/ Gary's recon script), this heuristic detects this and
    % compensates for it:
    
    restofln = fgets(fid);
    vals = {};
    while ~isempty(restofln)
        [vals{end+1},ignore,ignore,ind] = sscanf(restofln,'%s',1);
        restofln = restofln(ind:end);
    end
    
    if length(vals)==12 % all fields present in file
        scans(i).TE = str2num(vals{1});
        scans(i).TR = str2num(vals{2});
        scans(i).nShots = str2num(vals{3});
        scans(i).framePeriod = str2num(vals{4});
        scans(i).FOV = str2num(vals{5});
        scans(i).matSize = str2num(vals{6});
        scans(i).inplaneRes = [str2num(vals{7}(2:end)) str2num(vals{8}(1:end-1))];
        scans(i).nSlices = str2num(vals{9});
        scans(i).thick = str2num(vals{10});
        scans(i).totalFrames = str2num(vals{11});
    else % guessing TR, TE, and framePeriod fields missing
        scans(i).TE = [];
        scans(i).TR = 1000; % I think all scans of this sort had TR = 1 sec
        scans(i).nShots = str2num(vals{1});
        scans(i).framePeriod = 1; % I think all scans of this sort had TR = 1 sec
        scans(i).FOV = str2num(vals{2});
        scans(i).matSize = str2num(vals{3});
        scans(i).inplaneRes = [str2num(vals{4}(2:end)) str2num(vals{5}(1:end-1))];
        scans(i).nSlices = str2num(vals{6});
        scans(i).thick = str2num(vals{7});
        scans(i).totalFrames = str2num(vals{8});
    end
    
    scans(i).comments = '';
end    

%%%%% skipping the analysis parameters info for now
ignore = fgetl(fid);
ignore = fgetl(fid);
ignore = fgetl(fid);
ignore = fgetl(fid);
for i = 1:info.numScans
    ignore = fgetl(fid);
end
ignore = fgetl(fid);
ignore = fgetl(fid);

%%%%% anything that remains after anal params are comments
info.comments = [];
info.comments = fscanf(fid,'%c');
% info.comments = {};
% while ~feof(fid)
%     info.comments{end+1} = fgetl(fid);
% end

fclose('all');

info.scans = scans;

return


%--------------------------------------------------
function strOut = rmWhitespace(strIn);
% removes leading and trailing whitespace (tabs, spaces, and soon carriage return)
% in a string, but leaves white space (and buildings!) intact. Working on
% it can make you crazy --- soo many ethical dilemnas --- I had a friend
% who was working on it. They had to give him a lobotomy. But now he's well again.
% 09/03 by rasasdf#*$NML))F
strOut = strIn;

whiteSpaceVals = [7 8 9 10 32];

while ~isempty(strOut) & ismember(double(strOut(1)),whiteSpaceVals)
    strOut = strOut(2:end);
end

while ~isempty(strOut) & ismember(double(strOut(end)),whiteSpaceVals)
    strOut = strOut(1:end-1);
end

return