function overlayMapsSameSession(view);
% overlayMapsSameSession(view);
% 
% Take two maps (co, amp, ph, or map) from the current
% view, and superimpose them in different color channels, 
% with an interface for adjusting the thresholds of each/
% moving across slices if necessary.
%
%
% 06/04 ras: wrote it.

% dialog to get params
prompt = {...
        'map 1 field (can be co, amp, ph, or map):',...
        'map 1 clip (2 numbers, min and max--from 0 to 1 normalized):',...
        'map 1 scan:',...
        'map 1 data type #:',...
        'map 2 field (can be co, amp, ph, or map):',...
        'map 2 clip (2 numbers, min and max--from 0 to 1 normalized):',...
        'map 2 scan:',...
        'map 2 data type #:',...
        'Add Anatomical as underlay? (1 for yes, 0 for no):',...
        'Anat Clip (if 1 above):',...
    };
dlgTitle = 'Overlay Two maps from the same session....';
lineNo = 1;
defaults = {...
        viewGet(view,'displayMode'),...
        '0 1',...
        num2str(getCurScan(view)),...
        num2str(viewGet(view,'curdt')),...
        viewGet(view,'displayMode'),...
        '0 1',...
        '',...
        num2str(viewGet(view,'curdt')),...
        '1',...
        num2str(viewGet(view,'anatClip')),...
    };
AddOpts.Resize = 'on';
AddOpts.WindowStyle='normal';
AddOpts.Interpreter='tex';
answer = inputdlg(prompt,dlgTitle,lineNo,defaults,AddOpts);

% if cancel pressed, exit gracefull
if isempty(answer)
    return
end

% parse the responses
map1Name = answer{1};
map1Clip = str2num(answer{2});
map1Scan = str2num(answer{3});
map1Dt = str2num(answer{4});
map2Name = answer{5};
map2Clip = str2num(answer{6});
map2Scan = str2num(answer{7});
map2Dt = str2num(answer{8});
anatFlag = str2num(answer{9});
anatClip = str2num(answer{10});

curdt = viewGet(view,'curdt');
if map1Dt ~= curdt
    if map1Name=='map'
        fprintf('Whoops ... haven''t added the ability to get a map from another dt.\n');
        return
    end
    
    view = viewSet(view,'curdt',map1Dt);
    view = loadCorAnal(view);
end
field1 = viewGet(view,map1Name);
vol1 = field1{map1Scan};

curdt2 = viewGet(view,'curdt');
if map2Dt ~= curdt2
    if map2Name=='map'
        fprintf('Whoops ... haven''t added the ability to get a map from another dt.\n');
        return
    end
    
    view = viewSet(view,'curdt',map2Dt);
    view = loadCorAnal(view);
end
field2 = viewGet(view,map2Name);
vol2 = field2{map2Scan};


hbox = msgbox('Getting maps to overlay...');

% % apply clip
% for i = 1:size(vol1,3)
%     clip = map1Clip .* [min(vol1(:)) max(vol1(:))];
%     vol1(:,:,i) = rescale2(vol1(:,:,i),clip,clip);
% 
%     clip = map2Clip .* [min(vol2(:)) max(vol2(:))];
%     vol2(:,:,i) = rescale2(vol2(:,:,i),clip,clip);
% end

name1 = sprintf('%s Scan %i',map1Name,map1Scan);
name2 = sprintf('%s Scan %i',map2Name,map2Scan);

% use a separte function to add the
% background image, do the overlaying:
overlayMaps(view,vol1,vol2,anatFlag,name1,name2);

close(hbox);

return