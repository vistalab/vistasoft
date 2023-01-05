function val = rmGet(model,param,varargin)
% rmGet - Retrieve data from various retinotopy models
%
% val = rmGet(model, param, [options]);
%
% Read the parameters of a retinotopy model. Access to these
% structures should go through this routine and rmSet.
%
% rmGet will return empty ([]) if the parameter is known but not
% defined. In other words, rmGet will only create an error if you
% ask for a parameter that is not known.
%
% 2006/01 SOD: wrote it.
if ~exist('model','var') || isempty(model), error('No model defined.');    end;
if ~exist('param','var') || isempty(param), error('No parameter defined'); end;

% default output
val = [];
% each of these 'switch case' calls is inbedded in a 'try' loop
% so if that when the requested parameter is not defined, rmGet will return
% empty and exit gracefully.
try
    switch lower(param),
        % model
        case {'desc','description'}
            val = model.description;
        case {'x0','x'}
            val = model.x0;
        case {'y0','y'}
            val = model.y0;
        case {'x02','x2'}
            val = model.x02;
        case {'y02','y2'}
            val = model.y02;

        case {'whrf','hrf type'}
            val = model.hrf.type;
        case {'hrfparams','hrf parameters'}
            val = model.hrf.params;
        case {'hrfmax','peak hrf response value'}
            val = model.hrf.maxresponse;
        case {'s','sigma'}
            val = (model.sigma.major + model.sigma.minor)./2;             
            if isfield(model, 'exponent'),
                val = model.sigma.major./sqrt(model.exponent);
            end            
        case {'sigmamajor','sigma major','s_major'}
            val = model.sigma.major;
        case {'sigmaminor','sigma minor','s_minor'}
            val = model.sigma.minor;
        case {'sigmatheta','sigma theta','s_theta'}
            val = model.sigma.theta;
		case {'sigmaratiooval','sigma ratio oval'}
			val  = log10(model.sigma.major./model.sigma.minor);
        case {'s2','sigma2'}
            val = (model.sigma2.major + model.sigma2.minor)./2;
        case {'sigma2major','sigma2 major'}
            val = model.sigma2.major;
        case {'sigma2minor','sigma2 minor'}
            val = model.sigma2.minor;
        case {'sigma2theta','sigma2 theta'}
            val = model.sigma2.theta;
        % Measures for difference of gaussian pRF models, after Zuiderbaan et al JoV 2012
        case {'fwhm', 'sigma2fwhm','fwhmax', 'sigma2fwhmax'}
            [val, tmp1, tmp2, tmp3, tmp4] = rmGetDoGFWHM(model,varargin);               % varargin can contain the coords of the ROI
        case {'surroundsize', 'sigma2surround','dog surround','dog surroundsize'}
            [tmp1, val, tmp2, tmp3, tmp4] = rmGetDoGFWHM(model,varargin);               
        case {'fwhmin_first', 'fwmin1', 'first_fwhmin'}
            [tmp1, tmp2, val, tmp3, tmp4] = rmGetDoGFWHM(model,varargin);               
        case {'fwhmin_second', 'fwmin2', 'second_fwhmin'}
            [tmp1, tmp2, tmp3, val, tmp4] = rmGetDoGFWHM(model,varargin);               
        case {'diffwhmin', 'fwhmin2-1','difference fwhmins','difference fwhmin2 and fwhmin1'}
            [tmp1,tmp2, tmp3, tmp4, val] = rmGetDoGFWHM(model,varargin);                
        case {'allsigma2stats', 'alldogstats'}
            [tmp1, tmp2, tmp3, tmp4, tmp5] = rmGetDoGFWHM(model,varargin);              
            val=[tmp1; tmp2; tmp3; tmp4; tmp5];
            
        case {'si', 'suppression', 'suppressionindex', 'suppression index'}
            [val, tmp1, tmp2, tmp3, tmp4] = rmGetDoGSuppressionIndex(model,varargin);
        case {'volpos', 'volume positive gaussian','volume positive gaussian in stimulus window'}
            [tmp1, val, tmp2, tmp3, tmp4] = rmGetDoGSuppressionIndex(model,varargin);
        case {'volneg', 'volume negative gaussian' , 'volume negative gaussian in stimulus window'}
            [tmp1, tmp2, val, tmp3, tmp4] = rmGetDoGSuppressionIndex(model,varargin);
        case {'volpospRF', 'volume positive part of the pRF in stimulus window'}
            [tmp1, tmp2, tmp3, val, tmp4] = rmGetDoGSuppressionIndex(model,varargin);
       case {'volnegpRF', 'volume negative part of the pRF in stimulus window'}
            [tmp1, tmp2, tmp3, tmp4, val] = rmGetDoGSuppressionIndex(model,varargin);
        case {'allsistats', 'all suppression index stats'}
            [tmp1, tmp2, tmp3, tmp4, tmp5] = rmGetDoGSuppressionIndex(model,varargin);
            val=[tmp1; tmp2; tmp3; tmp4; tmp5];
        case {'volumeratio'} % another suppression index
            val = (abs(rmGet(model,'bcomp2')).*(rmGet(model,'sigma2').^2)) ./ ...
                  (abs(rmGet(model,'bcomp1')).*(rmGet(model,'sigma1').^2));
            
        case {'s_mm' 'sigma in millimeters'}
            vw = getCurView;
            val = rmNeighborsCompare(vw,model);

        case {'r','sr','sigmaratio','sigma ratio'}
            val1 = (model.sigma.major + model.sigma.minor)./2;
            val2 = (model.sigma2.major + model.sigma2.minor)./2;
            val  = val2./val1;
            
        case {'sc','sigmacontrast','sigma ratio contrast'}
            % 0 = same size (not allowed)
            % 1 = maximal contrast (one is zero or Inf)
            val1 = (model.sigma.major + model.sigma.minor)./2;
            val2 = (model.sigma2.major + model.sigma2.minor)./2;
            val = abs(val1-val2) ./ (val1+val2);
            
        case {'latx','laty','laterality x', 'laterality y'}
            dim = lower(param(end));
            % will not work for non-isotropic Gaussians
            val =  0.5.*erfc(rmGet(model,dim)./(rmGet(model,'sigma').*sqrt(2)));

            % fit
        case {'b','beta'}
            val = model.beta;

        case {'bcomp1','bcomp2','bcomp3','bcomp4','bcomp5',...
                'bcomp6','bcomp7','bcomp8','bcomp9'},
            % should really do something a bit better than hard coding the bcomps
            compnumber = str2double(lower(param(end)));
            switch length(size(model.beta))
                case 2
                    val = model.beta(compnumber, :);
                case 3
                    val = model.beta(:,:,compnumber);
                case 4
                    val = model.beta(:,:,:,compnumber);
            end;
            
        case {'br','br12','beta ratio contrast first and second component'},
            % val = rmGet(model,'bcomp2')./rmGet(model,'bcomp1');
            % 1 = equal wieght (regardless of sign), 0 = bcomp2 = 0
            % (or bcomp1 - but that should not be allowed)
            val = 1 - abs(rmGet(model,'bcomp1') - abs(rmGet(model,'bcomp2'))) ./ (abs(rmGet(model,'bcomp2')) + rmGet(model,'bcomp1'));

            
            % fit
        case {'amp','amplitude'}
            val = model.beta;
        case {'amplitude comp1','amplitude comp2',...
                'amplitude comp3','amplitude comp4',}
            compnumber = str2double(lower(param(end)));
            % RFs are scaled by the sigma (constant volume)
            % so if we want to compute the real amplitude we need to take
            % this into account:
            % amplitude = 1./(sigmax*sigmay*2*pi)*beta
            % Don't scale the amplitude so it equals beta.
            %if compnumber == 1,
            %  scalefac = model.sigma.major.*model.sigma.minor.*2.*pi;
            %elseif compnumber == 2,
            %
            %    scalefac = model.sigma2.major.*model.sigma2.minor.*2.*pi;
            %  catch,
            %    scalefac = model.sigma.major.*model.sigma.minor.*2.*pi;
            %  end;
            %else,
            %  scalefac = 1;
            %end;
            scalefac = 1;
            if     length(size(model.beta)) == 3,
                val = model.beta(:,:,compnumber)./scalefac;
            elseif length(size(model.beta)) == 4
                val = model.beta(:,:,:,compnumber)./scalefac;
            end;

        case {'nt','ntrends','number of trends'},
            val = model.beta.ntrends;

            % t-statistical values
        case {'tf','t fullfield','t-statistic fullfield'}
            val = model.t.fullfield;
        case {'trm','t retinotopy','t-statistic retinotopy'}
            val = model.t.retinotopy;
        case {'tall','t all','t-statistic all'}
            val = model.t.all;
        case {'trmf','t rmf','t-statistic retinotopy vs fullfield',...
                't-statistic retinotopy minus fullfield'}
            val = model.t.ret_vs_full;
        case {'t-statistic fullfield vs retinotopy',...
                't-statistic fullfield minus retinotopy'}
            val = model.t.ret_vs_full.*-1;
        case {'t'}
            if isfield(model.t,'all'),
                val = model.t.all;
            elseif isfield(model.t,'retinotopy'),
                val = model.t.retinotopy;
            elseif isfield(model.t,'fullfield'),
                val = model.t.fullfield;
            end;
        case {'position variance 1d', 'pv1', 'pv'}
            view = getCurView;
            val = rmPositionVariance1D(view);
        case {'position variance 2d', 'pv2'}
            view = getCurView;
            val = rmPositionVariance2D(view);
        case {'sigma neuron', 's_neuron'}
            view = getCurView;
            pv = rmPositionVariance2D(view);
            sigma = (model.sigma.major + model.sigma.minor)./2;
            val = sqrt(sigma.^2 - pv.^2);

            % variance explained and coherence
        case {'varexp','varexplained','variance','variance explained', 'varianceexplained', 've'}
            warning('off','MATLAB:divideByZero');
            val = 1 - (model.rss ./ model.rawrss);
            val(~isfinite(val)) = 0;
            val = max(val, 0);
            val = min(val, 1);
        case 'varexpfitprf'
            val = model.varExp;
        case {'coh','coherence'}
            warning('off','MATLAB:divideByZero');
            val = sqrt(rmGet(model,'variance explained'));
        case {'spvarexp','spvarexplained','sign-specified variance explained'}
            val = rmGet(model,'variance explained').*sign(rmGet(model,'bcomp1'));
        case {'spcoh','sign-specified coherence'}
            val = rmGet(model,'coherence').*sign(rmGet(model,'bcomp1'));
        case {'varexp2','varexplained2','variance2','variance explained 2'}
            warning('off','MATLAB:divideByZero');
            val = 1 - (model.rss2 ./ model.rawrss);
            val(~isfinite(val)) = 0;
            val = max(val, 0);
            val = min(val, 1);
        case {'varexppos', 'variance explained positive gaussian'}
            val = 1 - (model.rsspos ./ model.rawrss);
            val(~isfinite(val)) = 0;
            val = max(val, 0);
            val = min(val, 1);
         case {'varexpneg', 'variance explained negative gaussian'}
            val = 1 - (model.rsspos ./ model.rawrss);
            val(~isfinite(val)) = 0;
            val = max(val, 0);
            val = min(val, 1);         
        case {'vr','varexpratio'}
            val = (model.rss - model.rss2)./(model.rss + model.rss2);
        case {'vr2','var1-var2'}
            val = rmGet(model,'varexp')-rmGet(model,'varexp2');   % varexp whole model - varexp 1G model
            
            % p-values
        case {'pf','p fullfield','p-statistic fullfield'}
            val = rmT2P(model.t.fullfield,model.df.glm,'p');
        case {'prm','p retinotopy','p-statistic retinotopy'}
            val = rmT2P(model.t.retinotopy,model.df.glm,'p');
        case {'pall','p all','p-statistic all'}
            val = rmT2P(model.t.all,model.df.glm,'p');
        case {'prmf','p rmf','p-statistic retinotopy vs fullfield',...
                'p-statistic retinotopy minus fullfield'}
            val = rmT2P(model.t.ret_vs_full,model.df.glm,'p');
        case {'p-statistic fullfield vs retinotopy',...
                'p-statistic fullfield minus retinotopy'}
            val = rmT2P(model.t.ret_vs_full,model.df.glm,'p').*-1;
        case {'p'}
            if isfield(model.t,'all'),
                val = rmT2P(model.t.all,model.df.glm,'p');
            elseif isfield(model.t,'retinotopy'),
                val = rmT2P(model.t.retinotopy,model.df.glm,'p');
            elseif isfield(model.t,'fullfield'),
                val = rmT2P(model.t.fullfield,model.df.glm,'p');
            end;

            % log10p-value
        case {'log10pf','log10p fullfield','log10p-statistic fullfield'}
            val = rmT2P(model.t.fullfield,model.df.glm,'log10p');
        case {'log10prm','log10p retinotolog10py','log10p-statistic retinotopy'}
            val = rmT2P(model.t.retinotopy,model.df.glm,'log10p');
        case {'log10pall','log10p all','log10p-statistic all'}
            val = rmT2P(model.t.all,model.df.glm,'log10p');
        case {'log10prmf','log10p rmf','log10p-statistic retinotopy vs fullfield',...
                'log10p-statistic retinotopy minus fullfield'}
            val = rmT2P(model.t.ret_vs_full,model.df.glm,'log10p');
        case {'log10p-statistic fullfield vs retinotopy',...
                'log10p-statistic fullfield minus retinotopy'}
            val = rmT2P(model.t.ret_vs_full,model.df.glm,'log10p').*-1;
        case {'log10p'}
            if isfield(model.t,'all'),
                val = rmT2P(model.t.all,model.df.glm,'log10p');
            elseif isfield(model.t,'retinotopy'),
                try
                    val = rmT2P(model.t.retinotopy,model.df.glm,'log10p');
                catch
                    val = ones(size(model.x0));  % when all else fails...
                end;
            elseif isfield(model.t,'fullfield'),
                try
                    val = rmT2P(model.t.fullfield,model.df.glm,'log10p');
                catch
                    val = ones(size(model.x0)); % when all else fails...
                end;
            end
            
            % other model fits
        case {'rss','residual sum of squares'}
            val = model.rss;

        case {'rss2','residual sum of squares 2'}
            val = model.rss2;

        case {'rawrss','raw sum of squares'}
            val = model.rawrss;

        case {'rawrss2','raw sum of squares 2'}
            val = model.rawrss2;

        case {'rms'}
            val = sqrt(model.rss./model.npoints);

        case {'df','degrees of freedom'}
            if isfield(model.df,'glm'),
                val = model.df.glm;
            elseif isfield(model.df,'glm_corrected'),
                val = model.df.glm_corrected;
            end;
        case {'dfglm','degrees of freedom glm'}
            val = model.df.glm;
        case {'dfcorr','degrees of freedom model corrected'}
            val = model.df.glm_corrected;
            
            % derived spatial values
        case {'ecc','eccentricity'}
            [tmp val] = cart2pol(model.x0, model.y0);
        case {'pol','polar-angle','polar angle','polarangle'}
            val       = cart2pol(model.x0, model.y0);
            val	      = mod(val, 2*pi);
            
        case {'ecc2','eccentricity2'}
            [tmp val] = cart2pol(model.x02, model.y02);
        case {'pol2','polar-angle2','polar angle 2','polarangle2'}
            val       = cart2pol(model.x02, model.y02);
            val	      = mod(val, 2*pi);

		case {'logecc' 'logeccentricity' 'log eccentricity' 'log10 eccentricity'}
			[tmp val] = cart2pol(model.x0, model.y0);
			
			% avoid a divide-by-zero warning, by setting zero eccentricity
			% values to NaN:
			val(val<=0) = NaN;
			val(val>0) = log10( val(val>0) );
        case {'volume', 'max signal'}
            % estimate the maximum signal, in percent change, that could be
            % elicited from the model (assuming a full field stimulus)
            
            % calculate volume under pRF
            sigma = rmGet(model, 'sigma');
            vol = 2*pi*sigma.^2;
            
            % scale volume by betas (first two betas)
            beta = rmGet(model, 'b');
            beta = squeeze(beta(1,:,1:2));
            vol = vol .* beta(:,1)' + beta(:,2)';
            
            % convert to percent signal
            dc   = beta(:,2)';
            val = ((vol./dc) - 1) .*100;

           

		case {'logecc2' 'logeccentricity2'}
            [tmp val] = cart2pol(model.x02, model.y02);

			% avoid a divide-by-zero warning, by setting zero eccentricity
			% values to NaN:
			val(val<=0) = NaN;
			val(val>0) = log10( val(val>0) );

            % others,
            % only get roi coords here to avoid possible confusions
        case {'coords','roicoords'}
            val = model.roi.coords;

        case {'indices','roiindices','roiind','roiindex'}
            val = model.roi.coordsIndex;

        case {'roiname','roi name'},
            val = model.roi.name;

        case {'n','npoints','number of data points'}
            val = model.npoints;

        case 'exponent'
            if isfield(model, 'exponent'),  val = model.exponent;
            else                            val = ones(size(model.sigma.major)); end
            
        otherwise,
            error('[%s]:Unknown parameter: %s.',mfilename,param);
    end;
catch
    val = [];
end

return;
