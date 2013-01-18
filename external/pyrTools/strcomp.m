function same=strcomp(str1,str2)
%A local strcmp routine.   Used.  Not sure why. Left over from 1996.
%
%  same=strcomp(str1,str2);
%
%Returns 1 if str1 == str2
%Returns 0 otherwise.
%
%4/12/96 gmb	Why did I have to write this?
%

if length(str1)~=length(str2)
	same=0;
	return
end

for i=1:length(str1)
	if (str1(i)~=str2(i))
		same=0;
		return
	end
end

same=1;
