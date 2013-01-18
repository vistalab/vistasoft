function str = secs2text(t);
% convert a measure in seconds to a string report minutes and seconds.
%
% str = secs2text([t=toc]);
%
% Given a number indicating a span of seconds (e.g., the output of the TOC
% command), returns a string indicating how many minutes and seconds have
% passed. If >60 minutes have passed, will also break it down into hours.
%
%
% ras, 12/09/2008.
if ~exist('t', 'var') | isempty(t), t = toc;  end

nSeconds = mod(t, 60);

nMinutes = floor(t / 60);

if nMinutes > 60
	nHours = floor(nMinutes / 60);
	nMinutes = mod(nMinutes, 60);
	
	str = sprintf('%i hours, %i minutes, %2.1f seconds', nHours, ...
				   nMinutes, nSeconds);
else
	str = sprintf('%i minutes, %2.1f seconds', nMinutes, nSeconds);
end

return


