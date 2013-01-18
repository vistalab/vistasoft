function prfParams = hrfSet(prfParams,hrfParam,varargin)
% hrfSave - save and update HRF parameters in pRF params structure
%
% prfParams = hrfSave(prfParams,hrfParam,valargin)
%
% 2009/03 SOD: wrote it.

if ~exist('prfParams','var') || isempty(prfParams), error('Need prfParams'); end
if ~exist('hrfParam','var') || isempty(hrfParam),   error('Need hrfParam');  end

nScans = length(prfParams.stim);

% loop over options
switch lower(hrfParam)
    case {'hrftype'}
        val = varargin2val(varargin{1},nScans);
        for n = 1:nScans
            switch lower(val{n})
                case {'one gamma (boynton style)','o','one gamma' 'b' 'boynton'}
                    prfParams.stim(n).hrfType = 'one gamma (Boynton style)';
                case {'two gammas (spm style)' 't' 'two gammas' 'spm'}
                    prfParams.stim(n).hrfType = 'two gammas (SPM style)';
                case {'impulse' 'no hrf' 'none'}
                    prfParams.stim(n).hrfType = 'impulse';
            end
        end
        
    case {'hrfparams' 'hrfparam'}
        val = varargin2val(varargin{1},nScans);
        for n = 1:nScans
            switch prfParams.stim(n).hrfType
                case {'one gamma (Boynton style)'}
                    prfParams.stim(n).hrfParams{1} = val{n};
                case {'two gammas (SPM style)'}
                    prfParams.stim(n).hrfParams{2} = val{n};
                
%                 case {'impulse' 'no hrf' 'none'}
%                     prfParams.stim(n).hrfParams{3} = val{n};
                otherwise
            end
        end
        
    case {'hrf'}
        hrfParams = hrfGet(prfParams,'hrfparams');
        for n = 1:nScans
            % compute hrf
            [tmp tmphrf peak] = rfConvolveTC([1 zeros(1,prfParams.stim(n).nFrames-1)],...
                prfParams.stim(n).framePeriod,...
                prfParams.stim(n).hrfType,...
                hrfParams{n});
            
            % we need to store the HRF for each scan because they might have
            % different TRs. All other hrf parameters are independent of the TR.
            prfParams.analysis.Hrf{n}    = tmphrf(:);
            
            % rfConvolveTC normalizes the hrf to the volume of the
            % response. We save the peak amplitude so we can give the output
            % in % BOLD relative to the maximum response as well.
            prfParams.analysis.HrfMaxResponse = peak;
        end;
        
    otherwise
        fprintf(1,'[%s]:Unknown parameter (%s)',mfilename,hrfParam);
end

return


function val=varargin2val(val,nScans)
if ~iscell(val)
    tmp = val;
    val = cell(nScans,1);
    for n = 1:nScans
        val{n} = tmp;
    end
end
return
