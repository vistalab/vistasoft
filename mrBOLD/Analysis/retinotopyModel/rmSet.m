function model = rmSet(model,param,val)
% rmSet - Set data from various retinotopy models
%
% model = rmGet([model[,param[,val]]]);
%
% Set the parameters of a retinotopy model. Access to these
% structures should go through this routine and rmGet.
%
% If no inputs are given, rmSet will create a model, with the primary
% parameters defined but empty.
%
% 2006/01 SOD: wrote it.


if nargin == 0,
	% initiate model, bit circular but useful
	model.description = 'init';
	model = rmSet(model,'x0');
	model = rmSet(model,'y0');
	model = rmSet(model,'sigma');
	return;
else
	% set a specific parameter
	if ieNotDefined('model'), error('model not defined');    end;
	if ieNotDefined('param'), error('param not defined');    end;
	if ieNotDefined('val'),   val = [];                      end;
end;


switch lower(param),
	% model
	case {'desc','description'}
		model.description = val;
	case {'x0','x'}
		model.x0          = val;
	case {'y0','y'}
		model.y0          = val;
        
	case {'x02','x2'}
		model.x02         = val;
	case {'y02','y2'}
		model.y02         = val;

	case {'pol' 'polar-angle' 'polar angle' 'theta'}
		e = rmGet(model, 'ecc');		
		[x,y] = pol2cart(val,e);
		model = rmSet(model,'x0',x);
		model = rmSet(model,'y0',y);
		
	case {'ecc' 'eccentricity' 'r'}
		p = rmGet(model, 'polar-angle');
		[x,y] = pol2cart(p, val);
		model = rmSet(model,'x0',x);
		model = rmSet(model,'y0',y);		

		% hrf is part of the model too
	case {'whrf','hrf type'}
	model.hrf.type   = val;
	case {'hrfparams','hrf parameters'}
		model.hrf.params = val;
	case {'hrfmax','peak hrf response value'}
		model.hrf.maxresponse = val;

	case {'s','sigma'}
		model.sigma.major = val;
		model.sigma.minor = val;
		model.sigma.theta = zeros(size(val));
	case {'sigmamajor','sigma major','s_major'}
		model.sigma.major = val;
        % This change came with the fix Ben Harvey sent to Brian. Remove it to
        % check if now Theta fiixes are returned in one oval gaussian 
        % model.sigma.theta = zeros(size(val));
	case {'sigmaminor','sigma minor','s_minor'}
		model.sigma.minor = val;
	case {'sigmatheta','sigma theta','s_theta'}
		model.sigma.theta = val;

	case {'s2','sigma2'}
		model.sigma2.major = val;
		model.sigma2.minor = val;
		model.sigma2.theta = zeros(size(val));
	case {'sigma2major','sigma2 major'}
		model.sigma2.major = val;
	case {'sigma2minor','sigma2 minor'}
		model.sigma2.minor = val;
	case {'sigma2theta','sigma2 theta'}
		model.sigma2.theta = val;

    case {'exponent'}
        model.exponent = val;
        
		% fit
    case {'b', 'beta'}
        model.beta            = val;
    case {'bcomp1','bcomp2','bcomp3','bcomp4','bcomp5',...
            'bcomp6','bcomp7','bcomp8','bcomp9'},
        % should really do something a bit better than hard coding the bcomps
        compnumber = str2double(lower(param(end)));

        dimsize = numel(size(model.x0));
        if     dimsize == 2
            model.beta(:,:,compnumber) = val;
        elseif dimsize == 3
            model.beta(:,:,:,compnumber) = val;
        else
            disp(sprintf('[%s]:ERROR:Unknown dimension size (%d).',...
                mfilename,dimsize));
        end;

    case {'nt','ntrends','number of trends'},
        model.ntrends        = val;
	case {'rss','residual sum of squares'}
		model.rss             = val;
	case {'rss2','residual sum of squares 2'}
		model.rss2            = val;
    case {'rsspos','residual sum of squares positive'}
		model.rsspos            = val;
    case {'rssneg','residual sum of squares negative'}
		model.rssneg            = val;
	case {'rawrss','raw residual sum of squares'}
		model.rawrss          = val;
	case {'rawrss2','raw residual sum of squares 2'}
		model.rawrss2          = val;
	case {'df','degrees of freedom'}
		model.df.glm          = val;
		model.df.glm_corrected= val;
	case {'dfglm','degrees of freedom glm'}
		model.df.glm          = val;
	case {'dfcorr','degrees of freedom model corrected'}
		model.df.glm_corrected= val;

		% t-statistical values
	case {'tf','t fullfield','t-statistical fullfield'}
		model.t.fullfield     = val;
	case {'trm','t retinotopy','t-statistical retinotopy'}
		model.t.retinotopy    = val;
	case {'tall','t all','t-statstical all'}
		model.t.all           = val;
	case {'trmf','t rmf','t-statstical retintopy vs fullfield'}
		model.t.ret_vs_full   = val;

		% others
	case {'coords','roicoords'}
		model.roi.coords = val;
    case {'indices','roiindices','roiind','roiindex'}
        model.roi.coordsIndex = val;
    case {'roiname','roi name'}
        model.roi.name = val;
	case {'n','npoints','number of data points'}
		model.npoints         = val;

	otherwise,
		error('Unknown parameter: %s',param);

end;
