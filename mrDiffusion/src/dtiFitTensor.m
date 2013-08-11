function dtiFitTensor()
% OBSOLETE
% Help file for the  compiled mex function dtiFitTensor.
%
% To compile on most platforms, run:
%   cd(fileparts(which('dtiFitTensor.c')))
%   mex -O dtiFitTensor.c
%
% On Microsoft Windows, you have to append one of the following filenames to
% the command line, where <root> is what you get when you call matlabroot:
%  - lcc compiler: <root>\extern\lib\win32\lcc\libmwlapack.lib
%  - Visual C++:   <root>\extern\lib\win32\microsoft\msvc60\libmwlapack.lib
%
% To compile under linux with gcc, run:
%    mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' dtiFitTensor.c
%
% TEST CODE:
% 
%  bn = '/biac3/wandell4/data/reading_longitude/dti_y4/mho070519/raw/rawDti_g13_b800_aligned';
% 
%  bn = '/biac3/wandell4/data/reading_longitude/dti_y1/ar040522/raw/rawDti';
% 
% Examples:
%  dwRaw = niftiRead([bn '.nii.gz']);
%  sz = size(dwRaw.data);
%  d = double(dwRaw.data);
%  bvecs = dlmread([bn '.bvecs']);
%  bvals = dlmread([bn '.bvals']);
%  tau = 40;
%  q = [bvecs.*sqrt(repmat(bvals./tau,3,1))]';
%  X = [ones(size(q,1),1) -tau.*q(:,1).^2 -tau.*q(:,2).^2 -tau.*q(:,3).^2 -2*tau.*q(:,1).*q(:,2) -2*tau.*q(:,1).*q(:,3) -2*tau.*q(:,2).*q(:,3)];
%  tic; [dt,pdd] = dtiFitTensor(d,X); toc;
%  makeMontage3(abs(pdd));
% 
%  % Try using a mask:
%  mnB0 = mean(d(:,:,:,bvals==0),4);
%
%  % Tidy up the data a bit- replace any dw value > the mean b0 with the mean b0.
%  % Such data must be artifacts and fixing them reduces the # of non P-D tensors.
%  for(ii=find(bvals>0)) tmp=d(:,:,:,ii); bv=tmp>mnB0; tmp(bv)=mnB0(bv); d(:,:,:,ii)=tmp; end 
%  mask = uint8(dtiCleanImageMask(mrAnatHistogramClip(mnB0,0.4,0.99)>0.3));
%  tic;[dt,pdd] = dtiFitTensor(d,X,0,[],mask); toc
%  makeMontage3(abs(pdd));
% 
%  % Add some permutations (Repetition)
%  pm = dtiBootGetPermMatrix(dlmread([bn '.bvecs']), dlmread([bn '.bvals']));
%  permutations = dtiBootGetPermutations(pm, 500, 1);
%  tic;[dt,pdd,mdStd,faStd,pddDisp] = dtiFitTensor(d,X,1,permutations,mask); toc
%  b0=exp(dt(:,:,:,1)); b0=mrAnatHistogramClip(b0,0.4,0.99);
%  showMontage(b0);
%  [fa,md] = dtiComputeFA(dt(:,:,:,2:7));
%  md(md>5) = 5; md(md<0) = 0;
%  showMontage(fa);
%  showMontage(md);
%  showMontage(faStd);
%  mdStd(mdStd>0.3)=0.3;
%  showMontage(mdStd);
%  showMontage(pddDisp/pi*180);
%  inds = find(mask);
%  figure;scatter(fa(inds),pddDisp(inds)/pi*180,1);
%  xlabel('FA'); ylabel('PDD dispersion (deg)');
% 
% % Add some permutations (Residual)
%  permutations = dtiBootGetPermutations(length(bvals),300,0);
%  tic;[dt,pdd,mdStd,faStd,pddDisp] = dtiFitTensor(d,X,0,permutations,mask); toc
%  b0=exp(dt(:,:,:,1)); b0=mrAnatHistogramClip(b0,0.4,0.99);
%  showMontage(b0);
%  [fa,md] = dtiComputeFA(dt(:,:,:,2:7));
%  md(md>5) = 5; md(md<0) = 0;
%  showMontage(fa);
%  showMontage(md);
%  showMontage(faStd);
%  mdStd(mdStd>0.3)=0.3;
%  showMontage(mdStd);
%  showMontage(pddDisp/pi*180);
%  inds = find(mask);
%  figure;scatter(fa(inds),pddDisp(inds)/pi*180,1);
%  xlabel('FA'); ylabel('PDD dispersion (deg)');
% 

disp('We are now using dtiRawFitTensor, not this function');
error([mfilename ' must be compiled! Type "help ' mfilename '" for instructions on compiling this function.']);

return
