function [HLF,Wf]=hlfCompute(t1,pd,xform,outDir,mField)
%Calculate hydration layer fraction (HLF) and water fraction maps
%
%  [HLF,Wf]=hlfCompute(t1,pd,xform,outDir,mField)
%
% t1: Anatomical
% pd: Proton density
% xform:
% outDir:
% mField:  Magnetic field (B0) level
%
%


%% Check input arguments

%% Define the pd of water PDw by a mask on T1
% We use the values that have a high T1 of CSF also we are note using any pd
% value that is smaller then the mean of PD. The PD of water is by
% definition HIGH!. is i'm note using this treshold then there is a tail of
% very low pd values that are probably just noise

c= find( t1>2.5 & t1<max(t1(:))) & (pd > mean(pd(find(pd))));

%you can try that to see the distribution of PD try that:
%   figure;hist(pd(c),100)
%if the mean is note use then the distribusion is problemtic
%  figure;hist(pd(c),100)
Pdw=median(pd1(c));


%% The water farction is WF = PD / PDw.

mask(find(pd));
Wf=zeros(size(t1));

Wf(mask)=pd(mask)./Wf;
clean noise fits
Wf(isnan(Wf))=0;
Wf(isinf(Wf))=0;
Wf(find(Wf>1))=1;

% The Larmor frequency for the given magnetic field
if mField==3, L=127.6;      % 3T
elseif mField==1.5, L=64;   % 1.5T
else
    display('Unknown magnetic field')
    return
end;

% The T1 value is modeled as a weighted sum of two fast exchanging pools; a
% free pool (with T1f=~3.2 sec) and a hydration pool (T1h).
% 1/T1=fh/T1h+ (1-fh)/T1f
% T1h is estimated as a linear function of the magnetic field (Fullerton
% 1984). T1h=1.83 x f + 25, where f is the Larmor frequency for the given magnetic field. Rearranging the equation above, the water fraction (fh) is given by:
% fh= (1/T1-1/T1f) x (1/T1h-1/T1f).

fh=zeros(size(t1));
fh(mask)=(1./t1(mask)- 1/3.2)./(1000./(1.83.*L+25.02)-1/3.2);

%% The HLF map is calculated from HLF= fh x WF.
HLF=zeros(size(t1));
HLF(mask)=Wf(mask).*fh(mask);

%% Clean noise
HLF(isnan(HLF))=0;
HLF(isinf(HLF))=0;
HLF(find(HLF>.5))=0;

%% Output

dtiWriteNiftiWrapper(single(HLF), xform, fullfile(outDir,'HLF.nii.gz'));
dtiWriteNiftiWrapper(single(Wf), xform, fullfile(outDir,'Wf.nii.gz'));

return

