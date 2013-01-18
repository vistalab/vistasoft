dt=dtiLoadDt6('/biac3/wandell4/data/reading_longitude/dti_adults/ah080521_sense/dtifs06/dt6.mat');

% Ensure PDness:
  [eigVec, eigVal] = dtiEig(dt.dt6);
  %clear dt;
  eigVal(eigVal<0) = 0;
  % We'll clip the eigenvalues to be >=.5% of the max
  % eigenvalue. This should ensure that all the eigenvalues are
  % large enough to avoid singularity in the calculations below.
  % Note that this will also clip the FA to a max of 0.998.
  minVal = max(eigVal(:))*.005;
  eigVal(eigVal<minVal) = minVal;
  md = mean(eigVal,4);
  md = mean(md(logical(dt.brainMask(:))));
  % fill air voxels with isotropic tensors of mean brain diffusivity
  eigVal(repmat(~dt.brainMask,[1 1 1 3])) = md;
  dt6 = dtiEigComp(eigVec, eigVal);
  clear eigVal eigVec;
  D = dti6to33(dt6);
  clear dt6;
  if(p>1)
	% Raise D to the specified (INTEGER!) power 'p' (.^p, not ^p)
	for(jj=1:p)
	  D = D.*D;
	end
  end
  % Compute the determinant of D
  % det(D) for a 3x3 [a b c; d e f; g h i] is: (aei+bfg+cdh)-(gec+hfa+idb)
  % a=1,1; b=1,2; c=1,3; d=2,1; e=2,2; f=2,3; g=3,1; h=3,2; i=3,3;
  detD = (D(:,:,:,1,1).*D(:,:,:,2,2).*D(:,:,:,3,3) ...
          + D(:,:,:,1,2).*D(:,:,:,2,3).*D(:,:,:,3,1) ...
          + D(:,:,:,1,3).*D(:,:,:,2,1).*D(:,:,:,3,2)) ...
		 -(D(:,:,:,3,1).*D(:,:,:,2,2).*D(:,:,:,1,3) ...
		   + D(:,:,:,3,2).*D(:,:,:,2,3).*D(:,:,:,1,1) ...
		   + D(:,:,:,3,3).*D(:,:,:,2,1).*D(:,:,:,1,2));
  iD = shiftdim(ndfun('inv',shiftdim(D,3)),2);
  % normalize so sum(eigVal)==1
  tr = iD(:,:,:,1,1)+iD(:,:,:,2,2)+iD(:,:,:,3,3)+1e-12;
  for(jj=1:9)
	iD(:,:,:,jj) = iD(:,:,:,jj)./tr;
  end
  clear tr;
  scale = (4*pi*t)^1.5 .* sqrt(detD)+1e-12;
  % Compute the kernel for each voxel.
  for(xx=[-1:1])
	for(yy=[-1:1])
	  for(zz=[-1:1])
		x = [xx yy zz];
		%Kt(:,:,:,2+xx,2+yy,2+zz) = exp(-x*iD*x'./(4*t))/((4*pi*t)^(3/2)*(det(D))^0.5);
		s = shiftdim(ndfun('mult',ndfun('mult',x,shiftdim(iD,3)),x'),2);
		Kt(:,:,:,2+xx,2+yy,2+zz) = exp(-s./(4.*t)) ./ scale;
	  end
	end
  end
  clear scale s;
  % Normalize the kernel to have unit volume
  scale = sum(sum(sum(Kt,6),5),4);
  for(jj=1:27)
	Kt(:,:,:,jj) = Kt(:,:,:,jj)./scale;
  end
  clear scale;
  % Apply the kernel to each of the raw data in 's'
  for(jj=1:numel(s))
	d = padarray(double(s(jj).imData),[1 1 1],'replicate','both');
	tmp = zeros(sz(1:3));
	for(xx=[1:3])
	  for(yy=[1:3])
		for(zz=[1:3])
		  e = sz(1:3)+[xx yy zz]-1;
		  tmp = tmp+Kt(:,:,:,xx,yy,zz).*d(xx:e(1),yy:e(2),zz:e(3));
		end
	  end
	end
	s(jj).imData = tmp;
  end
  toc;
end