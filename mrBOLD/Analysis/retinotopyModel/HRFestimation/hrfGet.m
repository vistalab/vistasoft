function val = hrfGet(prfParams,hrfParam)
% hrfGet - get the hrfParameters from each of the scans
%
%   val = hrfGet(params,val)
%
% Brief description:
%   The vistasoft scans have an implicit HRF attached to them.  This
%   function gets the HRF for the parameters attached to a particular
%   scan.
%
% Inputs
%
% Key/value pairs
%   N/A
% 
% Return
%  
% Example:
%   
%
% 2009/03 SOD: modified from readHRFParams
if notDefined('prfParams'), error('prfParams needed'); end
if notDefined('hrfParam'),  error('hrfParam needed');  end

nScans = length(prfParams.stim);

val = [];
switch lower(hrfParam)
    case {'hrfparams'}
        val  = cell(nScans,1);
        for n = 1:nScans
            switch prfParams.stim(n).hrfType
                case 'one gamma (Boynton style)'
                    val{n} = prfParams.stim(n).hrfParams{1};
                case 'two gammas (SPM style)'
                    val{n} = prfParams.stim(n).hrfParams{2};
                case 'impulse'
                    % is this what we want??
                    val{n} = 1;
                otherwise
                    fprintf(1,'[%s]:Unknown hrf type (%s)',mfilename,prfParams.stim(n).hrfType);
            end
        end
        
    case {'hrftype'}
        val  = cell(nScans,1);
        for n = 1:nScans
            val{n} = prfParams.stim(n).hrfType;
        end
        
    otherwise
        fprintf(1,'[%s]:Unknown parameter (%s)',mfilename,hrfParam);
end

end
