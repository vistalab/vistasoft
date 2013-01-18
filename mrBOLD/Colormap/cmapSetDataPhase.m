function view = cmapSetDataPhase(view, cmapPh, dataPh);
%
%  view = cmapSetDataPhase(view, cmapPh, dataPh);
%
%Author: JL, BW
%Purpose:
%
%    This routine circularly shifts the color map phase to improve the
%    visualization.
%
%    Suppose you know which data phase represents horizontal (or foveal).
%    And you would like for that phase to fall in a particular location on
%    the color map. Then, call this routine to set a particular color
%    represent the horizontal/foveal value.
%
%    You are asked for two values.  One is the phase represented by the
%    color you think should be target phase.  Second is the phase of the
%    data that corresponds to the target.  The color map is adjusted so
%    that the data phase you specify has the color of the target.
%

if ieNotDefined('dataPh') | ieNotDefined('cmapPh')
    prompt={'Target color/phase from current map (left wedge = 2.2 (hor), ring = 0 (fov))',...
            'Data phase: (Plots|Current|Summary|Brief)'};
    def={'0','5.1'};
    dlgTitle='Shift/Rotate color map';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);
    if isempty(answer), return; 
    else
        cmapPh = str2num(answer{1});
        dataPh = str2num(answer{2});
    end
end

[mp, numGrays,numColors] = getColorMap(view,'ph',1);
step = numColors/(2*pi);
phShift = dataPh - cmapPh;
sz = round((phShift) *step);
cmap = circshift(mp,sz);

view = cmapSetManual(view,cmap,'ph',1);

return;