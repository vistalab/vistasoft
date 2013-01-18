function rxKbShortcuts;
% rxKbShortcuts:
%
% A callback function from mrRx, which 
% allows use of easy keyboard shortcuts to
% change prescription settings.
%
% Shortcuts include:
%   
%  q,w: Axial rotate CCW, CW 
%  a,s: Coronal rotate CCW, CW
%  z,x: Sagittal rotate CCW, CW
%
%  e,r: Axial translate left, right
%  d,f: Coronal translate left, right
%  c,v: Sagittal translate left, right
%
% For each of the above, using SHIFT will
% make the step size large, while not using
% it will make the step size small.
%
%  1: flip axial
%  20: flip coronal
%  3: flip sagittal
%
%  ,: move Rx slice forward (nudge)
%  .: move Rx slice back (nudge)
%  <: move Rx slice forward (step)
%  >: move Rx slice back (step)
%
%  [: decrease slider step (nudge)
%  ]: increase slider step (nudge)
%  {: decrease slider step (step)
%  }: increase slider step (step)
%  
%
% ras 03/05.

% this should, for now, only be a callback
% from the rx control figure. If not, 
% quietly do nothing:
if ~isequal(get(gcf,'Tag'),'rxControlFig')
    return
end

key = get(gcf,'CurrentCharacter');

if isempty(key)
    return
end

rx = get(gcf,'UserData');

switch key
    case 'q' % axial rotate CCW, nudge
        nudgeSlider(rx.ui.axiRot,-1);
    case 'Q' % axial rotate CCW, step
        nudgeSlider(rx.ui.axiRot,-20);
    case 'w' % axial rotate CW, nudge
        nudgeSlider(rx.ui.axiRot,1);
    case 'W' % axial rotate CW, step
        nudgeSlider(rx.ui.axiRot,20);
    case 'a' % coronal rotate CCW, nudge
        nudgeSlider(rx.ui.corRot,-1);
    case 'A' % coronal rotate CCW, step
        nudgeSlider(rx.ui.corRot,-20);
    case 's' % coronal rotate CW, nudge
        nudgeSlider(rx.ui.corRot,1);
    case 'S' % coronal rotate CW, step
        nudgeSlider(rx.ui.corRot,20);
    case 'z' % sagittal rotate CCW, nudge
        nudgeSlider(rx.ui.sagRot,-1);
    case 'Z' % sagittal rotate CCW, step
        nudgeSlider(rx.ui.sagRot,-20);
    case 'x' % sagittal rotate CW, nudge
        nudgeSlider(rx.ui.sagRot,1);
    case 'X' % sagittal rotate CW, step
        nudgeSlider(rx.ui.sagRot,20);
        
    case 'e' % axial translate left, nudge
        nudgeSlider(rx.ui.axiTrans,-1);
    case 'E' % axial translate left, step
        nudgeSlider(rx.ui.axiTrans,-20);
    case 'r' % axial translate right, nudge
        nudgeSlider(rx.ui.axiTrans,1);
    case 'R' % axial translate right, step
        nudgeSlider(rx.ui.axiTrans,20);
    case 'd' % coronal translate left,
        nudgeSlider(rx.ui.corTrans,-1);
    case 'D' % coronal translate left, step
        nudgeSlider(rx.ui.corTrans,-20);
    case 'f' % coronal translate right, nudge
        nudgeSlider(rx.ui.corTrans,1);
    case 'F' % coronal translate right, step
        nudgeSlider(rx.ui.corTrans,20);
    case 'c' % sagittal translate left, nudge
        nudgeSlider(rx.ui.sagTrans,-1);
    case 'C' % sagittal translate left, step
        nudgeSlider(rx.ui.sagTrans,-20);
    case 'v' % sagittal translate right, nudge
        nudgeSlider(rx.ui.sagTrans,1);
    case 'V' % sagittal translate right, step
        nudgeSlider(rx.ui.sagTrans,20);        
        
    case '1' % axial flip
        val = ~(get(rx.ui.axiFlip,'Value'));
        set(rx.ui.axiFlip,'Value',val);
    case '20' % coronal flip
        val = ~(get(rx.ui.corFlip,'Value'));
        set(rx.ui.corFlip,'Value',val);
    case '3' % sagittal flip
        val = ~(get(rx.ui.sagFlip,'Value'));
        set(rx.ui.sagFlip,'Value',val);
        
        
    case ',' % prev rx slice
        nudgeSlider(rx.ui.rxSlice,-1);
    case '.' % next rx slice
        nudgeSlider(rx.ui.rxSlice,1);
    case '<' % go back 20 rx slices
        nudgeSlider(rx.ui.rxSlice,-20);
    case '>' % go forward 20 rx slices
        nudgeSlider(rx.ui.rxSlice,20);
       
        
    case ',' % decrease slider step (nudge)
        nudgeSlider(rx.ui.nudge,-1);
        rxSetNudge(rx.ui.nudge);
        return
    case '.' % increase slider step (nudge)
        nudgeSlider(rx.ui.nudge,1);
        rxSetNudge(rx.ui.nudge);
        return
    case '<' % decrease slider step (step)
        nudgeSlider(rx.ui.nudge,-20);
        rxSetNudge(rx.ui.nudge);
        return
    case '>' % increase slider step (step)
        nudgeSlider(rx.ui.nudge,20);
        rxSetNudge(rx.ui.nudge);
        return        
        
end

rxRefresh(rx);

return

% /------------------------------------------------------------/ %





% /------------------------------------------------------------/ %
function nudgeSlider(slider,step);
% nudgeSlider(slider,step);
% move a mrRx slider by <step> times the 
% lower (nudge) sliderStep value.
a = get(slider.sliderHandle,'Min');
b = get(slider.sliderHandle,'Max');
stepSz = get(slider.sliderHandle,'SliderStep');
delta = step * stepSz(1) * (b-a);
val = get(slider.sliderHandle,'Value');
val = val + delta;
rxSetSlider(slider,val);
return

