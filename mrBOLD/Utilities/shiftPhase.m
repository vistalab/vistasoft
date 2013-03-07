function shiftedData = shiftPhase(data,phShift)
%
%   shiftedData = shiftPhase(data,phShift)
%
% Author: Wandell, Brewer
% Purpose:
%    This routine circularly shifts phase data, as if they were on a circle
%    in complex phase space.  This shifting is often necessary to avoid the problems
%    with phase wrapping at 0 and 2pi.  Use this routine rather than
%    applying mod to the data.
%
%    The size of the phase shift is determined by the second parameter,
%    phShift.
%
%    The call shiftPhase(pi/2,pi/2)  produces a result of pi
%    The call shiftPhase(pi/2,-pi/2) produces a result of 0.
%
%    data may be a number, a vector, or a matrix.
%    data = ones(3,3)*pi; shiftPhase(data,-pi/2)


cxPhShift = exp(sqrt(-1)*phShift);
cxData = exp(sqrt(-1).*data);
shiftedData = angle(cxData.*cxPhShift);

return;
