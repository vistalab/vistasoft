function [volco,volph] =  mrInitCoPhVol(co,ph,rot,trans,scaleFac,inpSize, ...
				anatmap,sagSize,whichcos,dataRange);
%
% MRINITCOPHVOL
%
%     [volco,volph] =  mrInitCoPhVol(co,ph,rot,trans,scaleFac,inpSize, ...
%			anatmap,sagSize, whichcos,dataRange);
%
%	Formats the co and ph data into the volume anatomy coordinate
%	frame by repeatedly sampling it.  May do interpolation, if global
%	interpflag is set.  Whichcos is a vector containing the experiment
%	numbers to include.
%

global interpflag;

interpflag = 0;

% We are rotating the reverse of the "usual direction"

rot = inv(rot);
trans = -trans;

% Only use the relevant parts of co and ph.

co = co(whichcos,:);
ph = ph(whichcos,:);
anatmap = anatmap(whichcos);
inpZsize = length(anatmap);

% Reorder co and ph to follow increasing anatomical order
[srt,ord] = sort(anatmap);
co = co(ord,:);
ph = ph(ord,:);

% Reformat co and ph so that volume sampling routines work.

co = reshape(co',1,prod(size(co)));
ph = reshape(ph',1,prod(size(ph)));
sinph = sin(ph);
cosph = cos(ph);

volco = zeros(dataRange(2)-dataRange(1)+1,prod(sagSize));
volph = zeros(dataRange(2)-dataRange(1)+1,prod(sagSize));

% Sample each anatomical slice from the co and ph data

[xs,ys] = meshgrid([1:sagSize(2)],[1:sagSize(1)]);
xs = reshape(xs,1,prod(sagSize));
ys = reshape(ys,1,prod(sagSize));

for theSlice = dataRange(1):dataRange(2)
	disp(theSlice);
	zs = ones(1,prod(sagSize))*theSlice;
	samp = [xs;ys;zs]';

	nusamp = samp'./(ones(prod(sagSize),1)*(scaleFac(2,:)))';

	nusamp = nusamp+(trans'*ones(1,length(nusamp)));
	nusamp = (rot*nusamp)';

	%Convert back from millimeters

	nusamp = nusamp.*(ones(prod(sagSize),1)*scaleFac(1,:));

	dum = theSlice-dataRange(1)+1;
	rang = [1,inpZsize];
	tmp = mrExtractImgVol(co,inpSize,inpZsize,nusamp,rang,NaN);
	volco(dum,:) = tmp';

	volsin = mrExtractImgVol(sinph,inpSize,inpZsize,nusamp,rang,NaN)';
	volcos = mrExtractImgVol(cosph,inpSize,inpZsize,nusamp,rang,NaN)';

	volph(dum,:) = atan2(volsin,volcos);
end

volco = reshape(volco',1,prod(size(volco)));
volph = reshape(volph',1,prod(size(volph)));

%volco = round(volco*254*256)+1;  % co is 0 to 1
%volco(isnan(volco)) = zeros(1,sum(isnan(volco)));
%volph = round(((volph+pi)/(2*pi))*254*256)+1; %ph is -pi to pi
%volph(isnan(volph)) = zeros(1,sum(isnan(volph)));

%save volco volco volph sagSize dataRange
