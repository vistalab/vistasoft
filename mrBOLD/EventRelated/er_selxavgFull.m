function r = er_selxavgFull(varargin)
% er_selxavgFull: perform selective averaging analysis on event-related, or block-design data.
% (see Greves '99)
%
% This is the full version, with the profusion of stuff that is included
% in the FS-FAST toolbox version, fast_selxavg.m. By default, mrVista
% will use er_selxavg, which will omit a lot of the stuff we generally 
% don't use.
%
% r = er_selxavg(varargin)
%
% This version of selxavg is designed for use with mrLoadRet, and loads
% data in the form of mrLoadRet tSeries.
%
% The format for calling this in general is (using non-functional call, to
% avoid quotes):
%
% ras-selxavg [options] -i inputdir -p parfile [repeat for all
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



% PROGRAMMING NOTES:
% Changes from fmri_selxavg:
%
%   * Doesn't use an invollist anymore (that's for bfiles). Instead, takes
%   an inpath list of mrLoadRet scan directories (e.g.,
%   mySession/Inplane/Original/tSeries/Scan1.) Similarly, the
%   outstem list (-o flag) should be the mrLoadRet scan directory to save
%   the tSeries output (generally .../Inplane/Averages/tSeries/Scan#/).
%
%   * New analysis option: -highpass [period]. This causes the code to high-pass
%   filter the data using removeBaseline2 from mrLoadRet before selective
%   averaging. Uses a 60-second cutoff period of low-frequency baseline
%   drift to remove from the time course, expressed in frames of the time
%   series. (This is thought to be better than a linear or quadratic
%   baseline fit for certain types of rapid-event-related designs.)
%
%   * Saving: the obvious change is that this code now saves/loads tSeries
%   instead of b-files. In addition, exactly what gets saved and where is a
%   little different. For fmri_selxavg, the outstem would save the raw
%   deconvolved time courses in 'h_###.bfloat', with mean functional images
%   in 'h-offset_###.bfloat' and percent signal changes was saved only if the user
%   specificed the -psc flag. Now, it saves the % signal change as tSeries
%   by default, saves the h-offset as a mean map (meanMapScan#.mat), and
%   also saves the omnibus contrast as a mean map. The mean maps are
%   located in the data type directory, e.g., mySession/Inplane/Averages/.
%   Raw timecourses (previously the main output) are saved in the same path
%   as the tSeries under the name 'raw_###.mat', but only if the '-raw' or 
%   '-saveraw' flags are set. (Otherwise, doesn't save raw data by default).
%
%   Also, now block-designed (non-deconvolved) scans are handled
%   differently from rapid event-related scans. The outstem is [more]
%
%   * Force saving: entering '-force', '-saveover', or '-override' as an
%   argument will now cause the code to automatically save over any
%   pre-existing files in the destination directory without prompting.
%
%   * Saves the omnibus contrast (p-value from F-test of all non-null 
%   conditions vs. null). If deconvolving, saves it as 'omnibus_scanX.mat'
%   in the Inplane/Averages directory. X is the scan # of the output scan
%   created for the deconvolved data. If fitting a hemodynamic response
%   (block-design, long event-related), saves it as 'omnibus_scanY-Z.mat'
%   in the dataDir of the session -- e.g., Inplane/Originals.
%   Y and Z are the first and last 
%   input scans (if only one input scan, saves as 'omnibus_scanY.mat').
%   This is saved as a parameter map.
%
%   * In general, there are a lot of things that this code can do that I 
%   leave off -- like auto-whitening, fwhm smoothing, etc. Since many of
%   these things are kind of against the philosophy of mrVISTA, I haven't
%   debugged their use in this context. But feel free to try!
%
% 06/18/03 ras: attempt to integrate into mrLoadRet tools
% 03/08/04 ras: Several further updates, inclding compatibiliity with
% block-design expts.
% 04/02/04 ras: saves omnibus contrast as a parameter map now.
%
% For more info on the original selxavg, see $fsfast/docs/selxavg.ps. or:
% merlin.psych.arizona.edu/~dpat/Public/Imaging/MGH/FS-FASTtutorial.pdf 
% '$Id: er_selxavgFull.m,v 1.1 2004/05/25 22:56:56 sayres Exp $'
version = '$Id: er_selxavgFull.m,v 1.1 2004/05/25 22:56:56 sayres Exp $';
fprintf(1,'%s\n',version);
r = 1;

%% Print useage if there are no arguments %%
if (nargin == 0)
    print_usage;
    return;
end

%% Parse the arguments %%
varargin = unNestCell(varargin); % so you can pass a big cell of options
s = parse_args(varargin);
if (isempty(s)) return; end
s = check_params(s);
if (isempty(s)) return; end

% This may be needed 
%s.PreStimWin = s.TER*floor(s.PreStimWin/s.TER);
%s.TotWin = s.TER*round(s.TotWin/s.TER);

sxa_print_struct(s,1);

TR  = s.TR;8
TER = s.TER;
TW  = s.TotWin;
TPS = s.PreStimWin;
RmBaseline = s.RmBaseline;
RmTrend    = s.RmTrend;
QTrendFit  = s.QTrendFit;
HighPassFilter = s.HighPassFilter;
HPFPeriod = s.HPFPeriod;
RescaleTarget = s.RescaleTarget;
GammaFit = s.GammaFit;
gfDelta = s.gfDelta;
gfTau =  s.gfTau;
nskip = s.nSkip;
firstslice = 1;
nslices = s.nslices;
TimeOffset = s.TimeOffset;
HanRadius = s.HanRad;
AcqOrder = s.AcqOrder;
SynthSeed = s.SynthSeed;
parfilelist = s.parlist;
instemlist = s.invollist;
tpxlist = s.tpxlist;
hstem     = s.hvol;
eresdir   = s.eresdir;
sigestdir = s.sigestdir;
pctstem   = s.pscvol;
fomnibusstem = s.fomnibusvol;
override = s.override;

% check if we're deconvolving by checking gammafit -- if we are, change
% where we save to be the same as the first input dir (not making new tSeries
% in mrLoadRet, just calculating single beta vals for each condition and saving 
% in hAvg files):
deconvolving = ~(GammaFit > 0); % flag whether we're deconvolving or not
if ~deconvolving
    hstem = deblank(instemlist(1,:));
    override = 1;
end

% want to save omnibus contrast (of p-vals from F-test)
% set it as the 2nd-degree parent of the hstem --
% (e.g., Inplane/Averages if hstem is Inplane/Averages/Tseries/Scan1)
pomnibusstem = fileparts(fileparts(hstem)); % s.pomnibusvol;

% Check if output path already exists / has tSeries %
if ~exist(hstem,'dir')
    callingdir = pwd;
    [a,b] = fileparts(hstem);
    cd(a); mkdir(b);
    cd(callingdir);
else
    if exist(fullfile(hstem,'tSeries1.mat'),'file') & ~override
        % warn user and prompt for save-over (unless overridden)
        questionStrings = [{'tSeries already exist in this path:'}; ...
                {''}; {hstem}; {''}; ...
                {'Do you want to continue, which will create new tSeries files?'}];
        buttonName = questdlg(questionStrings, 'Warning', 'Yes', 'No', 'No');
        pause(.1);  % Prevent hanging
        if strcmp(buttonName, 'No')
            fprintf('Aborting ... don''t want to save over existing files.\n');
            return
        else
            override = 1;
        end    
    end
end

if (~isempty(s.maskid))
    fprintf('INFO: loading mask %s\n',s.maskid);
    mask = er_ldtvolume(s.maskid);
    if (isempty(mask))
        fprintf('ERROR: could not load %s\n',s.maskid);
        return;
    end
    nmasktot = length(find(mask));
    fprintf('INFO: mask has %d points\n',nmasktot);
else
    mask = [];
end

%-------------------------------------------------%
lastslice = firstslice + nslices - 1;
nruns = size(parfilelist,1);
Nfir = round(TW/TER);

if (SynthSeed < 0) SynthSeed = sum(100*clock); end
fprintf('SynthSeed = %10d\n',SynthSeed);

% Load Whitening matrix %
if (s.SecondPass)
    WhtnMtx = er_ldtfile(s.WhtnMtxFile);
    WhtnMtxSq = WhtnMtx'*WhtnMtx; %'
else
    WhtnMtx = [];
    WhtnMtxSq = [];
end

%-- Determine Number of Conditions across all runs----------%
% Get list of unqiue condition IDs for all runs %
condlist = [];
for run = 1:nruns
    par = fmri_ldpar(deblank(parfilelist(run,:)));
    if (isempty(par))
        fprintf('ERROR: reading parfile %s\n',deblank(parfilelist(run,:)));
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
    par = fmri_ldpar(deblank(parfilelist(run,:)));
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

% Setup Spatial Smoothing Kernal %
if (HanRadius > 1)
    HanFilter = fmri_hankernel(HanRadius);
end

SubSampRate = round(TR/TER);

% Get basic info from the first run %
instem = deblank(instemlist(1,:));
[nslices nrows ncols ntrs] = er_tvoldim(instem);

%-----------------------------------------------------------------%
%--------------- Beginning of Slice Loop -------------------------%
%-----------------------------------------------------------------%
hWaitbar = mrvWaitbar(0,'selxavg:');
SumESSMtxRun = zeros(ntrs,ntrs,nruns);
NBrainVoxsRun = zeros(nruns);
SumESSMtx = 0;
NBrainVoxsTot = 0;
tic;
for slice = firstslice:lastslice
    mrvWaitbar((slice-1)/nslices,hWaitbar,sprintf('selxavg: slice %i of %i',slice,nslices));
    fprintf(1,'Slice %d, %g --------------\n',slice,toc);
    SumXtX = 0;
    SumXtWX = 0;
    SumXtWY = 0;
    eres_ss = 0;
    Xfinal = [];
    
    for Pass = 1:2
        
        if (slice == firstslice | s.debug)
            if (Pass == 1)
                fprintf(1,'  First Pass (Accumulation), %g \n',toc);
            else
                fprintf(1,'  Second Pass (Residual Error Estimation), %g \n',toc);
            end
        end
        
        randn('state',SynthSeed); 
        
        if (Pass == 2)
            
            c = cond(SumXtWX);
            if (slice == firstslice | s.debug)
                fprintf('    Paradigm Condition: %g\n',c);
            end
            
            if (c > 10000000)
                fprintf('ERROR: paradigm is ill-conditioned (%g).\n',c);
                fprintf('Check your paradigm file for file for periodicities\n');
                fprintf('or for some event types that always follow other\n');
                fprintf('event types (or itself).\n');
                return;
            end
            
            if (slice == firstslice | s.debug)
                indtask = 1:size(Xpar,2);
                invSumXtX = inv(SumXtWX);
                d = diag(invSumXtX);
                minvr  = min(1./d(indtask));
                meanvr = mean(1./d(indtask));
                maxvr  = max(1./d(indtask));
                fprintf('    Var Reduction Range: %g %g %g\n',minvr,meanvr,maxvr);
            end
            
            if (slice == firstslice | s.debug)
                fprintf(1,'     Computing hhat\n');
            end
            hCovMtx = inv(SumXtWX);
            hhat = hCovMtx*SumXtWY;
        end
        
        %-------------------- Run Loop ------------------------%
        ntrstot = 0;
        ntpxtot = 0;
        for run = 1:nruns
            
            if (slice == firstslice | s.debug)
                fprintf(1,'     Run %d/%d, %g \n',run,nruns,toc);
            end
            
            instem = deblank(instemlist(run,:));
            
            % Get number of TRs in this run %
            [nslices nrows ncols ntrs] = er_tvoldim(instem);
            ntrstot = ntrstot + ntrs;
            nvoxs = nrows*ncols;
            
            % Time Point Exclusion %
            if (~isempty(tpxlist))
                TPExcludeFile = deblank(tpxlist(run,:));
                if (strcmp(TPExcludeFile,'noexcl')) TPExcludeFile = []; end
            else
                TPExcludeFile = [];
            end
            [indTPExcl indTPIncl] = fast_ldtpexcl(TPExcludeFile,TR,ntrs,nskip);
            ntpx = length(indTPExcl);
            if (slice == firstslice | s.debug)
                fprintf(1,'       Excluding %d Points: ',ntpx);
                fprintf(1,'%d ',indTPExcl);
                fprintf(1,'\n');
            end
            ntpxtot = ntpxtot + ntpx; 
            FF = min(indTPIncl); % First Frame
            
            Xdrift = [];
            if (s.PFOrder < 0)
                % Create Baseline/Trend Components of Convolution Matrix %
                Xbaseline = []; Xtrend = []; Xqtrend  = [];
                if (RmBaseline) Xbaseline = fast_baselinemtx(run,ntrs,nruns); end
                if (RmTrend)    Xtrend    = fast_trendmtx(run,ntrs,nruns); end
                if (QTrendFit)  Xqtrend   = fast_quadtrendmtx(run,ntrs,nruns); end
                Xdrift = [Xbaseline Xtrend Xqtrend];
            else
                Xdrift  = fast_polytrendmtx(run,ntrs,nruns,s.PFOrder);
            end
            
            % Load paradigm for this run %
            par = fmri_ldpar(deblank(parfilelist(run,:)));
            
            % Compute Offset for Slice Timing %
            if (~isempty(AcqOrder))
                SliceDelay = fast_slicedelay(TR,nslices,slice,AcqOrder);
            else
                SliceDelay = 0;
            end
            
            % Adjust for Time Offset %
            par(:,1) = par(:,1) + TimeOffset;
            
            % Convert paradigm to FIR stimulus convolution matrix %
            Xfir = fmri_par2scm(par,Nc,SubSampRate*ntrs,TER,Nfir,TPS);
            
            % For Sub-TR Estimation %
            if (TR ~= TER)
                Xfirtmp = Xfir;
                nn = [1:SubSampRate:size(Xfirtmp,1)];
                Xfir = Xfirtmp(nn,:);
            end
            
            % Tranform for Fitting to Gamma Function(s) %
            if (GammaFit > 0)
                Xpar = fmri_scm2gcm(Xfir,Nnnc,TER,TPS,gfDelta,gfTau);
                Navgs_per_cond = length(gfDelta);
            else
                Xpar = Xfir;
                Navgs_per_cond = Nfir;
            end
            
            % Number of averages excluding the offsets and trends
            NTaskAvgs = Nnnc*Navgs_per_cond;
            
            if (~isempty(s.extreglist))
                extregstem = deblank(s.extreglist(run,:));
                extreg = er_ldtvolume(extregstem);
                if (isempty(extreg))
                    fprintf('ERROR: could not load %s\n',extregstem);
                    return;
                end
                if (size(extreg,3)~=1)
                    extreg = squeeze(extreg)'; %'
                else
                    extreg = squeeze(extreg);
                end
                if (slice == firstslice & s.nextreg < 0) s.nextreg = size(extreg,2); end
                if (s.nextreg > size(extreg,2))
                    fprintf('ERROR: %s does not have enough regressors\n',extregstem);
                    return;
                end
                % Remove mean of External Regressor %
                extreg = extreg(:,1:s.nextreg);
                extreg = extreg - repmat(mean(extreg), [ntrs 1]);
                extreg = extreg./repmat(std(extreg), [ntrs 1]);
                if (s.extregorthog)
                    extreg = ( eye(ntrs) - Xpar*inv(Xpar'*Xpar)*Xpar') * extreg;
                end
                z = zeros(size(extreg));
                extregrun = [repmat(z,[1 (run-1)]) extreg repmat(z,[1 (nruns-run)])];
            else
                extregrun = [];
            end
            
            % Create final Convolution Matrix for ith run %
            Xi = [Xpar Xdrift extregrun];
            
            % Load or synthsize data %
            if (SynthSeed == 0)
                % Load the data for this slice %
                [nrows ncols ntp fs ns endian bext] = er_tfiledim(instem);
                fname = fullfile(instem,['tSeries' num2str(slice) bext]);
                %         fname = sprintf('%s_%03d.%s',instem,slice,bext);
                y = er_ldtfile(fname);
            else
                %fprintf(1,'       Synthesizing Data for Slice %d \n',slice);
                y = randn(ntrs, nrows, ncols);
            end
            
            % Exlude Points %
            Xi(indTPExcl,:) = 0;
            y(:,:,indTPExcl)  = 0;
            
            % Spatial Smoothing with In-Plane Hanning Window %
            if (HanRadius > 1)
                if (slice == firstslice | s.debug)
                    fprintf(1,'       Spatial Smoothing, HanRad = %g\n',HanRadius);
                end
                y = fmri_spatfilter(y,HanFilter);
            end
            
            % Reshape to a more convenient form %
            y = reshape(y, [nrows*ncols ntrs])'; %'            
            
            off_est = repmat(mean(y),size(y,1),1);
            
            % High-pass filter: remove low-frequency baseline drift
            if HighPassFilter
                HPFPeriod = round(60/TR);
                y = removeBaseline2(y,HPFPeriod);
                % artificially add offset equal to raw tSeries mean,
                % so that PSC estimate is accurate
                y = y + off_est;
            end      
            
            % Global rescale of functional data %
            if (RescaleTarget > 0)
                MeanValFile = fullfile(instem,'fmc.meanval');
                [RescaleFactor MeanVal]=fast_rescalefactor(MeanValFile, RescaleTarget);
                %fprintf(1,'       Rescaling Global Mean %g,%g,%g\n',...
                %        MeanVal,RescaleTarget,RescaleFactor);
                y = RescaleFactor * y;
            else
                RescaleFactor = 1;
            end
            
            if (s.loginput) 
                fprintf('INFO: computing log of input\n');
                y = log(abs(y)+2); 
            end
            
            % Load per-run whitening matrix here, mult by Xi and y
            if (s.WhitenFlag)
                fname = deblank(s.WhtnMtxFile(run,:));
                %fprintf('INFO: loading whtn matrix %s\n',fname);        
                WW = load(fname);
                %Wrun = WW.W;
                %y  = Wrun*y;
                %Xi = Wrun*Xi;
                WhtnMtx = WW.W;
                WhtnMtxSq = WhtnMtx'*WhtnMtx; %'
            else
                % Whitening Filter %
                if (isempty(s.WhtnMtxFile)) 
                    WhtnMtx   = eye(ntrs); 
                    WhtnMtxSq = eye(ntrs); 
                else
                    [wr wc] = size(WhtnMtx);
                    if (wr ~= ntrs)
                        fprintf(2,'ERROR: Whitening Matrix is %d x %d, ntrs = %d\n',...
                            wr,wc,ntrs);
                        return;
                    end
                end
            end
            
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
                
                if (~isempty(sigestdir))
                    % Save Signal Estimate (Partial Model Fit) %
                    pmf = Xi(:,1:NTaskAvgs)*hhat(1:NTaskAvgs,:);
                    fname = sprintf('%s/s%03d_%03d.mat',sigestdir,run,slice);
                    tmp = reshape(pmf', [nrows ncols ntrs])/RescaleFactor; %'
                    er_svtfile(tmp,fname,override);
                    clear tmp pmf;
                end
                
                if (~isempty(eresdir))
                    % Save (Whitened) Residual Error %
                    fname = fullfile('%s/e%03d_%03d.mat',eresdir,run,slice);
                    tmp = reshape(eres', [nrows ncols ntrs])/RescaleFactor; %'
                    er_svtfile(tmp,fname,override);
                end
                
                if (~isempty(s.ErrCovMtxStem))
                    if (s.SegBrainAir)
                        if (isempty(mask))
                            MeanValFile = sprintf('%s.meanval',instem);
                            [tmp MeanVal] = fast_rescalefactor(MeanValFile,101);
                            indBrain = find( y(FF,:) > .75*MeanVal );
                        else
                            indBrain = find(mask(slice+1,:,:));
                        end
                    else
                        indBrain = [1 nvoxs];
                    end
                    NBrainVoxs = length(indBrain);
                    fprintf(1,'       NBrainVoxs = %d\n',NBrainVoxs);
                    if (NBrainVoxs > 0)
                        %fprintf(1,'       Computing Err SS Matrix\n');
                        ESSMtx = eres(:,indBrain) * eres(:,indBrain)'; % '
                        SumESSMtx = SumESSMtx + ESSMtx;
                        NBrainVoxsTot = NBrainVoxsTot + NBrainVoxs;
                        SumESSMtxRun(:,:,run) = SumESSMtxRun(:,:,run) + ESSMtx;
                        NBrainVoxsRun(run) = NBrainVoxsRun(run) + NBrainVoxs;
                    end
                end
                
            end
            mrvWaitbar(slice/nslices,hWaitbar);
            
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
    tmp = zeros(Navgs_per_cond,2,Nc,nvoxs);
    tmp(:,1,:,:) = hhattmp2;
    tmp(:,2,:,:) = hstdtmp2;
    tmp = reshape(tmp,[Navgs_per_cond*2*Nc nrows ncols ]);
    tmp = permute(tmp,[2 3 1]);
    
    % by default, selxavg would save the null condition (which
    % is defined by this analysis as being 0) for clarity. Since with a
    % deconvolved time course this is a lot of extra, redundant zeros to
    % store, I remove that information for mrLoadRet. Be aware that this
    % also removes the residual variance of the fitting, which is saved as
    % the variance associated with the null condition. This is important
    % for non-deconvolved data (so I keep it and the null condition), but
    % don't think it's needed for deconvolved. If necessary, I'll add an
    % option to save it as a separate file.
    if deconvolving
        tmp = tmp(:,:,(2*TW)+1:end);
    end
    
    % Save the raw data if selected %
    if s.saveraw | ~deconvolving % changed name to be (I hope) more clear what's stored
%         fname = fullfile(hstem,sprintf('raw_%03d.mat',slice));
        fname = fullfile(hstem,['hAvg' num2str(slice) '.mat']);
        if (slice == firstslice | s.debug)   fprintf(1,'  Saving raw data to %s \n',fname);    end    
        er_svtfile(tmp,fname,override);
    end
    
    % Save the mean image %
    if RmBaseline 
        hoffset = reshape(hhat(NTaskAvgs+1,:), [nrows ncols]); % From 1st Run
        fname = fullfile(hstem,sprintf('mean_%03d.mat',slice));
        if (slice == firstslice | s.debug)
            fprintf(1,'  Saving offset to %s \n',fname);
        end
        er_svtfile(hoffset,fname,override);
    end
    
    % ---- Save Percent Signal Chanage -- now the main output ---- %
    % trying to do something diff't: divide by the mean at each voxel,
    % instead of by the offset (which is the result of a baseline
    % estimator, I believe. ras 07/03). Changed back 09/03
    if deconvolving
        fname = fullfile(hstem,['tSeries' num2str(slice) '.mat']);
        tmp = 100 * tmp ./ repmat(hoffset, [1 1 size(tmp,3)]);
        %     tmp = 100 * tmp ./ repmat(mean(abs(tmp),3), [1 1 size(tmp,3)]);
        if (slice == firstslice | s.debug)   fprintf(1,'  Saving %% signal change to %s \n',fname);    end
        er_svtfile(tmp,fname,override);
    else
        % we want to save hAvg as the raw value, to be compatible w/ other fs-fast functions.
        % right now the % signal isn't as useful for non-deconvolved data,
        % but may become later. If so, insert a 'er_svtfile' call here        
    end       
    
    
    % Save in beta format %
    if (~isempty(s.betavol))
        tmp = hhat;
        ntmp = size(tmp,1);
        tmp = reshape(tmp',[nrows ncols ntmp]); %';
        fname = sprintf('%s_%03d.mat',s.betavol,slice);
        er_svtfile(tmp,fname,override);
        
        tmp = eres_var;
        ntmp = size(tmp,1);
        tmp = reshape(tmp',[nrows ncols ntmp]); %';
        fname = sprintf('%s-var_%03d.mat',s.betavol,slice);
        er_svtfile(tmp,fname,override);
        
        clear tmp;
    end
    
    % Omnibus Significance Test %
    if (~isempty(fomnibusstem) | ~isempty(pomnibusstem))
        
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
        if (~isempty(fomnibusstem))
            fname = sprintf('%s_%03d.mat',fomnibusstem,slice);
            tmp = reshape(F,[nrows ncols]);
            er_svtfile(tmp,fname,override);
        end
        if (~isempty(pomnibusstem))
            if (slice == firstslice | s.debug)
                fprintf('INFO: performing FTest on omnibus\n');
                fprintf('      NOTE: if this hangs, try running selxavg-sess\n');
                fprintf('      with the -noomnibus flag.\n');
            end
            p = sign(F) .* FTest(NTaskAvgs,DOF,abs(F));
            indz = find(p==0);
            p(indz) = 1;
            p = sign(p).*(-log10(abs(p)));
            omnibus(:,:,slice) = reshape(p,[nrows ncols]);
            % fname = fullfile(hstem,sprintf('omnibus_%03d.mat',slice));
            % er_svtfile(tmp,fname,override); % we'll save later, as a
            % param map
        end
    end
    
    if (~isempty(s.snrdir))
        p = zeros(Navgs_tot,1);
        p(1:NTaskAvgs) = 1;
        P = diag(p);
        sigvar = sum(hhat .* ((P'*SumXtX*P) * hhat))/(ntrstot);  %'
        
        sigvar = reshape(sigvar,[nrows ncols]);
        fname = sprintf('%s/sigvar_%03d.mat',s.snrdir,slice);
        er_svtfile(sigvar,fname,override);
        fname = sprintf('%s/sigstd_%03d.mat',s.snrdir,slice);
        er_svtfile(sqrt(sigvar),fname,override);
        
        resvar = reshape(eres_std.^2,[nrows ncols]);
        fname = sprintf('%s/resvar_%03d.mat',s.snrdir,slice);
        er_svtfile(resvar,fname,override);
        fname = sprintf('%s/resstd_%03d.mat',s.snrdir,slice);
        er_svtfile(sqrt(resvar),fname,override);
        
        ind0 = find(resvar==0);
        resvar(ind0) = 1;
        snrvar = sigvar./resvar;
        snrvar(ind0) = 0;
        fname = sprintf('%s/snrvar_%03d.mat',s.snrdir,slice);
        er_svtfile(snrvar,fname,override);
        fname = sprintf('%s/snrstd_%03d.mat',s.snrdir,slice);
        er_svtfile(sqrt(snrvar),fname,override);
        
    end
    
end % Loop over slices 
%------------------------------------------------------------%

outvolpath = fileparts(deblank(s.hvol));
xfile = sprintf('%s/X.mat',hstem);
pfOrder = s.PFOrder;
nExtReg = 0; if (s.nextreg > 0) nExtReg = s.nextreg; end
tPreStim = s.PreStimWin;
TimeWindow = TW;
fprintf('INFO: saving meta to %s\n',xfile);
save(xfile,'Xfinal','Nnnc','pfOrder','nExtReg',...
    'nruns','Navgs_per_cond','TimeWindow','tPreStim','TR','TER',...
    'gfDelta','gfTau','-v4');

%-- Save ECovMtx for each run individually --%
if (s.SaveErrCovMtx) 
    for run = 1:nruns,
        fname = sprintf('%s-ecvm_%03d.mat',s.hvol,run-1);
        tmp = SumESSMtxRun(:,:,run)/NBrainVoxsRun(run);
        er_svtfile(tmp,fname,override);
    end
end

% Save ErrCovMtxs across all runs %/
if (~isempty(s.ErrCovMtxStem))
    fprintf(1,'NBrainVoxsTot: %d\n',NBrainVoxsTot);
    fname = sprintf('%s.mat',s.ErrCovMtxStem);
    ErrCovMtx = SumESSMtx/NBrainVoxsTot;
    er_svtfile(ErrCovMtx,fname,override);
end

% Save the .dat file %
fname = fullfile(hstem,'h.dat');
SumXtXTmp  = SumXtX( 1:NTaskAvgs, 1:NTaskAvgs);
hCovMtxTmp = hCovMtx(1:NTaskAvgs, 1:NTaskAvgs);
hd = fmri_hdrdatstruct;
hd.TR  = TR;
hd.TER = TER;
hd.TimeWindow = TW;
hd.TPreStim = TPS;
hd.Nc = Nc;
hd.Nh = Navgs_per_cond;
hd.Nnnc = Nnnc;
hd.DOF= DOF;
hd.Npercond= Npercond;
hd.Nruns = nruns;
hd.Ntp = ntrstot;
hd.Nrows = nrows;
hd.Ncols = ncols;
hd.Nskip = nskip;
if (s.PFOrder < 0)
    hd.DTOrder = RmBaseline+RmTrend+QTrendFit;
else
    hd.DTOrder = s.PFOrder + 1;
end
hd.RescaleFactor = 1.0;
hd.HanningRadius = 0.0;
hd.BrainAirSeg = 0;
hd.GammaFit = GammaFit;
hd.gfDelta  = gfDelta;
hd.gfTau         = gfTau;
hd.NullCondId    = 0;
hd.SumXtX        = SumXtXTmp;
hd.nNoiseAC      = 0;
hd.CondIdMap     = [0:Nc-1];
hd.hCovMtx       = hCovMtxTmp;
hd.WhitenFlag        = s.WhitenFlag;
hd.runlist  = getrunlist(s.invollist);
hd.funcstem      = basename(deblank(s.invollist(1,:)));
hd.parname       = s.parname;
if (~isempty(s.extreglist))
    hd.extregstem  = basename(deblank(s.extreglist(1,:)));
    hd.nextreg  = s.nextreg;
    hd.extortho = s.extregorthog;
end

fmri_svdat3(fname,hd);

if (~isempty(pctstem))
    fname = sprintf('%s.dat',pctstem);
    fmri_svdat3(fname,hd);
end

% save omnibus contrast as a parameter map
% have to actually figure out the scan nums
if deconvolving
    % save path based on output scan num (hstem)
    a = length(hstem);
	while ~isempty(str2num(hstem(a)))
        a = a - 1;
	end
	scan = str2num(hstem(a+1:end));
	fname = sprintf('omnibus_scan%i.mat',scan);
	fname = fullfile(pomnibusstem,fname);
else
    % save path based on input scan nums
    if size(instemlist,1)==1
        a = length(instemlist);
        while ~isempty(str2num(instemlist(1,a)))
            a = a - 1;
        end
        scan = str2num(instemlist(1,a+1:end));
		fname = sprintf('omnibus_scan%i.mat',scan);
		fname = fullfile(pomnibusstem,fname);
    else
        firstScanPath = deblank(instemlist(1,:));
        lastScanPath = deblank(instemlist(end,:));
        a = length(firstScanPath); b = length(lastScanPath); 
        while ~isempty(str2num(instemlist(1,a)))
            a = a - 1;
        end
        while ~isempty(str2num(instemlist(end,b)))
            b = b - 1;
        end
        scanA = str2num(instemlist(1,a+1:end));
        scanB = str2num(instemlist(end,b+1:end));
		fname = sprintf('omnibus_scans%ito%i.mat',scanA,scanB);
		fname = fullfile(pomnibusstem,fname);
        scan = scanA;
    end
end
scan
map{scan} = omnibus; % this may not be the right length
mapName = 'FtestOmnibus';
fprintf('Saving omnibus to %s ...',fname);
save(fname,'map','mapName');


%------------------------------------------------------------%
if (s.AutoWhiten)
    
    fprintf('Computing Whitening Matrix\n');
    
    s.NMaxWhiten = round(s.TauMaxWhiten/s.TR);
    fprintf('TauMax = %g, NMax = %d, Pct = %g\n',s.TauMaxWhiten,...
        s.NMaxWhiten,s.PctWhiten);
    [W AutoCor] = fast_cvm2whtn(ErrCovMtx,s.NMaxWhiten,s.PctWhiten);
    
    if (0)
        [W AutoCor] = fast_cvm2whtn(ErrCovMtx,s.NMaxWhiten);
        nf = length(AutoCor);
        acf = AutoCor .* (.95.^[0:nf-1]');%'
        fprintf('Toeplitz, nmax = %d\n',s.NMaxWhiten);
        L = toeplitz(acf);
        fprintf('InvChol\n');
        W = inv(chol(L));
    end
    
    whtnmtxfile = sprintf('%s-whtnmtx.mat',s.hvol);
    er_svtfile(W,whtnmtxfile,override);
    autocorfile = sprintf('%s-autocor.dat',s.hvol);
    fid = fopen(autocorfile,'w');
    fprintf(fid,'%8.4f\n',AutoCor);
    fclose(fid);
    
    fprintf('Starting Whitening Stage\n');
    nvarargin = length(varargin);
    varargin{nvarargin+1} = '-noautowhiten';
    varargin{nvarargin+2} = '-whtnmtx';
    varargin{nvarargin+3} = whtnmtxfile;
    fprintf('\n\n\n\nStarting recursive call to fast_selxavg\n');
    r = er_selxavg(varargin{:});
    fprintf('Recursive call to fast_selxavg finished\n\n\n');
    
end
%------------------------------------------------------------%


close(hWaitbar);
fprintf(1,'Done %g\n',toc);

r = 0;

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
fprintf(1,'     -TR   TR\n');
fprintf(1,'     -TER  TER\n');
fprintf(1,'     -timewindow totwin  \n');
fprintf(1,'     -prewindow  prewin  \n');
fprintf(1,'     -nobaseline  \n');
fprintf(1,'     -detrend  \n');
fprintf(1,'     -qtrendfit  \n');
fprintf(1,'     -rescale  target \n');
fprintf(1,'     -nskip  n \n');
fprintf(1,'     -hanrad radius \n');
fprintf(1,'     -fwhm   width \n');
fprintf(1,'     -ipr    inplaneres \n');
fprintf(1,'     -gammafit delta tau \n');
fprintf(1,'     -timeoffset t \n');
fprintf(1,'     -acqorder  <linear or interleaved> \n');
fprintf(1,'     -firstslice sliceno : 0 \n');
fprintf(1,'     -nslices    nslices : auto \n');
fprintf(1,'     -eresdir    dir \n');
fprintf(1,'     -sigestdir  dir \n');
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
s.firstslice = 1;
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
    narg = narg + 1;
    %fprintf(1,'Argument: %s\n',flag);
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
            
        case {'-TR'}
            arg1check(flag,narg,ninputargs);
            s.TR = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            
        case {'-TER'}
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
            narg = narg + 1;
            s.HPFPeriod = sscanf(inputargs{narg},'%f',1);        
            
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
            gfDelta = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            gfTau   = sscanf(inputargs{narg},'%f',1);
            narg = narg + 1;
            s.gfDelta = [s.gfDelta gfDelta];
            s.gfTau   = [s.gfTau   gfTau];
            
        case '-acqorder',
            arg1check(flag,narg,ninputargs);
            s.AcqOrder = inputargs{narg};
            narg = narg + 1;
            
        case {'-firstslice', '-fs'}
            arg1check(flag,narg,ninputargs);
            s.firstslice = sscanf(inputargs{narg},'%d',1);
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
                    '-psc','percent'},
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
    fprintf(2,'ERROR: No TR specified\n');
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

if (s.firstslice < 0) 
    fprintf('ERROR: firstslice (%d) < 0',s.firstslice);
    s = []; return;
end

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
%% Print data structure
function s = sxa_print_struct(s,fid)
if (nargin == 1) fid = 1; end

fprintf(fid,'Number of Runs: %d\n',s.nruns);

fprintf(fid,'Input Volume List\n');
for n = 1:size(s.invollist,1),
    fprintf(fid,'  %d  %s\n',n,s.invollist(n,:));    
end

fprintf(fid,'Input Pardigm File List\n');
for n = 1:size(s.parlist,1),
    fprintf(fid,'  %d  %s\n',n,s.parlist(n,:));    
end

if (~isempty(s.tpxlist))
    fprintf(fid,'TP Exclude File List\n');
    for n = 1:size(s.tpxlist,1),
        fprintf(fid,'  %d  %s\n',n,s.tpxlist(n,:));    
    end
end

fprintf(fid,'Output Volume  %s\n',s.hvol);
if (~isempty(s.betavol))
    fprintf(fid,'Beta Volume  %s\n',s.betavol);
end
if (~isempty(s.fomnibusvol))
    fprintf(fid,'F Omnibus Volume  %s\n',s.fomnibusvol);
end
if (~isempty(s.pomnibusvol))
    fprintf(fid,'Sig Omnibus Volume  %s\n',s.pomnibusvol);
end
fprintf(fid,'TR    %f\n',s.TR);
fprintf(fid,'TER   %f\n',s.TER);
fprintf(fid,'Total   Window  %g\n',s.TotWin);
fprintf(fid,'PreStim Window  %g\n',s.PreStimWin);
fprintf(fid,'Remove Baseline %d\n',s.RmBaseline);
fprintf(fid,'Remove Trend    %d\n',s.RmTrend);
fprintf(fid,'Remove QTrend   %d\n',s.QTrendFit);
fprintf(fid,'Rescale Target  %g\n',s.RescaleTarget);
fprintf(fid,'nSkip           %d\n',s.nSkip);
fprintf(fid,'InPlane Res     %g\n',s.InPlaneRes);
fprintf(fid,'FWHM            %g\n',s.FWHM);
fprintf(fid,'Hanning Radius  %g\n',s.HanRad);
fprintf(fid,'Time Offset     %g\n',s.TimeOffset);
if (~isempty(s.AcqOrder))
    fprintf(fid,'Acquistion Order %s\n',s.AcqOrder);
end

fprintf(fid,'GammaFit        %d\n',s.GammaFit);
for n = 1:s.GammaFit
    fprintf(fid,'%d  %g  %g\n',n,s.gfDelta,s.gfTau);
end

fprintf(fid,'Seg Brain/Air   %d\n',s.SegBrainAir);
fprintf(fid,'SynthSeed       %d\n',s.SynthSeed);

if (~isempty(s.ErrCovMtxStem))
    fprintf(fid,'ErrCovMtx Stem   %s\n',s.ErrCovMtxStem);
end

if (~isempty(s.WhtnMtxFile))
    fprintf(fid,'WhtnMtx File   %s\n',s.WhtnMtxFile);
end

if (~isempty(s.extregfile))
    fprintf(fid,'ExtReg File   %s\n',s.extregfile);
    fprintf(fid,'NExtReg       %d\n',s.nextreg);
    fprintf(fid,'ExtRegOrthog  %d\n',s.extregorthog);
end

fprintf(fid,'firstslice   %d\n',s.firstslice);
fprintf(fid,'nslices      %d\n',s.nslices);

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