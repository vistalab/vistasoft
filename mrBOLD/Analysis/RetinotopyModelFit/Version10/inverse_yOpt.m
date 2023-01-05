function yOpt_inv = inverse_yOpt(yOpt,maxLevel)

% calculate inverse transformation of yOpt
% yOpt: transformation from atlas into raw data
% yOpt_inv: transformation from raw data into atlas

Omega=[1 1];
if ieNotDefined('maxLevel')
    maxLevel=7;
end
m=[2^maxLevel 2^maxLevel];
if size(yOpt,1)~=32768
    yOpt=stg2center(yOpt,m,'Py');
end
X=yOpt;
X_uni=getGrid(Omega,m);

% n = length(X)/2;
% mD = [101 101];
% Omega = [1, 1];
% 
% % get pixelsize, pay attention to the change of order from m to mD
% hD = Omega./mD([2,1]);
% % for easier reading
% hD1 = hD(1);
% hD2 = hD(2);
% 
% 
% X1 = X(1:n); X2 = X(n+(1:n));
% % transform grid X to integer grid
% X1 = (1/hD1)*X1 + 0.5;
% X2 = (1/hD2)*X2 + 0.5;
% 
% myX1=reshape(X1,[128 128]);
% myX2=reshape(X2,[128 128]);
% 
% [origX1 origX2]=meshgrid(1:128,1:128);
% origX1=origX1'/128*101;
% origX2=origX2'/128*101;
% 
% newX1=origX1*2-myX1;
% newX2=origX2*2-myX2;
% 
% 
% figure
% subplot(211)
% plot(myX1,myX2,'.')
% subplot(212)
% plot(newX1,newX2,'.')

% yOpt_inv = [(newX1(:)-0.5)*hD1;(newX2(:)-0.5)*hD1];

yOpt_inv = X_uni*2-X;

