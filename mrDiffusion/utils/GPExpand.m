%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Expand an image as per the Gaussian Pyramid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IResult = GPExpand(I)

Wt = [0.0500    0.2500    0.4000    0.2500    0.0500];

dim = size(I);
newdim = dim*2;
IResult = zeros(newdim,class(I)); % Initialize the array in the beginning ..
m = [-2:2];n=m;

switch length(dim)
	case 1
		%% Pad the boundaries.
		I = [ I(1) ;  I ;  I(dim(1))];
		for i = 0 : newdim(1) - 1
			pixeli = (i - m)/2 + 2;  idxi = find(floor(pixeli)==pixeli);
			A = I(pixeli(idxi)) .* Wt(m(idxi)+3);
			IResult(i + 1)= 2 * sum(A(:));
		end
	case 2
		%% Pad the boundaries.
		I = [ I(1,:) ;  I ;  I(dim(1),:) ];  % Pad the top and bottom rows.
		I = [ I(:,1)    I    I(:,dim(2)) ];  % Pad the left and right columns.
		Wt2 = Wt'*Wt;

		for i = 0 : newdim(1) - 1
			for j = 0 : newdim(2) - 1
				pixeli = (i - m)/2 + 2;  idxi = find(floor(pixeli)==pixeli);
				pixelj = (j - m)/2 + 2;  idxj = find(floor(pixelj)==pixelj);
				A = I(pixeli(idxi),pixelj(idxj)) .* Wt2(m(idxi)+3,m(idxj)+3);
				IResult(i + 1, j + 1)= 4 * sum(A(:));
			end
		end
	case 3
		Wt3 = ones(5,5,5);
		for i = 1:5
			Wt3(i,:,:) = Wt3(i,:,:) * Wt(i);
			Wt3(:,i,:) = Wt3(:,i,:) * Wt(i);
			Wt3(:,:,i) = Wt3(:,:,i) * Wt(i);
		end
		
		%% Pad the boundaries
		I2 = zeros(dim+2,class(I));
		I2(2:1+dim(1),2:1+dim(2),2:1+dim(3)) = I;
		I2(1,:,:)=I2(2,:,:);I2(end,:,:)=I2(end-1,:,:);
		I2(:,1,:)=I2(:,2,:);I2(:,end,:)=I2(:,end-1,:);
		I2(:,:,1)=I2(:,:,2);I2(:,:,end)=I2(:,:,end-1);
		I=I2; clear I2;
		
		for i = 0 : newdim(1) - 1
			for j = 0 : newdim(2) - 1
				for k = 0 : newdim(3) - 1
					pixeli = (i - m)/2 + 2;  idxi = find(floor(pixeli)==pixeli);
					pixelj = (j - m)/2 + 2;  idxj = find(floor(pixelj)==pixelj);
					pixelk = (k - m)/2 + 2;  idxk = find(floor(pixelk)==pixelk);
					A = I(pixeli(idxi),pixelj(idxj),pixelk(idxk)) .* Wt3(m(idxi)+3,m(idxj)+3,m(idxk)+3);
					IResult(i + 1, j + 1,k+1)= 8 * sum(A(:));
				end
			end
		end
end
