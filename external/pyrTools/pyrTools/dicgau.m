
siz = 512;
rad = 36;

% Find the maximum

imm = im;
imt = imm;
fil = zeros( siz, siz );

[val ind] = max( imt(:) );

while (val > 0)

x = floor( (ind-1) / siz ) + 1;
y = mod  ( (ind-1),  siz ) + 1;

fil = fil + mkCircMask( rad, [siz siz], [x y] ) .* val;

imt = imm - fil;
imt = imt.*(imt > 0);

[val ind] = max( imt(:) );

end

fmax = fil;

% Find the minimum

imm = max(max(im)) - im;
imt = imm;
fil = zeros( siz, siz );

[val ind] = max( imt(:) );

while (val > 0)

x = floor( (ind-1) / siz ) + 1;
y = mod  ( (ind-1),  siz ) + 1;

fil = fil + mkCircMask( rad, [siz siz], [x y] ) .* val;

imt = imm - fil;
imt = imt.*(imt > 0);

[val ind] = max( imt(:) );

end

fmin = max(max(im)) - fil;
