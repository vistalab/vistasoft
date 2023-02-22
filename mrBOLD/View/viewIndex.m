function index = viewIndex(view)%% function index = viewIndex(view)%% Loops through the global cell array (INPLANE, VOLUME, or FLAT)% to find this particular view.name, and returns its index.%% Called by refreshView to set the selectedINPLANE/VOLUME/FLAT%% djh, 2/14/2001
mrGlobals
switch view.viewType    case 'Inplane'        viewsArray = INPLANE;    case {'Volume','Gray'}        viewsArray = VOLUME;    case 'Flat'        viewsArray = FLAT;end

index = [];
for s = 1:length(viewsArray)    if ~isempty(viewsArray{s})        if strcmp(view.name,viewsArray{s}.name)            index = s;        end    endendreturn;
