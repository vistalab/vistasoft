dt = dtiLoadDt6('dti40/dt6');

[vec,val] = dtiEig(dt.dt6);
% Avoid negative eigenvalues
val(repmat(dt.brainMask,[1 1 1 3]) & val<=0) = 1;

doLog = true;
if(doLog)
    val = log(val);
end
logDt6 = dtiEigComp(vec,val);
if(~isreal(logDt6)), error('logDt6 can''t be complex!'); end

p = 1;
for(x=[-1:1])
    for(y=[-1:1])
        for(z=[-1:1])
            % Don't store 0,0,0
            if(any([x y z]))
                neigh(:,:,:,:,p) = circshift(logDt6,[x y z 0]);
                p = p+1;
            end
        end
    end
end

N1 = size(neigh,5);
N2 = 1;
N = N1+N2;
M1 = mean(neigh,5);
M2 = logDt6;
M = (N1*M1 + N2*M2)/N;
[V1,L1] = dtiEig(M1);
[V2,L2] = dtiEig(M2);
[V,L] = dtiEig(M);
coh = N * sum(((N1*L1 + N2*L2)/N).^2 - L.^2, 4);
% We need to normalize it it to make a nice image. Armin claims that
% THis metric is chi-square distributed. So, try linearizing with chi2inv.
df = 3; % for a tensor with 6 unique elements, df = 3
coh(coh>0.2)=0.2;
cohIm = chi2inv(coh,df);
showMontage(smooth3(cohIm,'gaussian'));


