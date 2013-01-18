function stim = prt2par(prtFile, TR, parFile);
%
% stim = prt2par(prtFile, [TR=2], [parFile]);
%
% Convert BrainVoyager .prt files to mrVista .par files.
% 
% prtFile and parFile can be a path string, or a cell of such strings, in
% which case it iterates. TR is the frame period to use when reading the
% prt files.
%
%
% ras, 07/06.
if notDefined('TR'), TR = 2; end

if notDefined('prtFile')
    [f p] = uigetfile({'*.prt' '*.*'}, 'Choose a Brain Voyager .prt file');
    prtFiles = fullfile(p,f);
elseif isequal(prtFile, 'all')
    w = dir('*.prt');
    prtFile = {w.name};
end

if iscell(prtFile)
    if notDefined('parFile') 
        for i = 1:length(prtFile)
            stim(i) = prt2par(prtFile{i}, TR, []);
        end
    else
        for i = 1:length(prtFile)
            stim(i) = prt2par(prtFile{i}, TR, parFile{i});
        end
    end
    return
end

if notDefined('parFile') % use same filename, different extension
    [p f ext] = fileparts(fullpath(prtFile));
    parFile = fullfile(p, [f '.par']);
end


stim = stimReadPrt(prtFile, TR);

par = stim; par.onset = stim.onsetSecs; 
par.color = cell(1, length(par.cond));
for i = 1:par.nConds
    ind = find(par.cond==par.condNums(i));
    if ~isempty(ind)
        par.color{ind(1)} = par.condColors{i};
    end
end
writeParfile(par, parFile);

return

