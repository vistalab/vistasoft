function createReadmeParams
% function pcreateReadmeParams
%
% Writes pulse sequence params and analysis params to Readme. 
% Called by mrCreateReadme.m
%
% DJH, 9/4/01

global mrSESSION dataTYPES

[fid, message] = fopen('Readme.txt', 'a');
if fid == -1
    warndlg(message);
    return
end

nScans = length(mrSESSION.functionals);

% pulse sequence parmeters:
% scan TR interleaves TE FOV matrixSize effRes
% for iScan = 1:nScans
%     effRes = mrSESSION.functionals(iScan).effectiveResolution;
%     fprintf(fid,'%s \t',effRes);
% end

% Descriptions/annotation:
fprintf(fid,'\n\n%s\n','Descriptions:');
fprintf(fid,'%s\t%s\n','scan','Description');
for iScan = 1:nScans
    str = dataTYPES(1).scanParams(iScan).annotation;
    fprintf(fid,'%d\t%s\n',iScan,str);
end

% Pulse sequence parameters:
fprintf(fid,'\n\n%s\n','Pulse sequence parameters:');
fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',...
    'scan','Pfile','TE','TR','nShots','framePeriod','FOV','matSize','inplaneRes','nSlices','thick','totalFrames');
for iScan = 1:nScans
    % disp(iScan)
    % disp(mrSESSION.functionals(iScan));
    
    fprintf(fid, '%d\t', iScan);
    PfileName = mrSESSION.functionals(iScan).PfileName;
    fprintf(fid, '%s\t', PfileName);
    TE = mrSESSION.functionals(iScan).reconParams.TE;
    fprintf(fid, '%d\t', TE);
    TR = mrSESSION.functionals(iScan).reconParams.TR;
    fprintf(fid, '%d\t', TR);
    nShots = mrSESSION.functionals(iScan).reconParams.nshots;
    fprintf(fid, '%d\t', nShots);
    framePeriod = mrSESSION.functionals(iScan).framePeriod;
    fprintf(fid, '%g\t', framePeriod);
    FOV = mrSESSION.functionals(iScan).reconParams.FOV;
    fprintf(fid, '%d\t', FOV);
    matSize = mrSESSION.functionals(iScan).reconParams.equivMatSize;
    fprintf(fid, '%d\t', matSize);
    inplaneRes = mrSESSION.functionals(iScan).effectiveResolution;
    fprintf(fid, '%s%g%s%g%s\t', '[', inplaneRes(1),' ',inplaneRes(2),']');
    nSlices = mrSESSION.functionals(iScan).reconParams.slquant;
    fprintf(fid, '%d\t', nSlices);
    thickness = mrSESSION.functionals(iScan).reconParams.sliceThickness;
    fprintf(fid, '%d\t', thickness);
    totalFrames = mrSESSION.functionals(iScan).reconParams.nframes;
    fprintf(fid, '%d\n', totalFrames);
end

% Analysis parameters:
fprintf(fid,'\n\n%s\n','Analysis parameters:');
fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\n',...
    'scan','junkFrames','nFrames','detrend','nCycles','inhomoCorrect');
for iScan = 1:nScans
    fprintf(fid, '%d\t', iScan);
    junkFrames = mrSESSION.functionals(iScan).junkFirstFrames;
    fprintf(fid, '%d\t', junkFrames);
    nFrames = mrSESSION.functionals(iScan).nFrames;
    fprintf(fid, '%d\t', nFrames);
    detrend = dataTYPES(1).blockedAnalysisParams(iScan).detrend;
    fprintf(fid, '%d\t', detrend);
    nCycles = dataTYPES(1).blockedAnalysisParams(iScan).nCycles;
    fprintf(fid, '%d\t', nCycles);
    inhomoCorrect = dataTYPES(1).blockedAnalysisParams(iScan).inhomoCorrect;
    fprintf(fid, '%d\n', inhomoCorrect);
end
% slices = mrSESSION.functionals(iScan).slices;
% fprintf(fid,'%s\t',slices);

fprintf(fid,'\n\n');

status = fclose(fid);
if status == -1
    warndlg(message);
    return
end

return

