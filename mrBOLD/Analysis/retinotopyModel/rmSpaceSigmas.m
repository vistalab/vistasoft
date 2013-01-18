function [s, linstep] = rmSpaceSigmas(params)
% rmSpaceSigmas - This function spaces sigma-values for the grid-seach. 
%
% V1 to V3 sigmas are between 0.1 to 3deg so we need to tile this space more
% carefully. So we tile the space linearly between 0 to about 3 deg and
% afterwards we use a log scale. We also put more samples in the 0-3 range.
%
% 2011/06 BMH & SOD: split off from rmDefineParameters

minRF = params.analysis.minRF;
maxRF = params.analysis.maxRF;
nSigmas = params.analysis.numberSigmas;
whichmethod = params.analysis.spaceSigmas;
switch lower(whichmethod)
    case {'linlog','2 step','default'}
        % two scenarios:
        border = 3.5;
        if maxRF <= border,
            s = linspace(minRF,maxRF,nSigmas);
        else
            % ratio to put in first 3deg sigmascoarseBlurParams
            r  = border/maxRF;
            if r<params.analysis.linlogcutoff, 
                r=params.analysis.linlogcutoff;
            end;

            % ratio for linear and log side
            h1 = floor(nSigmas.*r);
            h2 = ceil(nSigmas.*(1-r));

            % linear
            tmp = linspace(minRF,border,h1+1);
            s(1:h1) = tmp(1:end-1);
            linstep = mean(diff(tmp));

            % log
            s(h1+1:h1+h2) = logspace(log10(border),log10(maxRF),h2);
        end
    case {'log','logarithmically'}
        s = logspace(log10(minRF),log10(maxRF),nSigmas);
    case {'lin','linear'}
        s = linspace(minRF,maxRF,nSigmas);
    otherwise
        error('Unknown scaling method:%s.',whichmethod);
end
return;


