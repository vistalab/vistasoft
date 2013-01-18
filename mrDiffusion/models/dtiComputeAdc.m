function adc = dtiComputeAdc(b0, dwi, bval)
%
%
%
%
%
%

offset = 1e-6;
b0 = double(b0);
dwi = double(dwi);
if(size(b0,4)>1)
    b0 = mean(b0,4);
end

logB0 = log(b0+offset);

sz = size(dwi);
adc = zeros(sz);
if(numel(sz)>2)
    for(ii=1:sz(4))
        logDw = log(dwi(:,:,:,ii)+offset);
        adc(:,:,:,ii) = -1./bval(ii).*(logDw-logB0);
    end
else
    for(ii=1:sz(2))
        logDw = log(dwi(:,ii)+offset);
        adc(:,ii) = -1./bval(ii).*(logDw-logB0);
    end
end

return