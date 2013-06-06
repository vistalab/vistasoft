function overlayMaps(vw,map1,map2,anatFlag,map1Name,map2Name)
%
% overlayMaps(view,map1,map2,[anatFlag],[map1Name,map2Name]);
%
% Given two volumes containing values 
% relevant for the current view (such 
% as param maps, corAnal fields, etc), 
% grab the relevant anatomical images from 
% the view, take into account relevant 
% clip values, zoom, and other factors, and
% overlay using the overlayVolumes GUI.
%
% map1Name and map2Name are optional strings 
% specifying the names to use in the
% GUI for the two volumes.
%
%
% ras 04/02/2005
if ieNotDefined('map1Name')
    map1Name = inputname(2);
end

if ieNotDefined('map2Name')
    map2Name = inputname(3);
end

if ieNotDefined('anatFlag')
    anatFlag = 1;
end


if anatFlag==1    
    % initialize anatomy
	viewType = viewGet(vw,'viewType');
	switch viewType
        case {'Inplane','Flat'}, 
            nSlices = numSlices(vw); 
            for i = 1:nSlices
                bg(:,:,i) = recomputeAnatImage(vw,[],i);
            end
            
        case {'Volume','Gray'}, 
            bg = viewGet(vw,'anat');
            ori = getCurSliceOri(vw);
            if ori==1, % permute to axial view 
                bg = permute(bg,[2 3 1]);
            elseif ori==2, % permute to coronal view
                bg = permute(bg,[1 3 2]);
            end
	end

    % resize overlay volumes to be same size as bg
    switch viewType
        case {'Inplane'},
            vs = viewGet(vw,'Size');
            for i = 1:vs(3)
                tmp1(:,:,i) = imresize(map1(:,:,i),[vs(1) vs(2)]);
                tmp2(:,:,i) = imresize(map2(:,:,i),[vs(1) vs(2)]);
            end
            map1 = tmp1; map2 = tmp2; clear tmp1 tmp2;
            
        case {'Volume','Gray','volume3View'},
            coords = canOri2CurOri(vw,vw.coords);
            ind = sub2ind(size(bg),coords(1,:),coords(2,:),coords(3,:));
            
            tmp1 = zeros(size(bg));
            tmp1(ind) = map1;
            map1 = tmp1;
            clear tmp1;
            
            tmp2 = zeros(size(bg));
            tmp2(ind) = map2;
            map2 = tmp2;
            clear tmp2;       
            
            if isfield(vw.ui,'flipLR') & vw.ui.flipLR==1
                map1 = flipdim(map1,2);
                map2 = flipdim(map2,2);
                bg = flipdim(bg,2);
            end
                        
        case {'Flat'},
            % threshold to see sulci/gyri clearly
            thresh = 0.5 .* max(bg(:));
            lightRng = [0.6 0.8] .* max(bg(:));
            darkRng = [0.2 0.4] .* max(bg(:));
            bg(bg < thresh) = normalize(bg(bg < thresh),darkRng(1),darkRng(2));
            bg(bg >= thresh) = normalize(bg(bg >= thresh),lightRng(1),lightRng(2));
    end
    
    % apply a zoom, if specified in ui 
    ui = viewGet(vw,'ui');
    if isfield(ui,'zoom')
        switch viewType
            case {'Inplane','Flat'},
                zoom = round(ui.zoom);
                xrng = zoom(1):zoom(2);
                yrng = zoom(3):zoom(4);
                map1 = map1(yrng,xrng,:);
                map2 = map2(yrng,xrng,:);
                bg = bg(yrng,xrng,:);
            case {'Volume','Gray'},
                zoom = round(ui.zoom);
                ap = zoom(1,1):zoom(1,2);
                si = zoom(2,1):zoom(2,2);
                rl = zoom(3,1):zoom(3,2);
                map1 = map1(ap,si,rl);
                map2 = map2(ap,si,rl);
                bg = bg(ap,si,rl);
        end
    end
    
    bg = brighten(bg,0.5);
    
    overlayVolumes(map1,map2,bg,[],'map1Name',map1Name,'map2Name',map2Name);
else
    overlayVolumes(map1,map2,[],[],'map1Name',map1Name,'map2Name',map2Name);
end

return