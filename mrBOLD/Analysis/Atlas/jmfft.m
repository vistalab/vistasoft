 function [u1,u2] = jmfft(what,para,rhs1,rhs2,varargin);
%----------------------------------------------------------------------
% A   = F*|D11,D12| * F' /(m*n)
%         |D21,D22|    
%
% F   = |1 0| o Fn o Fm
%       |0 1|
%
% Fm  = exp(-i*2*pi/m * (0:m-1 )'*(0:m-1) );
% Fn  = exp(-i*2*pi/n * (0:n-1 )'*(0:n-1) );
% FoF = kron(Fn,Fm);
%
% HISTORY:
%   2001.07.03: donated by Bernd Fischer <fischer@math.mu-luebeck.de>
%----------------------------------------------------------------------

  version = '18-Sep-00';

  persistent FFT
  if ~exist('FFT','var'), FFT = []; end;

  switch what,
  case 'init',
    %fprintf('<%s> init FFT\n',mfilename);
    %fprintf('%-20s: %s\n','BC',para.BC);
    %fprintf('%-20s: %f\n','mu',para.mu);
    %fprintf('%-20s: %f\n','lambda',para.lambda);
    %fprintf('%-20s: %dx%d\n','rhs (2x)',para.m,para.n);
    FFT = initFFT(FFT,para);
    return;

  case 'scale'
    scale = rhs1;
    FFT.iD1 =  FFT.iD1/scale;
    FFT.iD2 =  FFT.iD2/scale;
    FFT.iD3 =  FFT.iD3/scale;
    FFT.iD4 =  FFT.iD4/scale;
       

  case 'solve',
    % ------------------------------------------------------------
    % computing g = F'*[f1;f2]
    % ------------------------------------------------------------
    u1  = fft2(rhs1);
    u2  = fft2(rhs2);
    % ------------------------------------------------------------
    % computing v = invD*[u1;u2]
    % v1 = D1.*u1 + D2.*u2
    % v2 = D3.*u1 + D4.*u2
    % ------------------------------------------------------------
    rhs1  = FFT.iD1.*u1 + FFT.iD2.*u2;
    rhs2  = FFT.iD3.*u1 + FFT.iD4.*u2;   
    % ------------------------------------------------------------
    % computing g = F*[f1;f2]
    % ------------------------------------------------------------
    u1 = ifft2(rhs1);
    u2 = ifft2(rhs2);
    max_real_u1 = max(max(abs(real(u1))));
    max_real_u2 = max(max(abs(real(u2))));
    max_imag_u1 = max(max(abs(imag(u1))));
    max_imag_u2 = max(max(abs(imag(u2))));

    if max_real_u1 > 0,
      max_imag1 = max_imag_u1/max_real_u1;
    else
      max_imag1 = max_imag_u1;
    end;

    if max_real_u2 > 0,
      max_imag2 = max_imag_u2/max_real_u2;
    else
      max_imag2 = max_imag_u2;
    end;

    if max(max_imag1,max_imag2) > 1e-12,
      error('complex u1 or u2')
    end;
    u1 = real(u1);    
    u2 = real(u2);    

  case 'clear',
    clear FFT

  %--------------------------------------------------------------------
  % switch
  end;
  %--------------------------------------------------------------------
return;
%----------------------------------------------------------------------





%----------------------------------------------------------------------
 function FFT = initFFT(FFT,para);
%function FFT = initFFT(FFT,para)
  m  = para.m; 
  n  = para.n;
  mn = m*n;
  i  = sqrt(-1);
    
  if n<3 | m<3, 
    fprintf('m=%d, n=%d, better > 2\n',m,n);
    error('#1')
  end;

  dm = log(m)/log(2);
  if abs(dm - round(dm))>1e-9,
    fprintf('<emfft.m> m = %d, better m: = 2^q\n',m);  
    error('#2')
  end;
  dn = log(n)/log(2);
  if abs(dn - round(dn))>1e-9,
    fprintf('<emfft.m> n = %d, better n: = 2^q\n',n);  
    error('#3')
  end;

  omega_m = exp(-i*2*pi/m*[0:m-1]');
  omega_n = exp(-i*2*pi/n*[0:n-1]');

  % ------------------------------------------------------------
  % computing D = P'*F'*A*F/(M*N)' = diag(dj,j=1,...m*n), 
  % dj = [d11,d12;d21,d22]
  % lambdapq = S^p_(2,q)+S^p_(3,q)*conj(omega_m)+S^p_(1,q)*omega_m
  % Dp       = lambdap2 +lambdap3 *conj(omega_n)+lambdap1 *omega_n
  % ------------------------------------------------------------

  [D11,D12,D21,D22] = setstars(para.mu,para.lambda);

  lambda1 = D11(2,1) + D11(3,1)*conj(omega_m) + D11(1,1)*omega_m;
  lambda2 = D11(2,2) + D11(3,2)*conj(omega_m) + D11(1,2)*omega_m;
  lambda3 = D11(2,3) + D11(3,3)*conj(omega_m) + D11(1,3)*omega_m;
    
  D1  = kron(ones(n,1),lambda2)+...
        kron(conj(omega_n),lambda3)+kron(omega_n,lambda1);

  lambda1 = D12(2,1) + D12(3,1)*conj(omega_m) + D12(1,1)*omega_m;
  lambda2 = D12(2,2) + D12(3,2)*conj(omega_m) + D12(1,2)*omega_m;
  lambda3 = D12(2,3) + D12(3,3)*conj(omega_m) + D12(1,3)*omega_m;

  D2  = kron(ones(n,1),lambda2)+...
        kron(conj(omega_n),lambda3)+kron(omega_n,lambda1);

  lambda1 = D21(2,1) + D21(3,1)*conj(omega_m) + D21(1,1)*omega_m;
  lambda2 = D21(2,2) + D21(3,2)*conj(omega_m) + D21(1,2)*omega_m;
  lambda3 = D21(2,3) + D21(3,3)*conj(omega_m) + D21(1,3)*omega_m;
    
  D3  = kron(ones(n,1),lambda2)+...
        kron(conj(omega_n),lambda3)+kron(omega_n,lambda1);

  lambda1 = D22(2,1) + D22(3,1)*conj(omega_m) + D22(1,1)*omega_m;
  lambda2 = D22(2,2) + D22(3,2)*conj(omega_m) + D22(1,2)*omega_m;
  lambda3 = D22(2,3) + D22(3,3)*conj(omega_m) + D22(1,3)*omega_m;

  D4  = kron(ones(n,1),lambda2)+...
        kron(conj(omega_n),lambda3)+kron(omega_n,lambda1);
  clear omega_n omega_m lambda1 lambda2 lambda3

  det    = D1.*D4 - D2.*D3;
  J      = find(abs(det)<1e-15);
  %disp(['D1(J),D2(J),D3(J),D4(J)'])
  %disp([ D1(J),D2(J),D3(J),D4(J) ])
  det(J) = ones(size(J));
  D1(J)  = zeros(size(J));
  D2(J)  = zeros(size(J));
  D3(J)  = zeros(size(J));
  D4(J)  = zeros(size(J));
        
  FFT.iD1 =  reshape( D4./det,m,n);
  FFT.iD4 =  reshape( D1./det,m,n);
  FFT.iD2 =  reshape(-D2./det,m,n);
  FFT.iD3 =  reshape(-D3./det,m,n);

return;
%----------------------------------------------------------------------

