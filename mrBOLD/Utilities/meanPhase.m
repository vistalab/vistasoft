function [mn,sd,rng] = meanPhase(ph)
%
%   [mn,sd,rng] = meanPhase(ph)
%
%Author: Wandell, Brewer
%Purpose:
%    Compute the  mean and standard deviation of phase data by moving into
%    complex coordinates and  averaging there, rather than in radians. If
%    the input data, ph, are between [0,2pi] it is returned between
%    [0,2pi].
%
%    N.B. We are not happy with the range computation.  It would be better to
%    have a percentile when there are enough data points to support.  We
%    left is as a range because sometimes there are only half a dozen
%    points.
%
%  coords = getCurROIcoords(FLAT{1});
%  ph = getCurDataROI(FLAT{1},'ph',1,coords);
%  [mn,sd,rng] = meanPhase(ph);

cxph = exp(sqrt(-1).*ph);
mn = mean(cxph);
mn = angle(mn);

% Matlab puts the angle values between [-pi,pi].  But we keep our data
% between 0 and 2pi.  So, we put them back into [0,2pi] if the input had no
% negative values.
if min(ph(:)) >= 0 & max(ph(:)) <= 2*pi
    if mn < 0
        mn = mn + 2*pi;
    end
end

if nargout >= 2,  sd = std(cxph); end
if nargout >= 3
    % Center the complex phases around the value of pi
    tmp = cxph*exp(sqrt(-1)*(-mn));
    % Find the range of the angles
    tmp = angle(tmp);
    rng = max(tmp(:)) - min(tmp(:));
end

return;


