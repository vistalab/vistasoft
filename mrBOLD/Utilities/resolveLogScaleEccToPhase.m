function phase=resolveLogScaleEccToPhase(Ecc,phaseZero,EccZero,noRings)

%   phase=resolveLogScaleEccToPhase(Ecc,phaseZero,EccZero,noRings)
%   PURPOSE: find the phase an eccentricity reflects when the ringmapping was logscaled.
%   (inverse of resolveLogScalePhaseToEcc)
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

tau=noRings/pi/2;
phase=(log2(Ecc/EccZero)/tau)+phaseZero; 