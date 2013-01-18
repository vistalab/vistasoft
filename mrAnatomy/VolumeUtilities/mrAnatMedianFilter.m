function imOut = mrAnatMedianFilter(im,ord,padoption)
%
% imOut = mrAnatMedianFilter(im, [ord=14], [padoption='replicate'])
%
% Perform 3-D order-statistic filtering on 26 neighbors.
%
%       ord = 14 <=> median filtering
%       ord = 1 <=> min
%       ord = [1 27] <=> [min max]
%       padoption: same as in padarray
%
% HISTORY:
% Olivier Salvado, Case Western Reserve University, 16Aug04
% 2008.10.15 RFD: copied ordfilt3D code from Matlab file exchange, renamed
% the function, and added some input argument checking.

if ~exist('ord','var')||isempty(ord)
    ord = 14;
end

if ~exist('padoption','var')
    padoption = 'replicate';
end


%%
% special care for uint8
if isa(im,'uint8')
    V = uint8(padarray(im,[1 1 1],padoption));
    S = size(V);
    Vn = uint8(zeros(S(1),S(2),S(3),26));  % all the neighbor
else
    V = single(padarray(im,[1 1 1],padoption));
    S = size(V);
    Vn = single(zeros(S(1),S(2),S(3),26));  % all the neighbor
end

%%
% build the neighboord
Vn(:,:,:,1) = V;
i = 1:S(1); ip1 = [i(2:end) i(end)]; im1 = [i(1) i(1:end-1)];
j = 1:S(2); jp1 = [j(2:end) j(end)]; jm1 = [j(1) j(1:end-1)];
k = 1:S(3); kp1 = [k(2:end) k(end)]; km1 = [k(1) k(1:end-1)];

%%
% left
Vn(:,:,:,2)     = V(im1    ,jm1    ,km1);
Vn(:,:,:,3)     = V(im1    ,j      ,km1);
Vn(:,:,:,4)     = V(im1    ,jp1    ,km1);

Vn(:,:,:,5)     = V(im1    ,jm1    ,k);
Vn(:,:,:,6)     = V(im1    ,j      ,k);
Vn(:,:,:,7)     = V(im1    ,jp1    ,k);

Vn(:,:,:,8)     = V(im1    ,jm1    ,kp1);
Vn(:,:,:,9)     = V(im1    ,j      ,kp1);
Vn(:,:,:,10)    = V(im1    ,jp1    ,kp1);

%%
% right
Vn(:,:,:,11)    = V(ip1    ,jm1    ,km1);
Vn(:,:,:,12)    = V(ip1    ,j      ,km1);
Vn(:,:,:,13)    = V(ip1    ,jp1    ,km1);

Vn(:,:,:,14)    = V(ip1    ,jm1    ,k);
Vn(:,:,:,15)    = V(ip1    ,j      ,k);
Vn(:,:,:,16)    = V(ip1    ,jp1    ,k);

Vn(:,:,:,17)    = V(ip1    ,jm1    ,kp1);
Vn(:,:,:,18)    = V(ip1    ,j      ,kp1);
Vn(:,:,:,19)    = V(ip1    ,jp1    ,kp1);

%%
% top
Vn(:,:,:,20)    = V(i       ,jm1    ,kp1);
Vn(:,:,:,21)    = V(i       ,j      ,kp1);
Vn(:,:,:,22)    = V(i       ,jp1    ,kp1);

%%
% bottom
Vn(:,:,:,23)    = V(i       ,jm1    ,km1);
Vn(:,:,:,24)    = V(i       ,j      ,km1);
Vn(:,:,:,25)    = V(i       ,jp1    ,km1);

%%
% front
Vn(:,:,:,26)    = V(i       ,jp1    ,k);

%%
% back
Vn(:,:,:,27)    = V(i       ,jm1    ,k);

%%
% perform the processing
Vn = sort(Vn,4);
imOut = Vn(:,:,:,ord);


%%
% remove padding on the 3 first dimensions
imOut = imOut(2:end-1,2:end-1,2:end-1,:);
