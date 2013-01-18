function dtiGradsGenerateGradsFile(nDirs, outFileName, numNonDwPerDw, addInverseDirs)
%
% dtiGradsGenerateGradsFile(nDirs, outFileName, [numNonDwPerDw=1/11.3], [addInverseDirs=true])
%
% numNonDwPerDw is the number of non-diffusion-weighted (b=0) volumes per
% dw volume. Jones et. al. MRM 1999 suggest that this should be 11.3 for
% optimal estimation of quantitative diffusivity parameters.
%
% HISTORY:
% 2007.08.10 RFD: wrote it.

gradsDir = fileparts(which(mfilename));
caminoPtsDir = fullfile(gradsDir,'caminoPts');

ptsFile = fullfile(caminoPtsDir,sprintf('Elec%03d.txt',nDirs));
if(~exist(ptsFile,'file'))
    error('No points file for %d directions.',nDirs);
end
if(~exist('numNonDwPerDw','var')||isempty(numNonDwPerDw))
    numNonDwPerDw = 1./11.3;
    % 11.3 comes from Jones et. al. MRM 1999.
end
if(~exist('addInverseDirs','var')||isempty(addInverseDirs))
    addInverseDirs = true;
end
if(~exist(outFileName,'var')||isempty(outFileName))
    outFileName = fullfile(gradsDir, sprintf('dwepi.%d.grads',nDirs)); 
end
if(exist(outFileName,'file'))
    [f,p] = uiputfile(outFileName, 'Files exists- please select...');
    if(isequal(f,0) || isequal(p,0))
        disp('User canceled.'); 
        return;
    end
    outFileName = fullfile(p,f);
end
disp(['Saving grads in ' outFileName '...']);

if(numNonDwPerDw<1)
    nNonDw = round(max(1,2*nDirs*numNonDwPerDw));
else
    nNonDw = numNonDwPerDw;
end

pts = dlmread(ptsFile);
if(pts(1)~=nDirs)
    error('pts file %s is invalid.',ptsFile);
end
pts = reshape(pts(2:end),3,nDirs);
if(addInverseDirs)
    pts = [pts -pts];
    nDirs = nDirs*2;
else
    % randomly flip half the dirs
    flipThese = randperm(nDirs);
    flipThese = flipThese(1:floor(nDirs/2));
    pts(:,flipThese) = -pts(:,flipThese);
end
pts = pts';
totalNumMeasurements = nDirs+nNonDw;

dirs = zeros(totalNumMeasurements,3);
s = totalNumMeasurements/nNonDw;
nonDwInds = round([0:nNonDw-1]*s+1);
dwInds = ~ismember([1:totalNumMeasurements],nonDwInds);
dirs(dwInds,:) = pts;

if(~exist('outFileName','var')||isempty(outFileName))
    outFileName = sprintf('dwepi.%d.grads',totalNumMeasurements);
    if(isunix)
        outFileName = fullfile('/usr','local','dti','diffusion_grads',outFileName);
    end
    [f,p] = uiputfile({'*.grads';'*.*'},'Save grads file as...',outFileName);
    if(isequal(f,0) || isequal(p,0)), disp('User cancelled.'); return; end
    outFileName = fullfile(p,f);
end

dlmwrite(outFileName,dirs,'delimiter',' ','newline','unix','precision',6);

figure;
plot3(dirs(:,1),dirs(:,2),dirs(:,3),'k.'); axis square; 

return;