function paramV = mtrFilename2Param(fileName,paramName)

% Will retrieve paramnames from files of the form *paramName_#_*.dat

sI = strfind(fileName,paramName)+length(paramName)+1;
eIVec = strfind(fileName,'_');
eI = min( eIVec(eIVec>sI) )-1;
if isempty(eI)
    eI = max(strfind(fileName,'.'))-1;
end
paramV = str2num(fileName(sI:eI));
return;