function mtrFG2Matrix(fgFilename,dt6Filename,matrixFilename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% mtrFG2Matrix([fgFilename],[dt6Filename],[matrixFilename])
%%
%% Matrix has the following form.
%%
%% Matrix.Data :
%%
%% Row i: param1# param2# ... paramN#
%%
%% Matrix.Names :
%%
%% {param1Name, param2Name, ..., paramNName}
%%
%% Author: Anthony Sherbondy
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if( ieNotDefined('fgFilename') )
    pathName = pwd;
    [f,p] = uigetfile({'*.dat';'*.*'},'Select a pathway database file for input...',pathName);
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    fgFilename = fullfile(p,f); 
end

if( ieNotDefined('dt6Filename') )
    pathName = pwd;
    [f,p] = uigetfile({'*.mat';'*.*'},'Select a dt6 file for coordinate space...',pathName);
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    dt6Filename = fullfile(p,f); 
end
dt6 = load(dt6Filename,'xformToAcPc');

if( ieNotDefined('matrixFilename') )
    pathName = pwd;
    [f,p] = uiputfile({'*.mat';'*.*'},'Select a matrix database for output...',pathName);
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    matrixFilename = fullfile(p,f); 
end

% Load pathways
fg = mtrImportFibers(fgFilename, dt6.xformToAcPc);


scoreID = [];
if (length(fg.params) == 1 && strcmp(fg.params{1}.name,'Weight'))
    scoreID = 1;
else
    for pp = 1:length(fg.params)
        ind = strfind(fg.params{pp}.name,'Posterior');
        if ~isempty(ind)
            scoreID = pp;
        end
    end
end
if (isempty(scoreID))
    error('Error: Unable to find score in statistics list!');
end

scoreVec = fg.params{scoreID}.stat;

% Calculate length for each path and get starting and ending points
for ff = 1:size(fg.fibers)
    startVec(ff,:) = fg.fibers{ff}(:,1)';
    endVec(ff,:) = fg.fibers{ff}(:,end)';
    lengthVec(ff) = length(fg.fibers{ff});
end

matrix.data = [startVec, endVec, lengthVec(:), scoreVec(:)];
matrix.names = {'startx','starty','startz','endx','endy','endz','length','score'};
[foo1, foo2, ext, foo3] = fileparts(matrixFilename);
if strcmp(ext,'.txt')
    M = matrix.data;
    save(matrixFilename,'M','-ascii');   
else
    save(matrixFilename, 'matrix');
end