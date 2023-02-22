function ieFontInit(fig)
%Initialize the font size based on the preference setting 
%
%   ieFontInit(fig)
%
% Font sizes are managed using the preference mechanism in Matlab. The font
% size is a field, fontDelta, in the mrVista preference structure. That
% information is retrieved here and the font size is changed based on this
% setting. This setting is stored across sessions.
%

vistaPref = getpref('mrVista');
if ~isempty(vistaPref)
    if checkfields(vistaPref,'fontDelta')
        fontDelta = getpref('vistaPref','fontDelta');
        ieFontChangeSize(fig,fontDelta);
    end
end

return;
