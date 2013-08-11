function nfgRunBlueMatter(phantomDir, projType, bRunInMatlab, nNumProcs, nNumIndProcs)
%Create scripts to run the BlueMatter algorithm
%
%   nfgRunBlueMatter(phantomDir, nNumProcs)
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 

if ieNotDefined('nNumProcs'); nNumProcs=1; end
if ieNotDefined('nNumIndProcs'); nNumIndProcs=1; end
if ieNotDefined('bRunInMatlab'); bRunInMatlab=1; end

if (nNumProcs~=1 || nNumIndProcs~=1) && bRunInMatlab
    error('Can only handle 1 processor in matlab.');
end

if nNumProcs==1
    mpiRun = '';
else
    mpiRun = ['mpirun -n ' num2str(nNumProcs)];
end

% Directories
projPidsDir = nfgGetName([projType,'PidsDir'],phantomDir);
% Input Files
projPDBFile = nfgGetName([projType,'PDBFile'],phantomDir);
ctrparamsFile = nfgGetName('ctrparamsFile',phantomDir);
noisyImg = nfgGetName('noisyImg',phantomDir);
bvalsFile = nfgGetName('bvalsFile',phantomDir);
bvecsFile = nfgGetName('bvecsFile',phantomDir);
b0File = nfgGetName('b0File',phantomDir);
tensorsFile = nfgGetName('tensorsFile',phantomDir);
wmROIFile = nfgGetName('wmROIFile',phantomDir);
bashExe = nfgGetName('bashExe',phantomDir);
bmLogFile = nfgGetName('bmLogFile',phantomDir);
% Output Files
[path, dbName] = fileparts(projPDBFile);
dbFile = fullfile(path,[dbName,'_0.SBfloat']);
projBMPDBFile = nfgGetName([projType,'BMPDBFile'],phantomDir);
bmScriptFile = nfgGetName('bmScriptFile',phantomDir);

% Convert pdb file into SBfloat
disp(' '); disp(['Converting ' projPDBFile ' to ' dbFile]);
pParamFile = [' -i ' ctrparamsFile];
pOutFile = [' -p ' dbFile];
pInFile = [' ' projPDBFile];
pThresh = [' --thresh ' num2str(100000)];
cmd = ['contrack_score' pParamFile pOutFile pThresh ' --seq ' pInFile];
disp(cmd);
system(cmd,'-echo');

if bRunInMatlab
    % Create new directories
    disp(' ');disp(['Creating PIDS directory ' projPidsDir ' ...']);
    [s,mess,messid] = mkdir(projPidsDir);
    % Remove previous directories
    if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
        disp('Removing previous PIDs directory and re-creating...');
        system(['rm -rf ' projPidsDir]);
        mkdir(projPidsDir);
    end
    mkdir(fullfile(projPidsDir,'voxels'));
else
    fids = {};
    for pp=1:nNumIndProcs
        strAdd = ['_' num2str(pp-1)];
        [pathstr,name,ext] = fileparts(bmScriptFile);
        scriptFile = fullfile(pathstr,[name strAdd ext]);
        fidScript = fopen(scriptFile,'w');
        fids{pp} = fidScript;
        fprintf(fids{pp},['#!' bashExe '\n\n']);
        pidsDir = [projPidsDir strAdd];
        fprintf(fids{pp},[' rm -rf ' pidsDir '\n mkdir ' pidsDir '\n mkdir ' fullfile(pidsDir,'voxels') '\n\n']);
    end
end

% Common BlueMatter Parameters
argGroupSize = ' -v 2';
b0 = niftiRead(b0File);
argSubSize = [' -s 0,' num2str(b0.dim(1)-1) ',0,' num2str(b0.dim(2)-1) ',0,' num2str(b0.dim(3)-1)];
argDatabase = [' -d ' dbFile];

% Create SAPrep script portion
argPids = [' -o ' projPidsDir];
argRaw = [' -r ' noisyImg];
argBvals = [' --val ' bvalsFile];
argBvecs = [' --vec ' bvecsFile];
argB0 = [' -0 ' b0File];
argMatter = [' -m ' wmROIFile];

if bRunInMatlab
    argPrep = [argPids argRaw argDatabase argBvals argBvecs argB0 argMatter argGroupSize argSubSize];
    cmdPrep = [mpiRun ' trueSAPrep ' argPrep];
    disp(cmdPrep);
    system(cmdPrep,'-echo');
else
    for pp=1:nNumIndProcs
        strAdd = ['_' num2str(pp-1)];
        pidsDir = [projPidsDir strAdd];
        [pathstr,name,ext] = fileparts(bmLogFile);
        logFile = fullfile(pathstr,[name strAdd ext]);
        argPids = [' -o ' pidsDir];
        argPrep = [argPids argRaw argDatabase argBvals argBvecs argB0 argMatter argGroupSize argSubSize];
        cmdPrep = [mpiRun ' trueSAPrep ' argPrep];
        fprintf(fids{pp},[cmdPrep ' > ' logFile ' 2> ' logFile '\n\n']);
    end
end


% Create SA portion
fLambda = 0.2;
fDiameter = 0.03;
vI = [1,10000,1,20000];
nMinPts = 5;
fStd = 60;
fDl = 2.0; % fa=0.8, md=0.9
fDr = 0.35;
argStd = [' --std ' num2str(fStd)];
argTensors = [' --ten ' tensorsFile];
argLambda = [' -w ' num2str(fLambda)];
argDiameter = [' --diameter ' num2str(fDiameter)];
argIters = [' -t ' num2str(vI(1)) ',' num2str(vI(2)) ',' num2str(vI(3)) ',' num2str(vI(4))];
argMin = [' --minpts ' num2str(nMinPts)];
argDiff = [' --dl ' num2str(fDl) ' --dr ' num2str(fDr)];

if bRunInMatlab
    argSA = [argDatabase argPids argRaw argBvals argBvecs argB0 argMatter argStd argTensors argSubSize argIters argLambda argDiameter argMin argGroupSize argDiff];
    cmdSA = [mpiRun ' trueSA ' argSA];
    disp(cmdSA);
    system(cmdSA,'-echo');
else
    for pp=1:nNumIndProcs
        strAdd = ['_' num2str(pp-1)];
        pidsDir = [projPidsDir strAdd];
        argPids = [' -o ' pidsDir];
        [pathstr,name,ext] = fileparts(bmLogFile);
        logFile = fullfile(pathstr,[name strAdd ext]);
        argSA = [argDatabase argPids argRaw argBvals argBvecs argB0 argMatter argStd argTensors argSubSize argIters argLambda argDiameter argMin argGroupSize argDiff];
        cmdSA = [mpiRun ' trueSA ' argSA];
        fprintf(fids{pp},[cmdSA ' >> ' logFile ' 2>> ' logFile '\n\n']);
    end
end

% Create pid2pdb portion
argVol = [' -v ' b0File];
argOutputPDB = [' -o ' projBMPDBFile];
argInputPids = [' -p ' fullfile(fullfile(projPidsDir,'model.pid'))];


if bRunInMatlab
    argP2P = [argDatabase argVol argOutputPDB argInputPids];
    cmdP2P = ['pid2pdb ' argP2P];
    disp(cmdP2P);
    system(cmdP2P,'-echo');
else
    for pp=1:nNumIndProcs
        strAdd = ['_' num2str(pp-1)];
        pidsDir = [projPidsDir strAdd];
        argInputPids = [' -p ' fullfile(fullfile(pidsDir,'model.pid'))];
        [pathstr,name,ext] = fileparts(projBMPDBFile);
        argOutputPDB = [' -o ' fullfile(pathstr,[name strAdd ext])];
        [pathstr,name,ext] = fileparts(bmLogFile);
        logFile = fullfile(pathstr,[name strAdd ext]);
        argP2P = [argDatabase argVol argOutputPDB argInputPids];
        cmdP2P = ['pid2pdb ' argP2P];
        fprintf(fids{pp},[cmdP2P ' >> ' logFile ' 2>> ' logFile '\n\n']);
        fclose(fids{pp});
        [pathstr,name,ext] = fileparts(bmScriptFile);
        scriptFile = [fullfile(pathstr,[name strAdd ext])];
        system(['chmod +x ' scriptFile]);
        disp(' '); disp(['Wrote script ' scriptFile]);
    end
    
end

% pParamFile = [' -i ' ctrparamsFile];
% pOutFile = [' -p ' projBMPDBFile];
% pInFile = [' ' projBMBfloatFile];
% pThresh = [' --thresh ' num2str(100000)];
% cmd = ['contrack_score' pParamFile pOutFile pThresh ' --seq ' pInFile];
% disp(cmd);
% system(cmd,'-echo');


% Save script and tell them how to run it
