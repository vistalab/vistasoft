function ph = unwrapPhases(ph)
% NOTE- this algorithm WILL FAIL if the first data point is anomalous!

if(~iscell(ph))
    tmpPh = {ph};
else
    tmpPh = ph;
end

stepThresh = pi;
for(ii=1:length(tmpPh))
%     if(tmpPh{ii}(1)>stepThresh)
%         tmpPh{ii}(1) - 2*pi;
%     end
    for(jj=2:length(tmpPh{ii}))
        diff = tmpPh{ii}(jj)-tmpPh{ii}(jj-1);
        if(diff>stepThresh)
            tmpPh{ii}(jj) = tmpPh{ii}(jj)-2*pi;
        elseif(diff<-stepThresh)
            tmpPh{ii}(jj) = tmpPh{ii}(jj)+2*pi;
        end
    end
end

if(~iscell(ph))
    ph = tmpPh{1};
else
    ph = tmpPh;
end

return;
