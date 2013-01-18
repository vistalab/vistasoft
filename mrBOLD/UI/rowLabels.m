function h = rowLabels(labels);
% Produce a set of text uicontrols to the left-hand side of a figure,
% labeling each row of subplots.
%
% h = rowLabels(labels);
%
% This is a simple function, which will assume there are as many 
% rows of plots as there are labels. It will place a text uicontrol
% with each label string at the appropriate location.
%
% ras, 02/2007.

N = length(labels);

for n = 1:N
	y = 1 - (n/N) + 1/(2*N);
	h(n) = uicontrol('Style', 'text', 'BackgroundColor', 'w', ...
		'Units', 'normalized', 'Position', [.01 y .07 .06], ...
		'String', labels{n}, 'HorizontalAlignment', 'left', ...
		'FontSize', 10, 'FontName', 'Helvetica');	
end

return
