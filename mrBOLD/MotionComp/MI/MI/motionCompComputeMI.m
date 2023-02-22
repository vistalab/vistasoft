function MI = motionCompComputeMI(H,normalize)
%
%    MI = motionCompComputeMI(H, [normalize])
%
% gb 02/22/05
%
% Computes the value of the mutual information given a joint histogram H

if ieNotDefined('normalize')
    normalize = 0;
end

% Normalizes the joint histogram
H  = H + eps;
H  = H/sum(H(:));

% Computes the mutual information
m  = H.*log2(H./(sum(H,2)*sum(H,1)));

% Normalizes the mutual information
% if normalize
% 	ha = -sum(sum(H,2).*log2(sum(H,2)));
% 	hb = -sum(sum(H,1).*log2(sum(H,1)));
% 	normalize = min(ha,hb);
% 	MI  = sum(m(:))/normalize;
% else
%     MI = sum(m(:));
% end

if normalize
	ha = sum(sum(H,2).*log2(sum(H,2)));
	hb = sum(sum(H,1).*log2(sum(H,1)));
	
    MI = (ha + hb) / (2*sum(sum(H.*log2(H))));
else
    MI = sum(m(:));
end