function  er_selxavg(varargin)
% er_selxavg: perform selective averaging analysis on event-related, or
% block-design data.
% (see Greves '99)
%
% er_selxavg(varargin)
%
% This version of selxavg is designed for use with mrLoadRet, and loads
% data in the form of mrLoadRet tSeries.
%
% The format for calling this in general is (using non-functional call, to
% avoid quotes):
%
% er_selxavg [options] -i inputdir -p parfile [repeat for all
% input scans] -o outputdir
%
% inputdir: path to dir containing tSeries from an input scan
%
% parfile: path to .parfile (see readParFile for more info) specifying
% onset conditions for the specified input scan. 
%
% You can specify many scans for input by entering several pairs of -i
% inputdir -p parfile. 
%
% outputdir: directory to save resulting tSeries.
%
% Type 'er_selxavg' without arguments to see a list of options.
%
% This now also works on block-design, as well as event-related, data. The
% main flag for specifying which design is used is the 'gammafit' option.
% This option tells the code to fit a gamma-function HRF as the shape of
% the hemodynamic response. It takes to parameters afterwords, gdelta and
% gtau, which specify the shape of the fitted gamma function. The typical
% settings for these parameters are 1.25 and 2.5, respectively.
%
% If you run this on block-design, rather than deconvolved event-related, scans,
% instead of saving tSeries it saves files named 'hAvg[slice#].mat' in the first
% inputdir directory. The outputdir in this case is ignored.
% These files are the same format as tSeries, but each
% time point represents the mean hemodynamic response during that
% condition. The first slice represents the response during the baseline condition 
% and is generally a bunch of 0's (all changes are measured relative to this baseline).
% The last slice represents the estimated residual variance from the HRF
% fitting.
%
% ras 06/03
fprintf('***** er_selxavg *****\n');

%% Print useage if there are no arguments %%
if (nargin == 0),  print_usage;    return;  end

%% Parse the arguments %%
varargin = unNestCell(varargin); % so you can pass a big cell of options
s = parse_args(varargin);
if (isempty(s)) return; end
s = check_params(s);
if (isempty(s)) return; end

% check if we're deconvolving by checking gammafit -- if we are, change
% where we save to be the same as the first input dir (not making new tSeries
% in mrLoadRet, just calculating single beta vals for each condition and saving 
% in hAvg files):
deconvolving = ~(s.GammaFit > 0); % flag whether we're deconvolving or not
if ~deconvolving
    s.hvol = deblank(s.invollist(1,:));
    s.override = 1;
end

% want to save omnibus contrast (of p-vals from F-test)
% set it as the 2nd-degree parent of the s.hvol --
% (e.g., Inplane/Averages if s.hvol is Inplane/Averages/Tseries/Scan1)
pomnibusstem = fileparts(fileparts(s.hvol)); % s.pomnibusvol;

% Check if output path already exists / has tSeries %
if ~exist(s.hvol,'dir')
    callingdir = pwd;
    [a,b] = fileparts(s.hvol);
    cd(a); mkdir(b);
    cd(callingdir);    disp(s.hvol);
else
    if exist(fullfile(s.hvol,'tSeries1.mat'),'file') & ~s.override
        % warn user and prompt for save-over (unless overridden)
        questionStrings = [{'tSeries already exist in this path:'}; ...
                {''}; {s.hvol}; {''}; ...
                {'Do you want to continue, which will create new tSeries files?'}];
        buttonName = questdlg(questionStrings, 'Warning', 'Yes', 'No', 'No');
        pause(.1);  % Prevent hanging
        if strcmp(buttonName, 'No')
            fprintf('Aborting ... don''t want to save over existing files.\n');
            return
        else
            s.override = 1;
        end    
    end
end

% disabled use of masks -- ras 05/04
mask = [];

%-------------------------------------------------%
nruns = size(s.parlist,1);
Nfir = round(s.TotWin/s.TER);

%-- Determine Number of Conditions across all runs----------%
% Get list of unqiue condition IDs for all runs %
condlist = [];
for run = 1:nruns
    par = fmri_ldpar(deblank(s.parlist(run,:)));
    if (isempty(par))
        fprintf('ERROR: reading parfile %s\n',deblank(s.parlist(run,:)));
        return;
    end
    condid = par(:,2);
    clrun = unique(par(:,2));
    condlist = unique([clrun; condlist]);
end

% Count number per condition
% Remove -1 and 0 %
ind = find(condlist ~= -1 & condlist ~= 0);
condlist = condlist(ind);
Nnnc = length(condlist); % excludes null %
Nc = Nnnc + 1;

fprintf(1,'Conditions Found (%d): ',Nnnc);
fprintf(1,'%2d ',condlist);
fprintf(1,'\n');

if (max(abs(diff(condlist))) > 1)
    fprintf('ERROR: the condition identifiers as found the the paradigm files\n');
    fprintf('       do not appear to be contiguous.\n');
    return;
end


% Check for holes in the list of condition numbers %
if (~isempty(find(diff(condlist)~=1)))
    fprintf(2,'fast_selxavg2: missing conditions\n');
    return;
end

% Count the number per condition %
Npercond= zeros(Nc,1);
for run = 1:nruns
    par = fmri_ldpar(deblank(s.parlist(run,:)));
    npc = [0];
    fprintf(1,'Run %2d: ',run);
    for c = condlist'  %'
        nc = length(find(par(:,2)==c)); 
        npc = [npc nc];
        fprintf(1,'%3d ',nc);
    end
    fprintf(1,'\n');
    Npercond = Npercond + npc'; %'
end

SubSampRate = round(s.TR/s.TER);

% Get basic info from the first run %
instem = deblank(s.invollist(1,:));
[s.nslices nrows ncols ntrs] = er_tvoldim(instem);

%-----------------------------------------------------------------%
%--------------- Beginning of Slice Loop -------------------------%
%-----------------------------------------------------------------%
hWaitbar = mrvWaitbar(0,'selxavg:');
SumESSMtxRun = zeros(ntrs,ntrs,nruns);
NBrainVoxsRun = zeros(nruns);
SumESSMtx = 0;
NBrainVoxsTot = 0;
tic;

for slice = 1:s.nslices
    mrvWaitbar((slice-1)/s.nslices,hWaitbar,sprintf('selxavg: slice %i of %i',slice,s.nslices));
    fprintf(1,'Slice %d, %g --------------\n',slice,toc);
    SumXtX = 0;    SumXtWX = 0;    SumXtWY = 0;    eres_ss = 0;
    Xfinal = [];
    
    for Pass = 1:2
        
        if (slice == 1 | s.debug)
            if (Pass == 1)
                fprintf(1,'  First Pass (Accumulation), %g \n',toc);
            else
                fprintf(1,'  Second Pass (Residual Error Estimation), %g \n',toc);
            end
        end
        
        randn('state',s.SynthSeed); 
        
        if (Pass == 2)
            
            c = cond(SumXtWX);
            if (slice == 1 | s.debug)
                fprintf('    Paradigm Condition: %g\n',c);
            end
            
            if (c > 10000000)
                fprintf('ERROR: paradigm is ill-conditioned (%g).\n',c);
                fprintf('Check your paradigm file for file for periodicities\n');
                fprintf('or for some event types that always follow other\n');
                fprintf('event types (or itself).\n');
                return;
            end
            
            if (slice == 1 | s.debug)
                indtask = 1:size(Xpar,2);
                invSumXtX = inv(SumXtWX);
                d = diag(invSumXtX);
                minvr  = min(1./d(indtask));
                meanvr = mean(1./d(indtask));
                maxvr  = max(1./d(indtask));
                fprintf('    Var Reduction Range: %g %g %g\n',minvr,meanvr,maxvr);
            end
            
            if (slice == 1 | s.debug)
                fprintf(1,'     Computing hhat\n');
            end
            hCovMtx = inv(SumXtWX);
            hhat = hCovMtx * SumXtWY;
        end
        
        %-------------------- Run Loop ------------------------%
        ntrstot = 0;
        ntpxtot = 0;
        for run = 1:nruns
            
            if (slice == 1 | s.debug)
                fprintf(1,'     Run %d/%d, %g \n',run,nruns,toc);
            end
            
            instem = deblank(s.invollist(run,:));
            
            % Get number of TRs in this run %
            [s.nslices nrows ncols ntrs] = er_tvoldim(instem,slice);
            ntrstot = ntrstot + ntrs;
            nvoxs = nrows*ncols;
            
            Xdrift = [];
            if (s.PFOrder < 0)
                % Create Baseline/Trend Components of Convolution Matrix %
                Xbaseline = []; Xtrend = []; Xqtrend  = [];
                if (s.RmBaseline) Xbaseline = fast_baselinemtx(run,ntrs,nruns); end
                if (s.RmTrend)    Xtrend    = fast_trendmtx(run,ntrs,nruns); end
                if (s.QTrendFit)  Xqtrend   = fast_quadtrendmtx(run,ntrs,nruns); end
                Xdrift = [Xbaseline Xtrend Xqtrend];
            else
                Xdrift  = fast_polytrendmtx(run,ntrs,nruns,s.PFOrder);
            end
            
            % Load paradigm for this run %
            par = fmri_ldpar(deblank(s.parlist(run,:)));
            
            % Compute Offset for Slice Timing %
            if (~isempty(s.AcqOrder))
                SliceDelay = fast_slicedelay(s.TR,s.nslices,slice,s.AcqOrder);
            else
                SliceDelay = 0;
            end
            
            % Adjust for Time Offset %
            par(:,1) = par(:,1) + s.TimeOffset;
            
            % Convert paradigm to FIR stimulus convolution matrix %
            Xfir = fmri_par2scm(par, Nc, SubSampRate*ntrs, s.TER, Nfir, s.PreStimWin);
            
            % For Sub-s.TR Estimation %
            if (s.TR ~= s.TER)
                Xfirtmp = Xfir;
                nn = [1:SubSampRate:size(Xfirtmp,1)];
                Xfir = Xfirtmp(nn,:);
            end
            
            % Tranform for Fitting to Gamma Function(s) %
            if (s.GammaFit > 0)
                Xpar = fmri_scm2gcm(Xfir, Nnnc, s.TER, s.PreStimWin, s.gfDelta, s.gfTau);
                Navgs_per_cond = length(s.gfDelta);
            else
                Xpar = Xfir;
                Navgs_per_cond = Nfir;
            end
            
            % Number of averages excluding the offsets and trends
            NTaskAvgs = Nnnc*Navgs_per_cond;
                        
            % Create final Convolution Matrix for ith run %
            Xi = [Xpar Xdrift];
            
            % Load data %
            % Load the data for this slice %
            [nrows ncols ntp fs ns endian bext] = er_tfiledim(instem,slice);
            fname = fullfile(instem,['tSeries' num2str(slice) bext]);
            y = er_ldtfile(fname);
            
            % Reshape to a more convenient form %
            y = reshape(y, [nrows*ncols ntrs])'; %'            
            
            off_est = repmat(mean(y),size(y,1),1);
            
            % High-pass filter: remove low-frequency baseline drift
            % ras, sometime in 2003
            if s.HighPassFilter & ~isempty(y)
                s.HPFPeriod = round(60/s.TR);
                y = removeBaseline2(y,s.HPFPeriod);
                % artificially add offset equal to raw tSeries mean,
                % so that PSC estimate is accurate
                y = y + off_est;
            end      
            
            % Global rescale of functional data %
            if (s.RescaleTarget > 0)
                MeanValFile = fullfile(instem,'fmc.meanval');
                [RescaleFactor MeanVal]=fast_rescalefactor(MeanValFile, s.RescaleTarget);
                y = RescaleFactor * y;
            else
                RescaleFactor = 1;
            end
            
            if (s.loginput) 
                fprintf('INFO: computing log of input\n');
                y = log(abs(y)+2); 
            end
                        
            % ghost whitening matrix (we don't do 
            % whitening, but I don't want to mess up
            % the manipulations below): -ras, 05/04
            WhtnMtx   = eye(ntrs); 
            WhtnMtxSq = eye(ntrs); 
            
            if (Pass == 1)
                % Accumulate XtX and XtWY %
                %fprintf(1,'       Accumulating XtWX and XtWY\n');
                SumXtX  = SumXtX  + Xi'*Xi; %'
                SumXtWX = SumXtWX + Xi'*WhtnMtxSq*Xi; %'
                SumXtWY = SumXtWY + (Xi'*WhtnMtxSq)*y;  %'
                Xfinal = [Xfinal; Xi];
            end
            
            if (Pass == 2)
                sigest = Xi*hhat;  % Compute Signal Estimate %
                
                % Compute Residual Error %
                if (isempty(s.WhtnMtxFile)) 
                    eres = y - sigest; % Unwhitened
                else
                    eres = WhtnMtx*(y - sigest); % Whitened
                end
                
                % Accumulate Sum of Squares of  Residual Error %
                %fprintf(1,'       Accumlating SumSquares Residual Error\n');
                eres_ss = eres_ss + sum(eres.^2);                                
            end
            
            mrvWaitbar(slice/s.nslices,hWaitbar);
            
        end % Loop over runs %
    end % Loop over Pass %
    
    % Total Number of Averages Computed %
    Navgs_tot = size(SumXtX,1);
    
    % Residual Error Forming Matrix 
    R = eye(size(Xfinal,1)) - Xfinal*inv(Xfinal'*Xfinal)*Xfinal'; 
    
    % Total Degrees of Freedom
    DOF = trace(R);
    
    %fprintf(1,'  Computing Residual Error Std\n');
    eres_var = eres_ss/DOF;
    eres_std = sqrt(eres_var);
    
    % -------- Convert to selavg format -------------- %
    hhattmp = hhat(1:NTaskAvgs,:); %Remove offset and baseline 
    hhattmp = [zeros(Navgs_per_cond,nvoxs); hhattmp]; % Add zero for cond 0
    hhattmp2 = reshape(hhattmp,[Navgs_per_cond Nc nvoxs]);
    
    hstd = sqrt( (diag(hCovMtx).*diag(SumXtX)) * eres_std.^2);
    hstdtmp = hstd(1:NTaskAvgs,:); % Remove offset and baseline
    hstdtmp = [repmat(eres_std, [Navgs_per_cond 1]); hstdtmp]; % Add 0 for cond 0
    hstdtmp2 = reshape(hstdtmp,[Navgs_per_cond Nc nvoxs]);
    
    %--- Merge Averages and StdDevs ---%
    tmp = zeros(Navgs_per_cond, 2, Nc, nvoxs);
    tmp(:,1,:,:) = hhattmp2;
    tmp(:,2,:,:) = hstdtmp2;
    tmp = reshape(tmp,[Navgs_per_cond*2*Nc nrows ncols ]);
    tmp = permute(tmp,[2 3 1]);    
       
    if deconvolving
        % by default, selxavg would save the null condition (which
        % is defined by this analysis as being 0) for clarity. Since with a
        % deconvolved time course this is a lot of extra, redundant zeros to
        % store, I remove that information for mrLoadRet. 
        resVar = tmp(:,:,Nfir+1); % residual variance of fitting
        varPath = fullfile(s.hvol, ['resVar' num2str(slice) '.mat']);
        er_svtfile(resVar, varPath, 1);
        
        tmp = tmp(:,:,(2*Nfir)+1:end);
    end
    
    % Save the raw data if selected %
    % (changed name to be (I hope) more clear what's stored)
    if s.saveraw | ~deconvolving 
%         fname = fullfile(s.hvol,sprintf('raw_%03d.mat',slice));
        fname = fullfile(s.hvol,['hAvg' num2str(slice) '.mat']);
        if (slice == 1 | s.debug)   fprintf(1,'  Saving raw data to %s \n',fname);    end    
        er_svtfile(tmp,fname,s.override);
    end
    
    % Save the mean image %
    if s.RmBaseline 
        hoffset = reshape(hhat(NTaskAvgs+1,:), [nrows ncols]); % From 1st Run
        fname = fullfile(s.hvol,sprintf('mean_%03d.mat',slice));
        if (slice == 1 | s.debug)
            fprintf(1,'  Saving offset to %s \n',fname);
        end
        er_svtfile(hoffset,fname,s.override);
    end
    
    % ---- Save Percent Signal Chanage -- now the main output ---- %
    % trying to do something diff't: divide by the mean at each voxel,
    % instead of by the offset (which is the result of a baseline
    % estimator, I believe. ras 07/03). Changed back 09/03
    if deconvolving
        fname = fullfile(s.hvol,['tSeries' num2str(slice) '.mat']);
        tmp = tmp ./ repmat(hoffset, [1 1 size(tmp,3)]);
        if (slice == 1 | s.debug)   fprintf(1,'  Saving %% signal change to %s \n',fname);    end
        er_svtfile(tmp,fname,s.override);
    else
        % we want to save hAvg as the raw value, to be compatible w/ other fs-fast functions.
        % right now the % signal isn't as useful for non-deconvolved data,
        % but may become later. If so, insert a 'er_svtfile' call here.        
    end       
    
    
    % Save in beta format %
    if (~isempty(s.betavol))
        tmp = hhat;
        ntmp = size(tmp,1);
        tmp = reshape(tmp',[nrows ncols ntmp]); %';
        fname = sprintf('%s_%03d.mat',s.betavol,slice);
        er_svtfile(tmp,fname,s.override);
        
        tmp = eres_var;
        ntmp = size(tmp,1);
        tmp = reshape(tmp',[nrows ncols ntmp]); %';
        fname = sprintf('%s-var_%03d.mat',s.betavol,slice);
        er_svtfile(tmp,fname,s.override);
        
        clear tmp;
    end
    
    % Omnibus Significance Test %
    if (~isempty(s.fomnibusvol) | ~isempty(pomnibusstem))
        
        R = eye(NTaskAvgs,Navgs_tot);
        q = R*hhat;
        if (size(q,1) > 1)  qsum = sum(q); % To get a sign %
        else               qsum = q;
        end
        
        if (NTaskAvgs == 1)
            Fnum = inv(R*hCovMtx*R') * (q.^2) ;  %'
        else
            Fnum = sum(q .* (inv(R*hCovMtx*R') * q));  %'
        end
        Fden = NTaskAvgs*(eres_std.^2);
        ind = find(Fden == 0);
        Fden(ind) = 10^10;
        F = sign(qsum) .* Fnum ./ Fden;
        if (~isempty(s.fomnibusvol))
            fname = sprintf('%s_%03d.mat',s.fomnibusvol,slice);
            tmp = reshape(F,[nrows ncols]);
            er_svtfile(tmp,fname,s.override);
        end
        if (~isempty(pomnibusstem))
            if (slice == 1 | s.debug)
                fprintf('INFO: performing er_ftest on omnibus\n');
                fprintf('      NOTE: if this hangs, try running selxavg-sess\n');
                fprintf('      with the -noomnibus flag.\n');
            end
            p = sign(F) .* er_ftest(NTaskAvgs,DOF,abs(F));
            indz = find(p==0);
            p(indz) = 1;
            p = sign(p).*(-log10(abs(p)));
            
            % ras 10/04 -- flat levels -- slices aren't 
            % always the same size; this takes that into account
            if exist('omnibus','var') & (ncols > size(omnibus,2))
                omnibus(end,ncols,slice-1) = 0;
            end
            
            omnibus(1:nrows,1:ncols,slice) = reshape(p,[nrows ncols]);
        end
    end
    
    if (~isempty(s.snrdir))
        p = zeros(Navgs_tot,1);
        p(1:NTaskAvgs) = 1;
        P = diag(p);
        sigvar = sum(hhat .* ((P'*SumXtX*P) * hhat))/(ntrstot);  %'
        
        sigvar = reshape(sigvar,[nrows ncols]);
        fname = sprintf('%s/sigvar_%03d.mat',s.snrdir,slice);
        er_svtfile(sigvar,fname,s.override);
        fname = sprintf('%s/sigstd_%03d.mat',s.snrdir,slice);
        er_svtfile(sqrt(sigvar),fname,s.override);
        
        resvar = reshape(eres_std.^2,[nrows ncols]);
        fname = sprintf('%s/resvar_%03d.mat',s.snrdir,slice);
        er_svtfile(resvar,fname,s.override);
        fname = sprintf('%s/resstd_%03d.mat',s.snrdir,slice);
        er_svtfile(sqrt(resvar),fname,s.override);
        
        ind0 = find(resvar==0);
        resvar(ind0) = 1;
        snrvar = sigvar./resvar;
        snrvar(ind0) = 0;
        fname = sprintf('%s/snrvar_%03d.mat',s.snrdir,slice);
        er_svtfile(snrvar,fname,s.override);
        fname = sprintf('%s/snrstd_%03d.mat',s.snrdir,slice);
        er_svtfile(sqrt(snrvar),fname,s.override);
        
    end
    
end % Loop over slices 
%------------------------------------------------------------%

outvolpath = fileparts(deblank(s.hvol));
xfile = sprintf('%s/X.mat',s.hvol);
pfOrder = s.PFOrder;
nExtReg = 0; if (s.nextreg > 0) nExtReg = s.nextreg; end
tPreStim = s.PreStimWin;
TimeWindow = s.TotWin;
fprintf('INFO: saving meta to %s\n',xfile);
save(xfile,'Xfinal','Nnnc','pfOrder','nExtReg',...
    'nruns','Navgs_per_cond','TimeWindow','tPreStim','s');

%-- Save ECovMtx for each run individually --%
if (s.SaveErrCovMtx) 
    for run = 1:nruns,
        fname = sprintf('%s-ecvm_%03d.mat',s.hvol,run-1);
        tmp = SumESSMtxRun(:,:,run)/NBrainVoxsRun(run);
        er_svtfile(tmp,fname,s.override);
    end
end

% Save ErrCovMtxs across all runs %/
if (~isempty(s.ErrCovMtxStem))
    fprintf(1,'NBrainVoxsTot: %d\n',NBrainVoxsTot);
    fname = sprintf('%s.mat',s.ErrCovMtxStem);
    ErrCovMtx = SumESSMtx/NBrainVoxsTot;
    er_svtfile(ErrCovMtx,fname,s.override);
end

% Save the .dat file %
fname = fullfile(s.hvol,'h.dat');
SumXtXTmp  = SumXtX( 1:NTaskAvgs, 1:NTaskAvgs);
hCovMtxTmp = hCovMtx(1:NTaskAvgs, 1:NTaskAvgs);
hd = fmri_hdrdatstruct;
hd.TR  = s.TR;    
hd.TER = s.TER;
hd.TimeWindow = s.TotWin; 
hd.TPreStim = s.PreStimWin;
hd.Nc = Nc; 
hd.Nh = Navgs_per_cond;
hd.Nnnc = Nnnc; 
hd.DOF= DOF;
hd.Npercond= Npercond;  
hd.Nruns = nruns;
hd.Ntp = ntrstot;   
hd.Nrows = nrows;
hd.Ncols = ncols;   
hd.Nskip = s.nSkip;
if (s.PFOrder < 0)
    hd.DTOrder = s.RmBaseline + s.RmTrend + s.QTrendFit;
else
    hd.DTOrder = s.PFOrder + 1;
end
hd.RescaleFactor = 1.0; 
hd.HanningRadius = 0.0;
hd.BrainAirSeg = 0; 
hd.GammaFit = s.GammaFit;
hd.gfDelta  = s.gfDelta;  
hd.gfTau = s.gfTau;
hd.NullCondId    = 0;
hd.SumXtX        = SumXtXTmp;
hd.nNoiseAC      = 0;
hd.CondIdMap     = [0:Nc-1];
hd.hCovMtx       = hCovMtxTmp;
hd.WhitenFlag    = s.WhitenFlag;
hd.runlist  = getrunlist(s.invollist);  
hd.funcstem      = basename(deblank(s.invollist(1,:)));
hd.parname       = s.parname;
if (~isempty(s.extreglist))
    hd.extregstem  = basename(deblank(s.extreglist(1,:)));
    hd.nextreg  = s.nextreg;
    hd.extortho = s.extregorthog;
end
fmri_svdat3(fname,hd);

if (~isempty(s.pscvol))
    fname = sprintf('%s.dat',s.pscvol);
    fmri_svdat3(fname,hd);
end

% save omnibus contrast as a parameter map
% have to actually figure out the scan nums
if deconvolving
    % save path based on output scan num (s.hvol)
    a = length(s.hvol);
	while ~isempty(str2num(s.hvol(a)))
        a = a - 1;
	end
	scan = str2num(s.hvol(a+1:end));
	fname = sprintf('omnibus_scan%i.mat',scan);
	fname = fullfile(pomnibusstem,fname);
else
    % save path based on input scan nums
    if size(s.invollist,1)==1
        a = length(s.invollist);
        while ~isempty(str2num(s.invollist(1,a)))
            a = a - 1;
        end
        scan = str2num(s.invollist(1,a+1:end));
		fname = sprintf('omnibus_scan%i.mat',scan);
		fname = fullfile(pomnibusstem,fname);
    else
        firstScanPath = deblank(s.invollist(1,:));
        lastScanPath = deblank(s.invollist(end,:));
        a = length(firstScanPath); b = length(lastScanPath); 
        while ~isempty(str2num(s.invollist(1,a)))
            a = a - 1;
        end
        while ~isempty(str2num(s.invollist(end,b)))
            b = b - 1;
        end
        scanA = str2num(s.invollist(1,a+1:end));
        scanB = str2num(s.invollist(end,b+1:end));
		fname = sprintf('omnibus_scans%ito%i.mat',scanA,scanB);
		fname = fullfile(pomnibusstem,fname);
        scan = scanA;
    end
end

map{scan} = omnibus; % this may not be the right length
mapName = 'FtestOmnibus';
fprintf('Saving omnibus to %s ...',fname);
save(fname,'map','mapName');

close(hWaitbar);
fprintf('\n\n\t****** GLM Done. Time: %5.0g min %2.2g sec ******.\n\n',toc/60,mod(toc,60));

return;
%---\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-----%
%----\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-----%
%-----\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-----%


%------------- Print Usage ---------------------%
function print_usage(dummy)

fprintf(1,'USAGE:\n');
fprintf(1,'  er_selxavg\n');
fprintf(1,'     -i   invol ... \n');
fprintf(1,'     -p   parfile ... \n');
fprintf(1,'     -parname  parfile \n');
fprintf(1,'     -extreg   extregfile \n');
fprintf(1,'     -nextreg  number of external regressors to use\n');
fprintf(1,'     -parname  parfile \n');
fprintf(1,'     -tpx tpxfile ... \n');
fprintf(1,'     -whtmtx whitening matrix file \n');
fprintf(1,'     -o   hdrstem \n');
fprintf(1,'     -psc pscstem \n');
fprintf(1,'     -fomnibus stem \n');
fprintf(1,'     -pomnibus stem \n');
fprintf(1,'     -s.TR   s.TR\n');
fprintf(1,'     -s.TER  s.TER\n');
fprintf(1,'     -timewindow totwin  \n');
fprintf(1,'     -prewindow  prewin  \n');
fprintf(1,'     -nobaseline  \n');
fprintf(1,'     -detrend  \n');
fprintf(1,'     -qtrendfit  \n');
fprintf(1,'     -rescale  target \n');
fprintf(1,'     -s.nSkip  n \n');
fprintf(1,'     -hanrad radius \n');
fprintf(1,'     -fwhm   width \n');
fprintf(1,'     -ipr    inplaneres \n');
fprintf(1,'     -gammafit delta tau \n');
fprintf(1,'     -timeoffset t \n');
fprintf(1,'     -acqorder  <linear or interleaved> \n');
fprintf(1,'     -1 sliceno : 0 \n');
fprintf(1,'     -s.nslices    s.nslices : auto \n');
fprintf(1,'     -s.eresdir    dir \n');
fprintf(1,'     -s.sigestdir  dir \n');
fprintf(1,'     -synth      seed \n');
fprintf(1,'     -cfg        file \n');

return
%--------------------------------------------------%

%--------------------------------------------------%
%% Default data structure
function s = sxa_struct
s.invollist      = '';
s.parlist        = '';
s.nruns          = 0;
s.parname        = '';
s.extregfile     = '';
s.extreglist     = '';
s.nextreg        = -1;
s.extregorthog   =  0;
s.tpxlist        = '';
s.WhtnMtxFile     = '';
s.AutoWhiten     = 0;
s.NoAutoWhiten   = 0;
s.SecondPass     = 0;
s.TauMaxWhiten   = 0;
s.NMaxWhiten     = 0;
s.PctWhiten      = 0;
s.LPFFlag        = 0;
s.HPF            = [];
s.WhitenFlag     = 0;
s.maskid         = []; % for whitening only
s.hvol           = '';
s.betavol        = '';
s.fomnibusvol    = '';
s.pomnibusvol    = '';
s.ErrCovMtxStem  = '';
s.SaveErrCovMtx  = 0;
s.pscvol   = ''; % obsolete
s.TR    = '';
s.TER    = '';
s.TotWin      = '';
s.PreStimWin  = 0;
s.PostStimWin = '';
s.SegBrainAir = 1;
s.RmBaseline = 1;
s.RmTrend    = 0;
s.QTrendFit  = 0;
s.HighPassFilter = 0;
s.HPFPeriod = 0;
s.PFOrder    = -1;
s.RescaleTarget = 0;
s.nSkip  = 0;
s.FWHM = 0;
s.InPlaneRes = 0;
s.HanRad = 0;
s.gfDelta = [];
s.gfTau = [];
s.TimeOffset = 0;
s.AcqOrder = '';
s.SynthSeed = 0;
s.cfgfile = '';
s.verbose = 0;
s.nslices    = -1;
s.eresdir    = '';
s.sigestdir  = '';
s.snrdir  = '';
s.debug = 0;
s.loginput = 0;
s.funcstem = '';
s.override = 0;
s.saveraw = 0;
return;

%--------------------------------------------------%
% Parse the arguments from the config file %
function argscfg = parse_cfg(args)
argscfg = args;
cfgfile = '';
nargs = length(args);
narg = 1;
while(narg <= nargs)
    flag = deblank(args{narg});
    narg = narg + 1;
    if (strcmp(flag,'-cfg'))
        arg1check(flag,narg,nargs);
        cfgfile = args{narg};
        break;
    end
end

if (~isempty(cfgfile))
    fid = fopen(cfgfile,'r');
    if (fid == -1)
        fprintf(2,'ERROR: cannot open %s\n',cfgfile);
        argscfg = []; return;
    end
    [s n] = fscanf(fid,'%s',1);
    while(n ~= 0)
        nargs = nargs + 1;;
        argscfg{nargs} = s;
        [s n] = fscanf(fid,'%s',1);
    end
end

return

%--------------------------------------------------%
% ----------- Parse Input Arguments ---------------%
function s = parse_args(varargin)

fprintf(1,'Parsing Arguments \n');
s = sxa_struct;
inputargs = parse_cfg(varargin{1});
ninputargs = length(inputargs);

narg = 1;
while(narg <= ninputargs)
    
    flag = deblank(inputargs{narg});
    flag=lower(flag);
    narg = narg + 1;
    if (~ischar(flag))
        flag
        fprintf(1,'ERROR: All Arguments must be a string\n');
        qoe; return
    end
    
    switch(flag)
        
        case '-i',
            arg1check(flag,narg,ninputargs);
            s.invollist = strvcat(s.invollist,inputargs{narg});
            narg = narg + 1;
            
        case '-p',
            arg1check(flag,narg,ninputargs);
            s.parlist = strvcat(s.parlist,inputargs{narg});
            narg = narg + 1;
            
        case '-extreg',
            arg1check(flag,narg,ninputargs);
            s.extregfile = inputargs{narg};
            narg = narg + 1;
            
        case '-extregorthog',
            s.extregorthog = 1;
            
        case '-nextreg',
            arg1check(flag,narg,ninputargs);
            s.nextreg = sscanf(inputargs{narg},'%d',1);
            narg = narg + 1;
            
        case {'-parname'},
            arg1check(flag,narg,ninputargs);
            s.parname = inputargs{narg};
            narg = narg + 1;
            
        case {'-tpx','-tpexclfile'}
            arg1check(flag,narg,ninputargs);
            s.tpxlist = strvcat(s.tpxlist,inputargs{narg});
            narg = narg + 1;
            
        case {'-whtnmtx'}
            arg1check(flag,narg,ninputargs);
            s.WhtnMtxFile = strvcat(s.WhtnMtxFile,inputargs{narg});
            narg = narg + 1;
            
        case {'-autowhiten'} % Arg is minimum condition for regularization
            arg1check(flag,narg,ninputargs);
            s.TauMaxWhiten = sscanf(inputargs{narg},'%f',1);
            if (s.TauMaxWhiten > 0)
                s.AutoWhiten = 1;
                s.SaveErrCovMtx = 1;
            end
            narg = narg + 1;
            
        case {'-whiten'} 
            s.WhitenFlag = 1; 
            % Requires that -whtnmtx be specified for each run
            % the whtn matrix will be stored in matlab4 format
            % in the variable named W.
            
        case {'-noautowhiten'} % To ease recursive calls
            s.NoAutoWhiten = 1;
            s.AutoWhiten = 0;
            s.TauMaxWhiten = 0;
            s.SecondPass = 1;
            
        case {'-mask'},
            arg1check(flag,narg,ninputargs);
            s.maskid = inputargs{narg};
            narg = narg + 1;
            
        case {'-o','-h'},
            arg1check(flag,narg,ninputargs);
            s.hvol = inputargs{narg};
            narg = narg + 1;
            
        case {'-beta'},
            arg1check(flag,narg,ninputargs);
            s.betavol = inputargs{narg};
            narg = narg + 1;
            
        case {'-fomnibus'},
            arg1check(flag,narg,ninputargs);
            s.fomnibusvol = inputargs{narg};
            narg = narg + 1;
            
        case {'-pomnibus'},
            arg1check(flag,narg,ninputargs);
            s.pomnibusvol = inputargs{narg};
            narg = narg + 1;
            
        case {'-ecovmtx'},
            arg1check(flag,narg,ninputargs);
            s.ErrCovMtxStem = inputargs{narg};
            narg = narg + 1;
            
        case {'-svecovmtx','-sverrcovmtx','-svecvm'},
            s.SaveErrCovMtx = 1;
            
        case {'-tr'}
            arg1check(flag,narg,ninputargs);
            s.TR = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-ter'}
            arg1check(flag,narg,ninputargs);
            s.TER = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-timewindow','-totwin','-tw'}
            arg1check(flag,narg,ninputargs);
            s.TotWin = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-prewindow','-prewin','-prestim'}
            arg1check(flag,narg,ninputargs);
            s.PreStimWin = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-postwindow','-postwin','-poststim'}
            arg1check(flag,narg,ninputargs);
            s.PostStimWin = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-timeoffset'}
            arg1check(flag,narg,ninputargs);
            s.TimeOffset = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-basegment'}
            s.SegBrainAir = 1;
            
        case {'-nobasegment'}
            s.SegBrainAir = 0;
            
        case {'-nobaseline'}
            s.RmBaseline = 0;
            
        case {'-baseline'}
            s.RmBaseline = 1;
            
        case {'-detrend'}
            s.RmTrend = 1;
            
        case {'-qtrendfit'}
            s.QTrendFit = 1;
            
        case {'-highpass'}
            s.HighPassFilter = 1;  
            s.HPFPeriod = sscanf(inputargs{narg},'%f',1); 
            narg = narg + 1;
            
        case {'-lpf'}
            s.LPFFlag = 1;
            
        case {'-hpf'}
            arg2check(flag,narg,ninputargs);
            s.HPF = sscanf(inputargs{narg},'%f %f',1);
            narg = narg + 1;
            
        case {'-polyfit'}
            arg1check(flag,narg,ninputargs);
            s.PFOrder = sscanf(inputargs{narg},'%d',1);
            narg = narg + 1;
            
        case {'-rescale'}
            arg1check(flag,narg,ninputargs);
            s.RescaleTarget = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-nskip'}
            arg1check(flag,narg,ninputargs);
            s.nSkip = sscanf(inputargs{narg},'%d',1);
            narg = narg + 1;
            
        case {'-hanrad'}
            arg1check(flag,narg,ninputargs);
            s.HanRad = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-force','-saveover','-override'}
            % save over any existing tSeries
            s.override = 1;
            
        case {'-fwhm'}
            arg1check(flag,narg,ninputargs);
            s.FWHM = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-ipr'}
            arg1check(flag,narg,ninputargs);
            s.InPlaneRes = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-gammafit'}
            arg2check(flag,narg,ninputargs);
            s.gfDelta = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            s.gfTau   = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
%             s.gfDelta = [s.gfDelta s.gfDelta];
%             s.gfTau   = [s.gfTau   s.gfTau];
            
        case '-acqorder',
            arg1check(flag,narg,ninputargs);
            s.AcqOrder = inputargs{narg};
            narg = narg + 1;            
            
        case {'-nslices', '-ns'}
            arg1check(flag,narg,ninputargs);
            s.nslices = sscanf(inputargs{narg},'%d',1);
            narg = narg + 1;
            
        case '-eresdir',
            arg1check(flag,narg,ninputargs);
            s.eresdir = inputargs{narg};
            narg = narg + 1;
            
        case '-snrdir',
            arg1check(flag,narg,ninputargs);
            s.snrdir = inputargs{narg};
            narg = narg + 1;
            
        case {'-sigestdir','-signaldir'}
            arg1check(flag,narg,ninputargs);
            s.sigestdir = inputargs{narg};
            narg = narg + 1;
            
        case '-cfg',
            % This is actually handled by parse_cfg
            arg1check(flag,narg,ninputargs);
            narg = narg + 1;
            
        case '-synth', 
            arg1check(flag,narg,ninputargs);
            s.SynthSeed = sscanf(inputargs{narg},'%d',1);
            narg = narg + 1;
            
        case '-verbose',
            s.verbose = 1;
            
        case '-log',
            s.loginput = 1;
            
            % ignore these guys %
        case {'-monly', '-nullcondid','-umask','-sveres','-svsignal','-svsnr',...
                    '-psc','percent', 'firstslice'},
            arg1check(flag,narg,ninputargs);
            narg = narg + 1;
            
        case {'-debug','-echo'}, % ignore
            s.debug = 1;
            
        case {'-saveraw','-raw'},
            s.saveraw = 1;
            
        otherwise
            fprintf(2,'ERROR: Flag %s unrecognized\n',flag);
            s = [];
            return;
            
    end % --- switch(flag) ----- %
    
end % while(narg <= ninputargs)

return;
%--------------------------------------------------%

%--------------------------------------------------%
%% Check that there is at least one more argument %%
function arg1check(flag,nflag,nmax)
if (nflag>nmax) 
    fprintf(1,'ERROR: Flag %s needs one argument',flag);
    error;
end
return;
%--------------------------------------------------%
%% Check that there are at least two more arguments %%
function arg2check(flag,nflag,nmax)
if (nflag > nmax-1 ) 
    fprintf(1,'ERROR: Flag %s needs two arguments',flag);
    error;
end
return;


%--------------------------------------------------%
%% Check argument consistency, etc %%%
function s = check_params(s)

fprintf(1,'Checking Parameters\n');

s.nruns = size(s.invollist,1);
npars = size(s.parlist,1);
ntpxs = size(s.tpxlist,1);

if (s.nruns < 1) 
    fprintf(2,'ERROR: No input volumes specified\n');
    s=[]; return;
end

if (s.nslices < 0)
    instem = deblank(s.invollist(1,:));
    [s.nslices nrows ncols ntrs] = er_tvoldim(instem);
    if (s.nslices == 0) 
        fprintf(2,'ERROR: Volume %s does not exist\n',instem);
        s=[]; return;
    end      
end

if (npars ~= 0 & ~isempty(s.parname) ) 
    fprintf(2,'ERROR: Cannot specify both -p and -parname\n');
    s=[]; return;
end

if (npars == 0 & isempty(s.parname) ) 
    fprintf(2,'ERROR: No paradigm specified\n');
    s=[]; return;
end

if ( ~isempty(s.parname) ) 
    for n = 1:s.nruns
        involpath = fileparts(deblank(s.invollist(n,:)));
        par = sprintf('%s/%s',involpath,s.parname);
        s.parlist = strvcat(s.parlist,par);
    end
    npars = size(s.parlist,1);
end

if (npars ~= s.nruns)
    fprintf(2,'ERROR: Number of input volumes (%d) and paradigms (%d) differ\n',...
        s.nruns,npars);
    s=[]; return;
end

if (ntpxs ~= 0 & ntpxs ~= s.nruns)
    fprintf(2,'ERROR: Number of input volumes (%d) and tpexcl files (%d) differ\n',...
        s.nruns,ntpxs);
    s=[]; return;
end

if (~isempty(s.extregfile) ) 
    for n = 1:s.nruns
        involpath = fileparts(deblank(s.invollist(n,:)));
        extregtmp = sprintf('%s/%s',involpath,s.extregfile);
        s.extreglist = strvcat(s.extreglist,extregtmp);
    end
end

if (size(s.hvol,1) ~= 1)
    fprintf(2,'ERROR: No output volume specified\n');
    s = []; return;
end

if (s.NoAutoWhiten) s.AutoWhiten = 0; end
if (s.AutoWhiten)
    s.hvol = sprintf('%s0',s.hvol);
    fprintf('INFO: chaning output volume stem to %s for first stage\n');
end
if (s.AutoWhiten & s.WhitenFlag)
    fprintf('ERROR: cannot specify -autowhiten and -whiten\n');
    s = []; return;
end
if (s.WhitenFlag)
    if (size(s.WhtnMtxFile,1) ~= s.nruns)
        fprintf('ERROR: must spec nruns whtmtx files with -whiten\n');
        s = []; return;
    end
end

if (~isempty(s.HPF))
    if (s.HPF(1) < 0 | s.HPF(1) > 1 | s.HPF(2) < 0 | s.HPF(2) >= 1)
        fprintf(2,'ERROR: HPF Parameters out of range\n');
        s = []; return;
    end
end

if (length(s.TR) == 0)
    fprintf(2,'ERROR: No s.TR specified\n');
    s = []; return;
end

if (length(s.TotWin) == 0)
    fprintf(2,'ERROR: No Time Window specified \n');
    s = []; return;
    %fprintf(2,'INFO: No Time Window specified ...\n');
    %fprintf(2,' Setting to 20 sec\n');
    %s.TotWin = 20;
end

if (length(s.AcqOrder) > 0)
    if (~strcmpi(s.AcqOrder,'Linear') & ~strcmpi(s.AcqOrder,'Interleaved'))
        fprintf(2,'ERROR: Acquisition Order %s unknown (Linear or Interleaved)\n',...
            s.AcqOrder);
        s = []; return;
    end
end

if (length(s.TER) == 0) s.TER = s.TR; end

s.GammaFit = length(s.gfDelta);

if (s.SaveErrCovMtx)
    s.ErrCovMtxStem = sprintf('%s-ecvm',s.hvol);
end

if (s.FWHM > 0 & s.HanRad > 0)
    fprintf('ERROR: Cannot specify both -hanrad and -fwhm\n');
    s = []; return;
end

if (s.FWHM > 0 & isempty(s.InPlaneRes))
    fprintf('ERROR: Need -ipr with -fwhm\n');
    s = []; return;
end

if (s.FWHM > 0 )
    s.HanRad = pi*s.FWHM/(2*s.InPlaneRes*acos(.5));
end

return;

%--------------------------------------------------%
function runlist = getrunlist(invollist)
nruns = size(invollist,1);
runlist = [];
for run = 1:nruns
    invol = deblank(invollist(run,:));
    tmp = fileparts(invol);
    runid = basename(tmp);
    runno = sscanf(runid,'%d');
    runlist = [runlist runno];
end
return;
