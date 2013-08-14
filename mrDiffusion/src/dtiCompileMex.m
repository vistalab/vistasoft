function dtiCompileMex

oldDir = pwd;
rootdir=fileparts(fileparts(which('mrDiffusion')));

mexFiles = {};

cd(fileparts(which('dtiFiberTracker.cxx')));
disp('Compiling dtiFiberTracker.cxx ...');
try
    mex -O -I./jama dtiFiberTracker.cxx
    mexFiles{end+1} = ['dtiFiberTracker.' mexext];
catch
    disp('Compiling dtiFiberTracker.cxx FAILED...');
end

cd(fileparts(which('nearpoints.cxx')));
disp('Compiling nearpoints.cxx ...');
try
    mex -O nearpoints.cxx
    mexFiles{end+1} = ['nearpoints.' mexext];
catch
    disp('Compiling nearpoints.cxx FAILED...');
end

cd(fileparts(which('magicwand1.c')));
disp('Compiling magicwand1.c ...');
try
    mex -O magicwand1.c
    mexFiles{end+1} = ['magicwand1.' mexext];
catch
    disp('Compiling magicwand1.c FAILED...');
end

cd(fileparts(which('dtiJointHist.c')));
disp('Compiling dtiJointHist.c ...');
try
    mex -O dtiJointHist.c
    mexFiles{end+1} = ['dtiJointHist.' mexext];
catch
    disp('Compiling dtiJointHist.c FAILED...');
end

cd(fileparts(which('niftiRead.c')));
disp('Compiling read/writeFileNifti ...');
try
    mex niftiRead.c nifti1_io.c znzlib.c zlib/adler32.c zlib/compress.c zlib/crc32.c zlib/deflate.c zlib/gzio.c zlib/infback.c zlib/inffast.c zlib/inflate.c zlib/inftrees.c zlib/trees.c zlib/zutil.c
    mexFiles{end+1} = ['niftiRead.' mexext];
    mex writeFileNifti.c nifti1_io.c znzlib.c zlib/adler32.c zlib/compress.c zlib/crc32.c zlib/deflate.c zlib/gzio.c zlib/infback.c zlib/inffast.c zlib/inflate.c zlib/inftrees.c zlib/trees.c zlib/zutil.c
    mexFiles{end+1} = ['writeFileNifti.' mexext];
catch
    disp('Compiling read/writeFileNifti.c FAILED...');
end

%      disp('Compiling dtiTensorInterp_Pajevic.c ...');
%      if(strcmp(computer,'GLNX86'))
%          mex -O dtiTensorInterp_Pajevic.c ./bcadtlib.so
%          mexFiles{end+1} = ['dtiTensorInterp_Pajevic.' mexext];
%      else
%          warning('dtiTensorInterp_Pajevic.c can only be compiled under 32-bit linux! Skipping it...'); %#ok<WNTAG>
%      end

%Confusing, multiple copies of sources and/or mex files in a different
%directory
%(1) 'mrManDist'; %Csource: c source
%(2) 'dijkstra2';%Csource under ManifoldUtilities AND within dir mrFlatMesh
%(3) 'dijkstra';%Csource


%'curvature'; -- where is the source?
%'smooth_mesh'; -- where is the source?
%'build_mesh'; -- where is the source?

%List of files to compile with path relative from the root vistasoft dir
functionsToCompile={
    ['mrAlign' filesep 'regInplanes'];
    ['mrAlign' filesep 'regHistogram'];
    ['mrAnatomy' filesep 'MrGray' filesep 'GrowGrayMatter' filesep 'grow_gray']; %cpp
    ['mrAnatomy' filesep 'mrMesh' filesep 'tcpToolbox' filesep 'pnet'];
    ['mrAnatomy' filesep 'VolumeUtilities' filesep 'mrAnatFastInterp3'];
    ['mrAnatomy' filesep 'VolumeUtilities' filesep 'myCinterp3'];
    ['mrDiffusion' filesep 'src' filesep 'dtiFitTensor'];
    ['mrDiffusion' filesep 'src' filesep 'dtiSplitTensor'];
    ['mrDiffusion' filesep 'xform' filesep 'fastDeformation' filesep 'trilin'];
    ['mrDiffusion' filesep 'xform' filesep 'fastDeformation' filesep 'initInvDiagsInC'];
    ['mrLoadRet' filesep 'Analysis' filesep 'SignalProc' filesep 'sumOfNeighbors'];
    ['mrLoadRet' filesep 'Analysis' filesep 'MotionComp' filesep 'MI' filesep 'MI' filesep 'Joint_Histogram' filesep 'spm_hist2_weighted_MI'];
    ['mrLoadRet' filesep 'Analysis' filesep 'MotionComp' filesep 'MI' filesep 'MI' filesep 'Joint_Histogram' filesep 'spm_hist2_weighted'];
    ['mrDiffusion' filesep 'src' filesep 'ndfun'];
    };

for CfileI =1:size(functionsToCompile, 1)
    cext='.c';
    CfileName=functionsToCompile{CfileI};
    [srcDir, f] = fileparts(which(CfileName));
    if(~exist(srcDir, 'dir'))
        warning(['Something went wrong! Where is ' srcDir ' directory?']); %#ok<WNTAG>
    end
    cd(srcDir);
    if(~exist([f cext], 'file'))
        cext='.cpp';
    end

    try
        disp(['Compiling ' f '...']);
        cmd = ['mex -O ' f cext];
        if(ispc)
            compileWithLapackLibToWinCommmand(cmd);
        else
            eval([cmd ' -lmwlapack -lmwblas']);
        end
        mexFiles{end+1} = [f '.' mexext];

    catch
        warning('Something went wrong! Check mex messages above.'); %#ok<WNTAG>
    end

end

fprintf('%d files compiled successfully.\n', length(mexFiles));

if(~isempty(mexFiles))
    fprintf('\n\n');
    fprintf('The following files were compiled and placed into the directories where respective source files were located%s:\n\n');
    for ii=1:length(mexFiles); fprintf('  %s\n', mexFiles{ii}); end
    %fprintf('\n\nYou probably want to move them to the usual place for mex files\n');
    %fprintf('(maybe %s ?)\n\n', fullfile(fileparts(srcDir),'DLLXX'));
end
cd(oldDir);

return;

function compileWithLapackLibToWinCommmand(cmd)

if exist(fullfile(matlabroot, 'extern', 'lib', 'win32', 'microsoft', 'libmwlapack.lib'),'file')
    libFile = fullfile(matlabroot, 'extern', 'lib', 'win32', 'microsoft', 'libmwlapack.lib');
elseif exist(fullfile(matlabroot, 'extern', 'lib', 'win32', 'microsoft', 'msvc60', 'libmwlapack.lib'),'file')
    libFile = fullfile(matlabroot, 'extern', 'lib', 'win32', 'microsoft', 'msvc60', 'libmwlapack.lib');
elseif exist(fullfile(matlabroot, 'extern', 'lib', 'win64', 'microsoft', 'libmwlapack.lib'),'file')
    libFile = fullfile(matlabroot, 'extern', 'lib', 'win64', 'microsoft', 'libmwlapack.lib');
else
    error('Cannot find libmwlapack.lib in standarad matlab directories!');
end

if isempty(find(matlabroot) == ' ')
    cmd = [cmd ' ' libFile];
    eval(cmd);
else
    copyfile(libFile);
    cmd = [cmd ' libmwlapack.lib'];
    eval(cmd);
    delete('libmwlapack.lib');
end

return;

% /home/bob/svn/vistasoft/trunk/fileFilters/nifti/niftiRead.mexa64
% /home/bob/svn/vistasoft/trunk/fileFilters/nifti/matToQuat.mexa64
% /home/bob/svn/vistasoft/trunk/fileFilters/nifti/writeFileNifti.mexa64
% /home/bob/svn/vistasoft/trunk/mrAlign/regInplanes.mexa64
% /home/bob/svn/vistasoft/trunk/mrAlign/regHistogram.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/MrGray/GrowGrayMatter/grow_gray.mexa64
%
% /home/bob/svn/vistasoft/trunk/mrAnatomy/mrMesh/curvature.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/mrMesh/tcpToolbox/pnet.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/mrMesh/smooth_mesh.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/mrMesh/build_mesh.mexa64
%
% /home/bob/svn/vistasoft/trunk/mrAnatomy/VolumeUtilities/nearpoints.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/VolumeUtilities/mrAnatFastInterp3.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/VolumeUtilities/myCinterp3.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/ManifoldUtilities/mrManDist.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/ManifoldUtilities/Csource/dijkstra2.mexa64
% /home/bob/svn/vistasoft/trunk/mrAnatomy/ManifoldUtilities/ShortestPaths/dijkstra.mexa64
%X /home/bob/svn/vistasoft/trunk/mrDiffusion/src/dtiFitTensor.mexa64
%X /home/bob/svn/vistasoft/trunk/mrDiffusion/src/dtiSplitTensor.mexa64
%X /home/bob/svn/vistasoft/trunk/mrDiffusion/src/dtiFiberTracker.mexa64
%X/home/bob/svn/vistasoft/trunk/mrDiffusion/src/ndfun.mexa64
% X/home/bob/svn/vistasoft/trunk/mrDiffusion/src/magicwand1.mexa64
% X/home/bob/svn/vistasoft/trunk/mrDiffusion/src/dtiJointHist.mexa64
% /home/bob/svn/vistasoft/trunk/mrDiffusion/xform/fastDeformation/trilin.mexa64
% /home/bob/svn/vistasoft/trunk/mrDiffusion/xform/fastDeformation/initInvDiagsInC.mexa64
% /home/bob/svn/vistasoft/trunk/mrLoadRet/Analysis/SignalProc/sumOfNeighbors.mexa64
% /home/bob/svn/vistasoft/trunk/mrLoadRet/Analysis/MotionComp/MI/MI/Joint_Histogram/spm_hist2_weighted_MI.mexa64
% /home/bob/svn/vistasoft/trunk/mrLoadRet/Analysis/MotionComp/MI/MI/Joint_Histogram/spm_hist2_weighted.mexa64


