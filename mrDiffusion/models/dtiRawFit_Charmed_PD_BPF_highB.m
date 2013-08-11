function dt6FileName = dtiRawFit_Charmed_PD_BPF_highB(dwRaw, bvecs, bvals, outBaseName, bs, fitMethod, adcUnits, xformToAcPc,ROICLmask,BPF,Gmcc,Wmcc,Cmcc,dt6_path)
%
%dt7 = dtiRawFitCharmedwithPDBPF(S_Raw, S_Bvecs, S_Bvals, name, [], 'charmed',[],[],ROICLmask,BPF,G,W,C)%charmed
% dt6FileName = dtiRawFitTensor([dwRaw=uigetfile],
% [bvecsFile=uigetfile], [bvalsFile=uigetfile], [outBaseDir=uigetdir],
% [bootstrapParams=[]], [fitMethod='ls'],
% [adcUnits=dtiGuessAdcUnits], [xformToAcPc=dwRaw.qto_xyz])
%
% Fits a tensor to the raw DW data. The tensors are returned (in [Dxx Dyy
% Dzz Dxy Dxz Dyz] format) and are saved in a dt6 file outBaseName 'dt6.mat'.
%
% If adcUnits is not provided, we'll try to guess based on the magnitude
% of the mean diffusivity. This guess is based on typical values for
% in-vivo human brain tissue. Our preferred units are 'micron^2/msec',
% because they produce very human-friendly numbers (eg. free diffusion of
% water is 3 micron^2/msec). Your adcUnits are determined by the units in
% which your bvals are specified. (adcUnits = 1/bvalUnits) For our GE
% Bammer/Hedehus DTI sequence, the native bvalUnits are sec/mm^2. However,
% we usually divide the bval by 1000, producing msec/micrometer^2 units.
%
% You can also specify a bootstrap to estimate tensor fit uncertainty.
% To skip the bootstrap, make bootstrapParams empty (or specify n=1
% bootstrap samples). bootstrapParams is a struct  with the following
% fields:
%
%   n: number of bootstrap samples. [] or 1 will trigger no bootstrap.
%      We've found that 200-300 gives a good variance estimate, but 500 is
%      probably better.
%
%   nVolsPerRepeat: each bootstrap sample is a permuted dataset. In order
%      to permute the original data in a reasonable way (ie. preserving the
%      # of unique directions and the # of non-DWIs), we need to know the
%      repetion pattern in the input data. For now, we assume that the data
%      are arranged such that the measurements for each repeat are
%      contiguous and that the order of the direction measurements is the
%      same across all the repeats. In that case, one number can specify
%      the approriate pattern for generating the bootstrap permutations.
%      nVolsPerRepeat specifies the number of image volumes to expect per
%      repeat. E.g., if you make 13 measurements per repeat (12 DWIs + 1
%      non DWI), nVolsPerRepeat = 13. Note that the code below will try to
%      deal gracefully with incomplete data for the last repeat.
%
% ===OR===
%
%   permuteMatrix: a cell-array with one entry for each measurement (ie.
%   N = length(permuteMatrix) = size(dwRaw,4). Each entry of this cell
%   array is a 1-d array of indices into the N dwRaw volumes that are
%   valid bootstrap samples of the corresponding volume. E.g:
%      bv = [dlmread(bvecsFile).*repmat(dlmread(bvalsFile),[3 1])];
%      bs.permuteMatrix = {};
%      for(ii=1:size(bv,2))
%         dist1 = sqrt((bv(1,:)-bv(1,ii)).^2+(bv(2,:)-bv(2,ii)).^2+(bv(3,:)-bv(3,ii)).^2);
%         dist2 = sqrt((bv(1,:)+bv(1,ii)).^2+(bv(2,:)+bv(2,ii)).^2+(bv(3,:)+bv(3,ii)).^2);
%         bs.permuteMatrix{ii} = unique([find(dist1<1e-3) find(dist2<1e-3)]);
%      end
%
%   maxMem: The bootstrap tensor fits can go much faster is we do them in
%      large chunks, but not so large that we cause Matlab to use swap
%      space or run out of memory altogether. So set maxMem (specified in
%      either bytes or Gigabytes) to about 80% of the physical RAM that you
%      have available. (defaults to 1GB)
%
%   showProgress: if true, a progress bar will be shown. (defaults to true)
%
% Currently, specifying the bootstrap cases the resulting dt6 file to have
% the following additional variables:
%
%   faStd, mdStd: standard deviations on fa and mean diffusivity.
%
%   pddDisp: dispersion of PDD axes (based on the Watson) in degrees of
%   angle (54 deg is maximum dispersion).
%
%
% fitMethod: the tensor fitting method.
%   'ls': least-squares (default)
%   'me': maximum-entropy method (Dima Kuzmin and Manfred Warmuth, UCSC)
%   'rt': RESTORE robust tensor fitting and outlier rejection:
%         Chang, Jones & Pierpaoli (2005). RESTORE: Robust Estimation of
%         Tensors by Outlier Rejection. Magnetic Resonance in Medicine, v53.
%
% Note that the RESTORE implementation is experimental and needs more
% testing. Also, don't do a bootstrap with RESTORE- that doesn't work yet.
%
% E.g.:
% f = 'raw/dti_g13_b800_aligned.'; out = 'dti06rt';
% dtiRawFitTensor([f 'nii.gz'], [f 'bvecs'], [f 'bvals'], out, [], 'rt');
% % Show outlier count as an overlay on the b0:
% aNi = niftiRead(fullfile(out,'bin','b0.nii.gz'));
% oNi = niftiRead(fullfile(out,'bin','outliers.nii.gz'));
% aIm = mrAnatHistogramClip(double(aNi.data),0.4,0.98);
% oIm = double(sum(oNi.data,4));
% mrAnatOverlayMontage(oIm, oNi.qto_xyz, aIm, aNi.qto_xyz, autumn(256), [1 10], [-34:2:62],[],3,1,false);
%
% TODO:
%
% * add more statistics to bootstrap. We should fit an assymetric
% distribution to the PDD pdf, like the Bingham. Also, we should do
% ksdensity on fa and md and save out a more complete description of the
% PDFs, as they are not well-fit by the normal assumption implicit in the
% standard deviation.
%
% HISTORY:
%
% 2007.03.20 RFD: wrote it.
% 2007.05.30 RFD: added bootstrap option
% 2007.06.02 RFD: cleaned and documented bootstrap code. Seems to work well
% now.
% 2007.06.08 RFD: now save in the new all-NIFTI format. THe dt6 file is now
% just a 'project' file with some notes and the filenames of the actual
% data files.
% 2007.06.14 RFD: NIFTI tensor files weren't respecting the NIFTI-1 spec.
% This is now fixed and the tensor elements are stored in lower-triangular,
% row-wise order (Dxx Dxy Dyy Dxz Dyz Dzz).
% 2007.07.20 AJS: Relative fileanames to the parent directory.
% 2008.09.03 DY & RFD: Implemented 'rt' fitMethod (RESTORE)
% 2008.12.16 DY: Forced useParfor (parallel processing flag) to be false,
% as it seems not to be functional (on Bob's recommendation)
% 2008.12.18 DY & AL: Create summary image of outliers.nii.gz that can be viewed as an image
% when loaded into DTIfiberUI.
% if(license('checkout','distrib_computing_toolbox'))
%     useParfor = true;
% else
%useParfor = false;
% end

if(~exist('dwRaw','var')||isempty(dwRaw))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
    if(isnumeric(f)), error('User cancelled.'); end
    dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    [dataDir,inBaseName] = fileparts(dwRaw);
else
    [dataDir,inBaseName] = fileparts(dwRaw.fname);
end
[junk,inBaseName] = fileparts(inBaseName);
if(isempty(dataDir)), dataDir = pwd; end

if(~exist('bvecs','var')||isempty(bvecs))
    bvecs = fullfile(dataDir,[inBaseName '.bvecs']);
    [f,p] = uigetfile({'*.bvecs';'*.*'},'Select the bvecs file...',bvecs);
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvecs = fullfile(p,f);
end
if(~exist('bvals','var')||isempty(bvals))
    bvals = fullfile(dataDir,[inBaseName '.bvals']);
    [f,p] = uigetfile({'*.bvals';'*.*'},'Select the bvals file...',bvals);
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvals = fullfile(p,f);
end
if(~exist('outBaseName','var')||isempty(outBaseName))
    if(nargout==0)
        outBaseName = fullfile(dataDir,inBaseName);
    else
        outBaseName = [];
    end
end
if(~exist('adcUnits','var'))
    adcUnits = '';
end
if(isempty(outBaseName))
    outBaseName = uigetdir(inBaseName,'Select a directory for the data...');
    if(isnumeric(outBaseName)), disp('User canceled.'); return; end
end
dt6FileName = fullfile(outBaseName, 'dt6.mat');
binDirName = fullfile(outBaseName, 'bin');
if(exist(outBaseName,'dir'))
    if(exist(dt6FileName,'file')||(exist(binDirName,'dir')&&~isempty(dir(fullfile(binDirName,'*.nii*')))))
        q = ['Output dir ' outBaseName ' exists and appears to contain data. Are you sure that you want to overwrite the data files in there?'];
        resp = questdlg(q,'Confirm Overwrite','Yes','Cancel','Cancel');
        if(strcmp(resp,'Cancel')), disp('canceled.'); return; end
        %error(['Output dir ' outBaseName ' exists and appears to contain data- please move it out of the way.']);
        %outBaseName = uigetdir('Select directory for output...',dt6FileName);
        %if(isnumeric(f)), disp('User canceled.'); return; end
        %dt6FileName = fullfile(p,f);
        %[p,f] = fileparts(dt6FileName);
        %binDirName = fullfile(p,f);
    end
end
disp(['data will be saved to ' outBaseName '.']);

if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
    weLoadedRaw = true;
else
    weLoadedRaw = false;
end

nvols = size(dwRaw.data,4);
if(~exist('xformToAcPc','var')||isempty(xformToAcPc))
    xformToAcPc = dwRaw.qto_xyz;
end

if(~exist('bs','var')||isempty(bs))
    bs.n = 1;
    bs.nVolsPerRepeat = 1;
    % 1 GByte = 2^30
    bs.maxMem = 4*2^30;
    bs.showProgress = false;
else
    if(~isfield(bs,'maxMem')), bs.maxMem = 1*2^30;
    elseif(bs.maxMem<100), bs.maxMem = bs.maxMem*2^30; end
    if(~isfield(bs,'showProgress')), bs.showProgress = true; end
end

if(~exist('fitMethod','var')||isempty(fitMethod))
    fitMethod = 'ls';
end


%% Load the bvecs & bvals
% NOTE: these are assumed to be specified in image space.
% If bvecs are in scanner space, use dtiReorientBvecs and
% dtiRawReorientBvecs.
if(~isnumeric(bvecs))
    %bvecs = dlmread(bvecs, ' ');
    bvecs = dlmread(bvecs);
end
if(~isnumeric(bvals))
    %bvals = dlmread(bvals, ' ');
    bvals = dlmread(bvals);
end

if(size(bvecs,2)~=nvols || size(bvals,2)~=nvols)
    error(['bvecs/bvals: need one entry for each of the ' num2str(nvols) ' volumes.']);
end

%% Get a brain mask
%
disp('Computing brain mask from average b0...');
dwInds = bvals>0;
b0Ims = double(dwRaw.data(:,:,:,~dwInds));
nz = b0Ims>0;
b0Ims(nz) = log(b0Ims(nz));
b0 = exp(mean(b0Ims,4));
clear b0Ims nz;
b0clip = mrAnatHistogramClip(b0,0.4,0.99);
b0 = int16(round(b0));
% We use a liberal brain mask for deciding which tensors to compute, but a
% more conservative mask will be saved so that that the junk outside the
% brain won't be displayed when we view the data.
liberalBrainMask = dtiCleanImageMask(b0clip>0.1&all(dwRaw.data>0,4),10,1,0.25);
liberalBrainMask(all(dwRaw.data==0,4)) = 0;
brainMask = uint8(dtiCleanImageMask(b0clip>0.25));
% make sure the display-purposes brain mask is a subset of the
% tensor-fitting (liberal) brain mask.

brainMask(~liberalBrainMask) = 0;
if(exist('ROICLmask','var') && ~isempty(ROICLmask))
brainMask(ROICLmask)=3;
brainMask(brainMask~=3)=0;
end;
% brainMask(~ROICLmask) = 0;
% brainMask(find(brainMask))=0;
% brainMask(ROICLmask)=1;
clear b0clip badEdgeVox;

%% Reorganize the data to make computations easier
numVols = size(dwRaw.data,4);
brainInds = find(liberalBrainMask);
mask=liberalBrainMask;
if(exist('ROICLmask','var') && ~isempty(ROICLmask))
brainInds = find(brainMask);
mask=brainMask;
end;

data = zeros(numVols,1,length(brainInds));
for(ii=1:numVols)
    tmp = double(dwRaw.data(:,:,:,ii));
    data(ii,1,:) = tmp(brainInds);
end

%% Compute signal noise estimate
%
% According to Henkelman (), the expected signal variance (sigma) can be computed as
% 1.5267 * SD of the background (thermal) noise.
sz = size(dwRaw.data);
x = 10;
y = 10;
z = round(sz(3)/2);
[x,y,z,s] = ndgrid(x-5:x+5,y-5:y:5,z-5:z+5,1:sz(4));
noiseInds = sub2ind(sz,x(:),y(:),z(:),s(:));
sigma = 1.5267 * std(double(dwRaw.data(noiseInds)));

% Memory usage is tight- if we loaded the raw data, clear it now since
% we've made the reorganized copy that we'll use for all subsequent ops.
if(weLoadedRaw), clear dwRaw; end
clear liberalBrainMask;
% Voxels with intensity exactly==0 sometimes occur by chance (usually in a
% artifact region, like a blood vessel) or as a result of eddy/motion
% correction and interpolation. They are a problem because fitting the
% tensor involves taking the log(intensity).
minVal = min(data(data(:)>0));
data(data==0) = minVal;

%% Fit the tensor maps.
%brainMask(~ROICLmask) = 0;


nvox = size(data,3);
% Start with q, which will have a row for each volume, each row having
% three elements: [bvx bvy bvz].
%
% Each row of X corresponds to a DW direction for that volume of the form:
% [1, -b bvx bvx, -b bvy bvy, -b bvz bvz, -2b bvx bvy, -2b bvx bvz, -2b bvy bvz].
%
% The last six values in each row of X: [-bx^2 -by^2 -bz^2 -2bxy -2bxz
% -2byz] are equivalent to equation 1 on p.457 of Basser et al, 2002, NMR
% in Biomedicine. They are the six unique values in the symmetric b-matrix.
%
% Our goal is to use the raw data from each DWI (from dwRaw.data, stored in
% the matlab workspace currently as data) and its corresponding b-matrix
% (currently computed to be X in the matlab workspace) to estimate D using
% multivariate linear regression.

q = (bvecs.*sqrt(repmat(bvals,3,1)))';
X = [ones(numVols,1) -q(:,1).^2 -q(:,2).^2 -q(:,3).^2 -2.*q(:,1).*q(:,2) -2.*q(:,1).*q(:,3) -2.*q(:,2).*q(:,3)];
gof = [];
outliers = [];
switch fitMethod


    case 'charmed'
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% GET THE Gradient and change there cordinate to speric +innitiate the relevabt Paramer %%%
        g = 42576.0; % kHz/T = (cycles/millisecond)/T
        Par.delta = 41.124;%17.2; % msec (23.1 w/ 40mT = b=1.0), 33.6 for bvals up to 3
        maxG = 50;
        % We need to get the gradient amplitudes that we actually used when
        % scanning. To compute these, we used the default (assumed) value
        % of delta:
        [grads, maxB] = dtiGradsBuildCharmed([], [], [], 0);
        % [grads, maxB, Par.delta, Par.Delta] = dtiGradsBuildCharmed([], [], Par.delta, 0);
        % But we also need the properly-computed Delta
        Par.Delta = maxB/((2*pi*g).^2 * (maxG*1e-9).^2 * Par.delta.^2) + Par.delta/3;
        G = grads*maxG;
        % T/micrometer * cycles/msec/T * msec = cycles/micrometer
        q =  G*1e-9 * g * Par.delta;


        [Q(:,1),Q(:,2) Q(:,3)] =cart2sph(q(1,:)',q(2,:)',q(3,:)');

       % Q(:,1:2)=pi/2-Q(:,1:2);%change tocharmed article convetion

        % Compute the actual bvals
        norm_q = sqrt(sum(q.^2,1));
        bvals = (norm_q.*2*pi).^2*(Par.Delta-Par.delta/3);
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% for intiation of some of the fitted parameterswe need to fit the low B value diffution data %%%

BV=unique(sort(bvals));

        normal_b=find(bvals<BV(2)*1.1); % find the law bvals this is the b0 and the secound bvalue as some time there is small digit difference i take all the bval above 10% of the secound bval.
numBV_Vols=length(normal_b);
     q1 = (bvecs(:,normal_b).*sqrt(repmat(bvals(normal_b),3,1)))';
        X1 = [ones(numBV_Vols,1) -q1(:,1).^2 -q1(:,2).^2 -q1(:,3).^2 -2.*q1(:,1).*q1(:,2) -2.*q1(:,1).*q1(:,3) -2.*q1(:,2).*q1(:,3)];
      
                data1=data(normal_b,:,:);
         Xinv = pinv(X1);
        % The dt values are simply log(data)*Xinv
        % Avoid log of zero warning:
        nz = data1>0;
        data1(nz) = log(data1(nz));
        clear nz;
        A = ndfun('mult', Xinv, data1);

        
        clear logData;
        %calculate the Tensor for the low b values
        [eigVec,eigVal] = dtiEig(squeeze(A(2:7,1,:))');
        l1 = eigVal(:,1);
        l2 = eigVal(:,2);
        l3 = eigVal(:,3);
        %find the orintation of the firist eigVal and change its cordinate to
        %speric
        eig_L1(:,:)=eigVec(:,[1 2 3],1);
        [Q0(:,1),Q0(:,2) Q0(:,3)] =cart2sph(eig_L1(:,1),eig_L1(:,2),eig_L1(:,3));%
        %Q0(:,1:2)=pi/2-Q0(:,1:2); %change tocharmed article convetion

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%% Initiate the fitted parameters  

        %the ftted paramters:
        %         theta_H=x(1);  %the  orientation of the hindererd component  from the qradients pitch from z axis
        %         phi_H=x(2);      %the  orientation of the hindererd
        %                           component  from the qradients
        %                       rotation in x-y plane see Assaf et al MRM 2004 p 977-8
        %         f_h=x(3);     the hidered component
        %         Lh_par=x(4);  the parallel Diffusion coefficient in the hindererd component
        %         Lh_per=x(5);  the ratio of the perpendicular ADC to the parallel ADC
        %                       in the hindered component to that of the x(5)=Lh_par/Lh_per;
        %         Dr_par=x(6);  the parallel Diffusion coefficient in the restricted component
        %         N=x(7);       %the noise floor
        %         theta_R=x(8);    %the cylinder orientation in it the diff is
        %                        restricted:pitch from z axis
        %         phi_R=x(9);     %the cylinder orientation in it the diff is restricted:
        %                       rotation in x-y plane see Assaf et al MRM 2004 p 977-8
        
        
        
        options = optimset('LargeScale','on','LevenbergMarquardt','on', 'Display', 'off', 'MaxIter', 100);
        %options = optimset('Display', 'off', 'MaxIter', 100);

        lb=[-10*pi -10*pi   1e-6  1e-6  1e-6  1e-6  1e-6 -10*pi -10*pi ]; %low bondery
        ub=[10*pi   10*pi    1     3     1     3    0.5   10*pi  10*pi ]; %up bondery



        dwInds = bvals>0;
        B0 = mean(data(~dwInds,:),1);
        Dw = data(dwInds,:);
        Par.Q=Q(dwInds,:);
        Par.Dr_per=1; % the restricted perpedicular diffusion coefficient this is a case
        Par.R=0.5;    % the radius of the restricted cilinder. this is a case
        Par.tau=119.4/2; %TE/2 from the charmed data heder file
%         if check==1;
%             %try it on ii=35576 this a CC voxcel
%         normal_b1=find(bvals<BV(2)*1.1 & bvals>0);
%         Dw = data(normal_b1,:);
%         Par.Q=Q(normal_b1,:);
%         end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%fit by charmed model%%%%%
        for(ii=1:nvox)
            raw=Dw(:,ii)/B0(ii);
            
            x0(1:2)=Q0(ii,1:2); %the orientation of the low b val eigVec1
            x0(8:9)=Q0(ii,1:2); %the orientation of the low b val eigVec1

            x0(3)=0.5;%  this is a case: just the center
            x0(4)=l1(ii);%D// lh_par
            x0(5)=mean([l2(ii) l3(ii)])/l1(ii);%Lh_par/Lh_per  --> Lh_per=x4*x5;
            x0(6)=2; %Dr_par of axon
            x0(7)=0.03; % this is a case from yaniv data
%              if check==1;
%        raw1=data(normal_b1,ii)/B0(ii); x0(3)=1;
%         Charmed_err(x0,raw1,Par)
%              end;
            [x1, resnorm] = lsqnonlin(@(x) Charmed_err(x,raw,Par),x0,lb,ub,options);

            x_1(:,ii)=x1;
            resnorm1(ii)=resnorm;
        end;

        res.x=x_1;
        res.resnorm=resnorm1;
        res.Par=Par;
        res.lb=lb;
        res.lb=ub;
        res.l0w_b_dif=A;
        res.brainMask=mask;
        res.brainInds=brainInds;
         save(outBaseName,'res')
      %  save(outBaseName,'x_1','resnorm1','A')
        fprintf('finish charmed fit and save it');

        return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
    case 'charmed_fitR'
        fprintf('Fitting %d Charmed model (SLOW!)...\n',nvox);

        %in order to get delta do that in a unix shell

        % dicomDumpHeader raw/dwi_g354_b10000_I0002.dcm
        % Stikov^Nikola  (M , 030Y): Date 20090519 Exam 1989, Series 5 , Image 2
        % 28 slices in series, Location: -6.411901474 (-8.4119  to 45.5881 )
        % (DWI CVs) b-value=10000, dwepi=354, diffusionGradDur=41124

        %[grads, maxB,delta,Delta] = dtiGradsBuildCharmed(maxG, Delta,delta,interact)
        %this is thecode we used to genarate the sequnse
        [grads, maxB,delta,Delta] = dtiGradsBuildCharmed([], [], delta,0);
        % maxG = 50.0; % mT/m * 1e-3/1e+6 = 1e-9
        % % For an optimized DTI sequence, we can get an effective G of srt(2)*maxG:
        % G = sqrt(2)*maxG;
        %bval = (2.*pi.*g).^2 * (G.*1e-9).^2 .* delta.^2 .* (Delta-delta./3)
        % bval = .8; % msec/micrometer^2 (8000 sec/mm^2 / 1000)
        % Delta = bval/((2*pi*g).^2 * (G*1e-9).^2 * delta.^2) + delta/3;
        %Delta=43.7;
        Del=(Delta-(delta/3));
        maxG = 50;
        G = grads*maxG;
        q =  G *1e-9 * g * delta;%  G*1e-9 -> T/m  g ->(cycles/millisecond)/T delta -> millisecond   q --> cycles
        % Check to make sure we computed q properly:
        %norm_q = sqrt(sum(q.^2,1))
        % b = (norm_q.*2*pi).^2*Del;
        % normB = sqrt(sum(b.^2,1))
        %

        Par(2)=4*pi^2;
        Par(3)=-Par(2)*Del; %need to check that this number is problematic!!!! what was it in the lowB Val?

        Par(1)=Delta;
        Par(5)=delta;
        Par(6)=Del;

        Dpar=1;
        Par(4)=Dpar;% micrometer^2/msec^2=1e-5 cm^2/sec^2  = micrometer^2/msec^2

        %     Par
        %     1- Delta
        %     2- 4Pi^2
        %     3- 4Pi^2*(Delta-(delta/3)
        %     4- 1=D_par
        %     5- delta
        %     6- (Delta-(delta/3));
        % q1=(bvecs*(G*1e-9)*g*delta*(2*pi))';

        %q1=(bvecs*(G*1e-9)*g*delta)';%*(2*pi))';
        %q units= T/um* cycles/millisecond)/T* ms*1/cycles =1/um
        %note  yaniv theta and phi are just the oposite of matlab so we take
        %them in reveres order. also matlab number running-  pi/2 <theta<pi/2
        %<pi<phi<phi in radians (for yanivs theta and phi- confusing!)
        %yaniv notition for Phi is the angel on the x-y serpase but he mesure
        %it from yaxes and matlab from x. so we must take it from pi/2
        %phi=pi/2-phi also for theta
        %from each phi number  and from theta .
        %q1=q/Delta;



        dwInds = bvals>0;
        B0 = mean(data(~dwInds,:),1);
        Dw = data(dwInds,:);

        %first use the compute one exponent dti with low bval:
        dt = dtiLoadDt6(fullfile(dt6_path,'dt6'));
        for dd=1:6
            dt6=squeeze(dt.dt6(:,:,:,dd));
            dtroi(dd,:)=dt6(ROICLmask);
        end;

        [eigVec,eigVal] = dtiEig(dtroi');
        [fa,md,rd] = dtiComputeFA(eigVal);
        l1 = eigVal(:,1);
        l2 = eigVal(:,2);
        l3 = eigVal(:,3);
        eig_L1(:,:)=eigVec(:,[1 2 3],1);
        %gof = zeros(1,nvox,'int16');


        lb=[.9  .1  .8  1e-6  1e-6]; %low bondery
        ub=[ 2   1   2  3     2]; %up bondery
        %  L1  L2/L1 L1ax a     b
        %Par(4)=Dpar*Del;

        options =  optimset('LevenbergMarquardt','on');
        
            % First compute the linear inversion matrix X^-1. This is
            % equivalent to the [-(1/b)] in the central DTI equation:
            % D = -(1/b) * log(S1/S0) (cf, Cercignani 2001; Basser 2002)
            % A = Xinv * log(data) : how we will represent it here
            %         Xinv = pinv(X);
            %         % To avoid log of zero warning:
            %         nz = data>0; logData = data; logData(nz) = log(data(nz));
            %         clear nz; % To avoid running out of memory.
            %         % Multiply Xinv * logData for each "page" or 2D matrix in a stack
            %         % (with numVoxels = number of "pages"). Each multiplication
            %         % involves Xinv (7 x nVols) * logData (nVols x 1)
            %         A = ndfun('mult', Xinv, logData); % Ainit = 7 x 1 x nVoxels
            % %         l=size(A);
            % %         A(l(1)+1,:,:)=1;
            %         normal_Tensor=A;
            %         [eigVec,eigVal] = dtiEig(squeeze(A(2:7,1,:))');
            %
            %         eig_L1(:,:)=eigVec(:,[1 2 3],1);
            %         l1 = eigVal(:,1);
            %         l2 = eigVal(:,2);
            %         l3 = eigVal(:,3);
            % Ainit = initial linear fit of seven
            % diffusion parameters for each voxel (6 directions + b0)
            %clear logData;
            %options = optimset('LargeScale','on','LevenbergMarquardt','on', 'Display', 'off', 'MaxIter', 50);
            %options = optimset('Display', 'off', 'MaxIter', 100);
            sigmaSq = sigma.^2;
            offset = 1e-6;

            %the matlab and charmed convention are opposing so we need to fix it.
            %first the use the opposit leter and then the mesure it in 90 degree
            %diference.
            [Q(:,1),Q(:,2) Q(:,3)] =cart2sph(q(1,:)',q(2,:)',q(3,:)');
            [Q0(:,1),Q0(:,2) Q0(:,3)] =cart2sph(eig_L1(:,1),eig_L1(:,2),eig_L1(:,3));%
            Q(:,1:2)=pi/2-Q(:,1:2);
            Q0(:,1:2)=pi/2-Q0(:,1:2);

            % we do this calculation ones as we assume that in the CC the angel is
            % fitted good.

            for j=1:length(Q0)

                Qper2(:,j)=Q(:,3).^2.*(1-(sin(Q(:,1)).*sin(Q0(j,1)).*cos(Q(:,2)-Q0(j,2))+cos(Q(:,1)).*cos(Q0(j,1))).^2);%Q+

                Qpar2(:,j)=Q(:,3).^2.*(sin(Q(:,1)).*sin(Q0(j,1)).*cos(Q(:,2)-Q0(j,2))+cos(Q(:,1)).*cos(Q0(j,1))).^2;
            end;
            %[Q1(:,2),Q1(:,1) Q1(:,3)] =cart2sph(q1(:,1),q1(:,2),q1(:,3));
            %     [THETA(:,1),PHI(:,1),R(:,1)] =cart2sph(q1(:,1),q1(:,2),q1(:,3));
            %
            %     Y_THETA(:,1)=pi/2-PHI(:,1);
            %     Y_PHI=(:,1)=pi/2-THETA(:,1);
            %
            % QRD2=Q(1,3)^2.*(1-(sin(Y_THETA(:,1)).*sin(x(1)).*cos(Y_PHI(:,2)-x(2))+cos(Y_THETA(:,1)).*cos(x(1))).^2);%Q+
            %
            % QLong2=Q(1,3)^2.*(sin(Y_THETA(:,1)).*sin(x(1)).*cos(Y_PHI(:,2)-x(2))+cos(Y_THETA(:,1)).*cos(x(1))).^2;%Q+
            %        Q(1,3)^2.*(sin(Q(:,1)).*sin(x(1)).*cos(Q(:,2)-x(2))+cos(Q(:,1)).*cos(x(1))).^2;%Q//



            % lb=ones(1,6)*offset ;
            % lb(3)=0.01;
            % lb(4)=0.01;
            % lb(5)=Par(4)*.1;
            % lb(6)=0.1;


            lb=[.9  .1  .8  1e-6  1e-6]; %low bondery
            ub=[ 2   1   2  3     2]; %up bondery
            %  L1  L2/L1 L1ax a     b
            %Par(4)=Dpar*Del;

            options =  optimset('LevenbergMarquardt','on');
            for(ii=1:nvox)
                raw=Dw(:,ii)/B0(ii);
                %[x0(2),x0(1)] =cart2sph(eig_L1(ii,1),eig_L1(ii,2),eig_L1(ii,3));%eigVecl1(vox(1),vox(2),vox(3),[1 2 3],1))%,....)
                %x0(1)=pi/2-x0(1);
                %x0(3)=pi/2-x0(3);
                x0(1)=l1(ii);%L// L_par
                x0(2)=mean([l2(ii) l3(ii)])/l1(ii);%L_par/L_per  --> Lper=x2*x1;
                x0(3)=2; %L_par of axon
                x0(4)=1; %alfa of gamma
                x0(5)=1; %beta of gamma
                %Par(1)=Fr(ii);

                if Wmcc(ii)>0;

                    %[x1, resnorm] = lsqnonlin(@(x) dtiRawCharmed_PD_BPD_Err(x,raw,Par,Qper2(dwInds,ii),Qpar2(dwInds,ii),Cmcc(ii),Wmcc(ii),Gmcc(ii),BPF(ii)),x0,lb,ub,options);
                    %[x1, resnorm] = lsqnonlin(@(x) dtiRawCharmed_PD_B_Err(x,raw,Par,Qper2(dwInds,ii),Qpar2(dwInds,ii),Cmcc(ii),BPF(ii)),x0,lb,ub,options);
                    [x1, resnorm] = lsqnonlin(@(x2) dtiRawCharmed_PD_Err(x2,raw,Dw(:,ii),B0(ii),Par,Qper2(dwInds,ii),Qpar2(dwInds,ii),Cmcc(ii),Wmcc(ii),Gmcc(ii)),x0,lb,ub,options);
                    Charmed_test_Education(x0,raw,Dw(:,ii),B0(ii),Par,Qper2(dwInds,ii),Qpar2(dwInds,ii),Cmcc(ii),Wmcc(ii),Gmcc(ii),Q(dwInds,:),Q0(ii,:),eig_L1(ii,:))
                    x_1(:,ii)=x1;
                    resnorm1(ii)=resnorm;
                end;
                %    [x(i,k,1:6),resnorm(i,k)] = lsqnonlin(@Charmedfun,x0,lb,ub,options) ;
            end;
            aMap=zeros(size(brainMask));
            bMap=zeros(size(brainMask));
            fitMap=zeros(size(brainMask));

            aMap(ROICLmask)=x_1(4,:);
            bMap(ROICLmask)=x_1(5,:);
            fitMap(ROICLmask)=resnorm1(:);

            save(outBaseName,'aMap','bMap','fitMap');
            % Par(1)=Fr(ii);
            return;
            % Par(2)=;4*pi^2;
            % Par(3)=-Par(2)*Del;
            %Par(4)=Dper;

            %x(1)=THETA
            % x(2)=PHI
            % x(3)=lpar
            % x(4)=lper
            % x(5)=Dpar
            % x(6)=R

        ;
            otherwise,
                error('unknown tensor fitting method "%s".',fitMethod);
        end

        if(bs.n>1)
            % the data use nvox*numVols doubles and each output uses nvox
            maxMemForStrides = bs.maxMem-(nvox*numVols+4*nvox)*8;
            % Xinv uses 7*numVols*bs.n doubles (8 bytes/dbl)
            % tmp uses 1*numVols*bs.n (=8*numVols*bs.n)
            % the resulting tensor fits use another 7*bs.n
            % We also allow for ~ 25% overhead per stride.
            stride = floor(maxMemForStrides./((8*numVols*bs.n+7*bs.n)*8*1.25));
            tic;
            fprintf('Running %d bootstrap samples on %d voxels (i.e. fitting %0.1f million tensors)- this may take a while!\n',bs.n,nvox,bs.n*nvox/1e6);
            % For the bootstrap, we set up a 3d Xinv matrix and then for each
            % voxel, solve for all the bootstrap tensor-fits at once using ndfun.
            if(isfield(bs,'permuteMatrix'))
                sampInds = zeros(numVols,bs.n);
                for(ii=1:numVols)
                    sampInds(ii,:) = bs.permuteMatrix{ii}(ceil(length(bs.permuteMatrix{ii}).*rand(1,bs.n)));
                end
            else
                % FIXME: allow for partial datasets, where numVols<nVolsPerRepeat*nRepeats.
                nRepeats = ceil(numVols/bs.nVolsPerRepeat);
                % The following will sample (with replacement) such that each repeat is
                % a coherent whole (ie. a full set of directions/bvals). You can check
                % this with mod(sampInds,nVolsPerRepeat).
                sampInds = repmat((1:bs.nVolsPerRepeat)',nRepeats,bs.n)+floor(nRepeats.*rand(bs.nVolsPerRepeat*nRepeats,bs.n))*bs.nVolsPerRepeat;
            end
            bsBvecs = bvecs(:,sampInds(:));
            bsBvals = bvals(sampInds(:));
            q = (bsBvecs.*sqrt(repmat(bsBvals./tau,3,1)))';
            sz = size(q);
            X = [ones(sz(1),1) -tau.*q(:,1).^2 -tau.*q(:,2).^2 -tau.*q(:,3).^2 -2*tau.*q(:,1).*q(:,2) -2*tau.*q(:,1).*q(:,3) -2*tau.*q(:,2).*q(:,3)];
            clear q bsBvals bsBvecs;
            X = permute(reshape(X',[7,numVols,bs.n]),[2 1 3]);
            %Xinv = ndfun('inv',X);
            fprintf('   Inverting %d X matrices...\n',bs.n);
            for(ii=1:size(X,3))
                Xinv(:,:,ii) = pinv(X(:,:,ii));
            end
            clear X;
            % To speed up the following loop, we do several (='stride') voxels per
            % iteration. If we had enough RAM, we could do them all in one go call
            % to ndfun to keep the voxel-loop in the c-code. But, the following
            % more pratical solution is a good compromise for a reasonably fast
            % solution (e.g., under 20 minutes for 500 bootstrap samples on ~200K
            % voxels.) Unfortunately, this optimization makes the following code
            % hard to read...
            Xinv = repmat(Xinv,[1,1,stride]);
            faStd = zeros(1,nvox);
            mdStd = zeros(1,nvox);
            pddDisp = zeros(1,nvox);
            fprintf('   Multiplying log(DWI) by Xinv (%d voxel stride)...\n',stride);
            for(ii=1:stride:nvox)
                sInd = ii; eInd = min(ii+stride-1,nvox);
                n = eInd-sInd+1;
                tmp = reshape(data(sampInds(:),1,sInd:eInd),[numVols,1,bs.n*n]);
                t = ndfun('mult', Xinv(:,:,1:size(tmp,2)), tmp);
                t = squeeze(t(2:7,:,:));
                t = reshape(t,6,bs.n,n);
                % We now have bs.n tensors- use them to estimate tensor fit
                % variances like FA, MD and PDD variance.
                %
                % dtiEig likes the 6 tensor vals to be in the 2nd (or 4th) dim.
                % we'll permute so that the n voxels for this stride are in the
                % first dim and the bs.n are in the 3rd dim.
                %
                % *** WORK HERE- insert better PDD dispersion fitting here (e.g.
                % Bingham distribution)
                [vec,val] = dtiEig(permute(t,[3 1 2]));
                % Convert vec to an Mx3xN array of PDD vectors where N is the
                % bootstrap dim- the dim along which we'll collapse to compute
                % dispersions.
                vec = permute(vec(:,:,1,:),[1 2 4 3]);
                %badVals = any(val<0,2);
                [fa,md] = dtiComputeFA(val);
                faStd(sInd:eInd) = std(fa,0,2);
                %         keyboard;
                %         tic
                %         for(jj=1:size(fa,1))
                %             [pdfY,pdfX] = ksdensity(fa(jj,:),'function','cdf');
                %             xi = interp1(pdfY+rand(size(pdfY))*1e-9,pdfX,[0.025 0.975]);
                %             faLb(sInd+jj-1) = xi(1); faUb(sInd+jj-1) = xi(2);
                %         end
                %         toc
                mdStd(sInd:eInd) = std(md,0,2);
                clear t val;
                [junk,pddDisp(sInd:eInd)] = dtiDirMean(vec);
            end
            clear Xinv tmp vec;
            % Convert dispersion to angle in degrees
            % We get a few values just below zero in edge voxels, so we clip.
            pddDisp(pddDisp<0) = 0;
            pddDisp = asin(sqrt(pddDisp))./pi.*180;
            fprintf('   Elapsed time: %f minutes.\n',toc/60);
            tmp = zeros(size(brainMask));
            tmp(brainInds) = faStd; faStd = tmp;
            tmp(brainInds) = mdStd; mdStd = tmp;
            tmp(brainInds) = pddDisp; pddDisp = tmp;
        else
            faStd = [];
            mdStd = [];
            pddDisp = [];
        end

        tn = tempname;
        disp(['saving temp data to ' tn '...']);
        save(tn);

        % Computing the mean b0 (in log space) is exactly equivalent to pulling the
        % b0 from the model fit (A(1,:,:)). We use the log-mean b0 that we already
        % computed since it saves us a little computation (one less exp) and it has
        % no background voxels masked away.
        %b0 = zeros(size(brainMask));
        %b0(brainInds) = exp(squeeze(A(1,:,:)));
        tmp = zeros(size(brainMask));
        dt6 = zeros([size(brainMask),6]);
        for(ii=1:6)
            tmp(brainInds) = squeeze(A(ii+1,:,:));
            dt6(:,:,:,ii) = tmp;
        end


        %% Check ADC units and adjust if necessary
        %
        if(isempty(adcUnits))
            % Always convert to our standard ADC units (micrometer^2/msec)
            [curUnitStr,scale,adcUnits] = dtiGuessDiffusivityUnits(dt6);
            if(scale~=1)
                fprintf('Converting %s to %s with scale = %f.\n',curUnitStr,adcUnits,scale);
                dt6 = dt6.*scale;
            end
        end

        %% Compute a rough white-matter mask
        %
        [fa,md] = dtiComputeFA(dt6);
        wmMask = brainMask & fa>.15 & (md<1.1 | fa>0.4);
        wmMask = dtiCleanImageMask(wmMask,0,0);

        %% Save all results
        %
        if(~exist(outBaseName,'dir'))
            mkdir(outBaseName);
        end
        if(~exist(binDirName,'dir'))
            mkdir(binDirName);
        end
        params.nBootSamps = bs.n;
        params.buildDate = datestr(now,'yyyy-mm-dd HH:MM');
        l = license('inuse');
        params.buildId = sprintf('%s on Matlab R%s (%s)',l(1).user,version('-release'),computer);
        params.rawDataDir = dataDir;
        % We assume that the raw data file is a directory inside the 'subject'
        % directory.
        params.subDir = fileparts(dataDir);

        % We want all the important file names to be relative so that they are
        % platform-independent. The only platform-dependent path should be
        % 'homeDir'. As long as the dt6 project file stays in the same dir as the
        % bin dir, we shouldn't need 'homeDir' to find everything.
        %
        %  TONY: Every filename now is relative to the directory above the
        %  directory containing this dt6.  Thus we have no system dependent
        %  information.  Just make sure the relative paths stay the same.
        %[files.homeDir,files.binDir] = fileparts(binDirName);
        [fullParentDir, binDir] = fileparts(binDirName);
        [ppBinDir, pBinDir] = fileparts(fullParentDir);
        pBinDir = fullfile(pBinDir,binDir);
        files.b0 = fullfile(pBinDir,'b0.nii.gz');
        files.brainMask = fullfile(pBinDir,'brainMask.nii.gz');
        files.wmMask = fullfile(pBinDir,'wmMask.nii.gz');
        files.tensors = fullfile(pBinDir,'tensors.nii.gz');
        % description can have up to 80 chars
        desc = [params.buildDate ' ' params.buildId];
        if(length(desc)>80), disp('NOTE: description field clipped to 80 chars.'); end
        dtiWriteNiftiWrapper(int16(round(b0)), xformToAcPc, fullfile(ppBinDir,files.b0), 1, desc, 'b0');
        dtiWriteNiftiWrapper(uint8(brainMask), xformToAcPc, fullfile(ppBinDir,files.brainMask), 1, desc, 'brainMask');
        dtiWriteNiftiWrapper(uint8(wmMask), xformToAcPc, fullfile(ppBinDir,files.wmMask), 1, desc, 'whiteMatterMask');
        if(~isempty(gof))
            tmp = zeros(size(brainMask),'int16');
            tmp(brainInds) = gof;
            gof = tmp;
            tmpVol = zeros([size(brainMask),numVols],'uint8');
            tmp = zeros(size(brainMask),'uint8');
            for(ii=1:numVols)
                tmp(brainInds) = outliers(ii,:);
                tmpVol(:,:,:,ii) = tmp;
            end
            outliers = tmpVol;
            files.gof = fullfile(pBinDir,'gof.nii.gz');
            files.outliers = fullfile(pBinDir,'outliers.nii.gz');
            dtiWriteNiftiWrapper(gof, xformToAcPc, fullfile(ppBinDir,files.gof), 1, desc, 'GOF');
            dtiWriteNiftiWrapper(outliers, xformToAcPc, fullfile(ppBinDir,files.outliers), 1, desc, 'outlier mask');
            %Create summary image of outliers.nii.gz that can be viewed as an image
            % when loaded into DTIfiberUI.
            %outlierImage=niftiRead(fullfile(pBinDir,files.outliers));
            outlierImage=niftiRead(files.outliers);
            outlierImage.data=sum(outlierImage.data,4);
            outlierImage.fname = fullfile(ppBinDir,pBinDir,'outlier_sum_image.nii.gz');
            writeFileNifti(outlierImage);
        end
        % NIFTI convention is for the 6 unique tensor elements stored in the 5th
        % dim in lower-triangular, row-order (Dxx Dxy Dyy Dxz Dyz Dzz). NIFTI
        % reserves the 4th dim for time, so in the case of a time-invatiant tensor,
        % we just leave a singleton 4th dim. Our own internal convention is
        % [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz], so we use the code below to convert to
        % the NIFTI order and dt6=squeeze(ni.data(:,:,:,1,[1 3 6 2 4 5])); to get
        % back to our convention. FOr reference- the 3x3 tensor matrix is:
        %    Dxx Dxy Dxz
        %    Dxy Dyy Dyz
        %    Dxz Dyz Dzz
        dt6 = dt6(:,:,:,[1 4 2 5 6 3]);
        sz = size(dt6);
        dt6 = reshape(dt6,[sz(1:3),1,sz(4)]);
        dtiWriteNiftiWrapper(dt6, xformToAcPc, fullfile(ppBinDir,files.tensors), 1, desc, ['DTI ' adcUnits]);
        if(bs.n>1)
            files.faStd = fullfile(pBinDir,'faStd.nii.gz');
            files.mdStd = fullfile(pBinDir,'mdStd.nii.gz');
            files.pddDisp = fullfile(pBinDir,'pddDispersion.nii.gz');
            dtiWriteNiftiWrapper(single(faStd), xformToAcPc, fullfile(ppBinDir,files.faStd), 1, desc, 'FA stdev');
            dtiWriteNiftiWrapper(single(mdStd), xformToAcPc, fullfile(ppBinDir,files.mdStd), 1, desc, 'MD stdev');
            dtiWriteNiftiWrapper(pddDisp, xformToAcPc, fullfile(ppBinDir,files.pddDisp), 1, desc, 'PDD disp (deg)');
        end
        save(dt6FileName,'adcUnits','params','files');
        disp('Finished writing dt6 file--line634 of dtiRawFitTensor');
        if(nargout<1), clear dt6; end

        return;


        % % To run this on a bunch of subjects
        % bd = '/biac3/wandell4/data/reading_longitude/dti_y1234';
        % rf = 'dti_g13_b800_aligned.';
        % of = 'dti06rt';
        % d = dir(fullfile(bd,'*0*'));
        % for(ii=1:numel(d))
        %     sd = fullfile(bd,d(ii).name);
        %     dwRaw = fullfile(sd,'raw',[rf 'nii.gz']);
        %     dwBvc = fullfile(sd,'raw',[rf 'bvecs']);
        %     dwBvl = fullfile(sd,'raw',[rf 'bvals']);
        %     out = fullfile(sd,of);
        %     if(exist(sd,'dir') && exist(dwRaw,'file') && exist(dwBvc,'file') && exist(dwBvl,'file') && ~exist(out,'dir'))
        %         fprintf('Processing %s (%d of %d)...\n',sd,ii,numel(d));
        %         dtiRawFitTensor(dwRaw, dwBvc, dwBvl, out, [], 'rt');
        %     end
        % end


       
