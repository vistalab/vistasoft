function RD = smoothData(RD,maxSize);

while any(size(RD)>maxSize),
  ee = size(RD);
  if ee(1) - 2*floor(ee(1)/2) ~= 0, ee(1) = ee(1) -1;  end;
  RD = 0.5*(RD(1:2:ee(1),:,:) + RD(2:2:ee(1),:,:));

  if ee(2) - 2*floor(ee(2)/2) ~= 0, ee(2) = ee(2) -1;  end;
  RD = 0.5*(RD(:,1:2:ee(2),:) + RD(:,2:2:ee(2),:));    

  if length(ee) > 2,
    if ee(3) - 2*floor(ee(3)/2) ~= 0, ee(3) = ee(3) -1;  end;
    RD = 0.5*(RD(:,:,1:2:ee(3)) + RD(:,:,2:2:ee(3)));    
  end;
end;

return;