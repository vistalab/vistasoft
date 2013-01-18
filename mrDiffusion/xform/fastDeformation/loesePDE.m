function [u1,u2,u3]=loesePDE(varargin);
% function [u1,u2,u3]=loesePDE(varargin); 
%
% SW 8/2002
%
% (c) 2002 Stefan Wirtz

persistent invD
if ~exist('invD','var'), invD=0; end;
[what,varargin]=getopt('what',0,varargin{:});
if what==0, error('don''t know what to do'); end;

if strcmp(what,'solve')
   [f1,varargin]=getopt('f1',42,varargin{:});
   [f2,varargin]=getopt('f2',42,varargin{:});
   [f3,varargin]=getopt('f3',42,varargin{:});
   %[L,varargin]=getopt('level',1,varargin{:});
   if ~isempty(varargin), varargin; end;
   
   %keyboard
   %-------------------------------------------------------------%
   %                                                             %
   %          ( D11 D12 D13 )            ( D11 D12 D13 )         %
   % F'*A*F = ( D21 D22 D23 )  =>  A = F*( D21 D22 D23 )*F'      %
   %          ( D31 D32 D33 )            ( D31 D32 D33 )         %
   %                                                             %
   % mit F = I_3 * F_n3 * F_n2 * F_n1,                           %
   %     F_n := 1/sqrt(n)*(omega_n^{(j-1)(k-1)})_{j,k=1,..,n},   %
   %     omega_n := exp(-2*pi*i/n)                               %
   %     und * = kron(.,.)                                       %
   %                                                             %
   % mit G_n := sqrt(n)*F_n und G = I_3 * G_n3 * G_n2 * G_n1 folgt%
   % A = G*D*G'/(n1*n2*n3)                                       %
   % wegen F'F=FF'=I faellt 1/(n1*n2*n3) bei der Berechnung weg  %
   %                                                             %
   % A*u=f  =>  F*D*F'*u=f  => F'*u=inv(D)*F'*f                  %
   %                                                             %
   %-------------------------------------------------------------%
   
   % berechne: temp1=G'*[f1;f2;f3] ----------
   % berechne: temp2=inv(D)*temp1 -----------
   % verwende u1 fuer temp1, um Speicherplatz zu sparen
   % gehe sequentiell vor, um weiteren Platz zu sparen
   % verwende f für temp2 um Speicherplatz zu sparen
   u1 = fftn(f1);
   u2 = f2;
   u3 = f3;
   
   f1 = invD(:,:,:,1).*u1;
   f2 = invD(:,:,:,2).*u1;
   f3 = invD(:,:,:,3).*u1;
   
   u1 = fftn(u2);
   f1 = f1 + invD(:,:,:,2).*u1; 
   f2 = f2 + invD(:,:,:,4).*u1;
   f3 = f3 + invD(:,:,:,5).*u1;
   
   u1 = fftn(u3);
   f1 = f1 + invD(:,:,:,3).*u1;
   f2 = f2 + invD(:,:,:,5).*u1;
   f3 = f3 + invD(:,:,:,6).*u1;
   
   % berechne: u=G*temp2 --------------------
   u1=real(ifftn(f1));
   u2=real(ifftn(f2));
   u3=real(ifftn(f3));

elseif strcmp(what,'init')
   fprintf('\tinit inv of D... '); tic;
   [lambda,varargin]=getopt('lambda',0,varargin{:});
   [mu,varargin]=getopt('mu',1,varargin{:});
   [n1,varargin]=getopt('n1',0,varargin{:});
   [n2,varargin]=getopt('n2',0,varargin{:});
   [n3,varargin]=getopt('n3',0,varargin{:});
   if ~prod([n1 n2 n3]), error('dimensions not given'); end;
   invD=initInvDiagsInC(lambda,mu,n1,n2,n3); 
   fprintf('done \t[%3.2f s]\n\n',toc); 
end;

return;
