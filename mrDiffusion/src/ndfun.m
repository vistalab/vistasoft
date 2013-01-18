function NDFUN
%NDFUN Matrix operations on N-D matrices
%   NDFUN treats an N-D matrix of double precision values as a set of pages
%   of 2D matrices, and performs various matrix operations on those pages.
%   The BLAS and LAPACK routines compiled into MATLAB are used for all these
%   operations, so results will be very close, and are usually identical, to
%   "native MATLAB results".  Available commands are:
%
%   C = NDFUN('mult', A, B)
%   C = NDFUN('mprod', A)
%   C = NDFUN('backslash', A, B)
%   C = NDFUN('inv', A)
%   C = NDFUN('eig', A)
%   [C, D] = NDFUN('eig', A) 
%   C = NDFUN('version')
%
%   The two-argument commands perform operations equivalent to:
%       for i=1:N
%           C(:,:,i) = A(:,:,i) * B(:,:,i);
%       end
%   The one-argument command
%       for i=1:N
%           C(:,:,i) = inv(A(:,:,i));
%       end
%
%   Any number of dimensions is supported, but dimensions > 2 must match:
%       C = ndfun('mult', rand(4,3,2,2,2), rand(3,1,2,2,2))
%   C will have size = [4 1 2 2 2]
%
%   'mprod' behaves differently.  It cumulatively multiplies a set
%   of matrices and produces a single 2D output.  The equivalent
%   code is:
%       C = A(:,:,1);
%       for i=2:N
%           C = C * A(:,:,i);
%       end
%   2D inputs return themselves.  Inputs with more than 3
%   dimensions collapse the 3rd dimension only.  So with an A of
%   size [2 2 7 3 4],
%       C = ndfun('mprod', A);
%   is equivalent to
%       for i=1:3
%           for j=1:4
%               C(:,:,i,j)=ndfun('mprod',M(:,:,:,i,j));
%           end
%       end
%   and C will have size [2 2 3 4].
%
%
%   NDFUN will reuse 2D arguments when needed, much like scalar
%   operations.  A single 2D matrix can be multiplied (or solved with)
%   each 2D page of the other argument.  For instance:
%       A = rand(4,3);  B = rand(3,10,100);
%       C = ndfun('mult', A, B);
%   is equivalent to:
%       for i=1:100
%           C(:,:,i) = A * B(:,:,i);
%       end
%   The reverse also works.  These types of operations are especially
%   efficient for the backslash operator.
%
%
%   Only the 'mprod' operation supports complex numbers
%
%   Author: Peter Boettcher <boettcher@ll.mit.edu>

% Last modified: <Fri Jul 22 13:08:38 2005 by pwb>
  
if(1)
  msg = sprintf(['\nMEX file not found.  Try\n' ...
				 '    ''mex ndfun.c <matlab>/extern/lib/win32/lcc/libmwlapack.lib'''...
				 '\nto compile.  Replace <matlab> with the MATLAB installation '...
				 'directory.\n\nIf using MSVC as the mex compiler,' ...
				  ' the lib file should be instead:\n' ...
				  '    <matlab>/extern/lib/win32/microsoft/msvc60/libmwlapack.lib']);
else
  msg = 'MEX file not found.  Try ''mex ndfun.c'' to compile.';
end

error(msg);
