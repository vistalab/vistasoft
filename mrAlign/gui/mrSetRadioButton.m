function mrSetRadioButton(buttonNum,buttonIdList)
%mrSetRadioButton(buttonNum,buttonIdList)
%
%Sets (highlights) one radio button and turns other off
%
%bttonNum:  button number in list to turn on
%buttonIdList:  array of handles to radio buttons.  

%7/30/97 gmb  Wrote it.

for i=1:length(buttonIdList)
  if buttonNum == i
    set(buttonIdList(i),'Value',1);
  else
    set(buttonIdList(i),'Value',0);
  end
end
