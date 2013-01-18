%  cols(M)		equivalent to a=size(M); a(end-1);

function [a] = cols(M)

   a = size(M);

   if length(a) == 2,
      a = a(2);
   elseif length(a) > 2,
      a = a(end-1);
   else
      error('Ooops! size(M) wasn''t length 2 or greater!');
   end;
   
   
