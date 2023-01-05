function imwrite2D(Tc,m,file,colmap)

if ~exist('colmap','var'), colmap = [];  end;
TD = reshape(Tc,m);
TD = permute(TD,[2,1]);
TD = flipdim(TD,1);

if isempty(colmap),
  imwrite(uint8(TD),[file,'.jpg'],'quality',100);
else
  imwrite(uint8(TD),colmap,[file,'.jpg'],'quality',100);
end;

return;