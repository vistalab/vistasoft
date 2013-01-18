%  rows(M)		equivalent to a=size(M); a=a(end-2);

function [a] = rows(M)

   a = size(M);

   if length(a) == 2,
      a = a(1);
   elseif length(a) > 2,
      a = a(end-2);
   else
      error('woops size wasn''t length 2 or bigger!');
   end;
   
   return;
   
