function Ecc=resolveLogScalePhaseToEcc(phase,phaseZero,EccZero,noRings)
%   Ecc=resolveLogScalePhaseToEcc(phase,phaseZero,EccZero,noRings)
%   PURPOSE: translate a phaseValue into an eccentricity when the ringmapping was logscaled.
%   (inverse of resolveLogScaleEccToPhase)
%
%--------------------------------------------------------------------------
%   USAGE:  phase       = the phase that needs to be translated,
%           phaseZero   = the lowest phase (or reference phase)
%           EccZero     = the Ecc the phaseZero reflects
%           noRings     = number of stimuli in the ringmapping, usually 8,
%                         importent because noRing makes 2pi
%--------------------------------------------------------------------------
%   HISTORY
%
%   2005.03.14 by Mark Schira mark@ski.org


if nargin<4  %if no noRINGs assume a default of 8 (used at the SKBIC)
    noRings=8;
end

tau=noRings/pi/2;
Ecc=   EccZero* (2.^((phase-phaseZero)*tau));