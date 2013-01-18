function [volco, volph, dataRange] = mrLoadCoPhVol(fname); 
%
% mrLoadCoPhVol
%
%	[volco, volph, dataRange] = mrLoadCoPhVol(fname);
%	
%	Loads in correlation and phase data and reformats them from
%	their stored range which was 0:255*256 to save space.
%
%

str = ['load ',fname];
eval(str);

volco(volco==0) = NaN*ones(1,sum(volco==0));
volph(volph==0) = NaN*ones(1,sum(volph==0));
volco = (volco-1)/(254*256);
volph = ((volph-1)/(254*256))*2*pi-pi;

