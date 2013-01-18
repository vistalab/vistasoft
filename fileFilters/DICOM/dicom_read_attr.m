function [attr, data, file] = dicom_read_attr(file, info, dictionary, varargin)
%DICOM_READ_ATTR  Read the next attribute from a DICOM file.
%   [ATTRIBUTE, DATA] = DICOM_READ_ATTR(FILE, INFO, DICTIONARY) reads the
%   next ATTRIBUTE and its DATA from the currently open FILE.  INFO
%   should be the previously read metadata for the message.  DICTIONARY
%   is the data dictionary which will be used to read the attribute.
%
%   [ATTRIBUTE, DATA] = DICOM_READ_ATTR(FILE, INFO, DICTIONARY, VR) reads
%   the next attribute which is part of an item list.  When reading
%   items, the two-letter value-representation VR must be inherited.
%
%   Note: DICOM_READ_ATTR reads the next data element.  In the case of of
%   a sequence, this includes the entire sequence, which might consist of
%   multiple attributes.  In the case of an item list, the data element
%   contains all of the items.  Item delimiters are not returned in DATA.
%
%   See also DICOM_READ_ATTR_METADATA.
%
%   This file was copied out from
%   $Matlabroot/toolbox/images/images/private/dicom_read_attr.m
%   Original Line 503 of this file (Line 511 in this modified file) has a
%   typo, I think. I changed 16 to 26 so that dicomread function in Matlab
%   works without error for GE images. Obviously matlab dicom functions
%   were for Siemens images, so there are potentially more unknown bugs for
%   GE images. -- Junjie Liu 2004/01/23

%   [ATTR, DATA, FILE] = DICOM_READ_ATTR(...) also returns the file
%   struct (FILE) in case the warning state has changed.

%   Copyright 1993-2002 The MathWorks, Inc.
%   $Revision: 1.1 $  $Date: 2004/01/23 23:48:38 $

%
% Read data.
%

if (nargin == 4)
    
    % VR was passed in.  Reading a sequence of attributes.
    
    VR = varargin{1};
    
    [attr, data] = read_elt(file, info, dictionary, VR);
    
else
    
    [attr, data] = read_elt(file, info, dictionary);
    
end

%
% Determine what to do with the attribute.
%

if ((~isequal(attr.VR, 'SQ')) & ...
    (~isequal(attr.Length, uint32(inf))))
    
    % Regular, non-sequence attribute.
    
    return

elseif ((isequal(attr.VR, 'UN')) & ...
        (isequal(attr.Length, uint32(inf))))
    
    % Item in sequence or list of items.
    
    return
    
elseif ((~isequal(attr.VR, 'SQ')) & ...
        (isequal(attr.Length, uint32(inf))))
    
    % Sequence of the same attribute.
    
    data = read_items(file, info, dictionary, attr.Length, attr.VR);
    return
    
elseif (isequal(attr.VR, 'SQ'))
    
    % Sequence of one or more named attributes (not all the same).
    
    data = read_seq(file, info, attr.Length, dictionary);
    return
    
end



%%%
%%% Function read_elt
%%%

function [attr, data] = read_elt(file, info, dictionary, varargin)
% Read a single data attribute.

%
% Get the attribute's Tag, VR, VM, and Length.
%

[attr, file] = dicom_read_attr_metadata(file, info, dictionary);

if (nargin == 4)
    
    attr.VR = varargin{1};
    
end

%
% Get the attribute's name and VM.
%

try
    
    attr = find_attr_details(attr, dictionary);
    
catch
    
    % find_attr_details calls dicom_dict_lookup which can error but
    % doesn't have the file structure to close the message.
    
    file = dicom_close_msg(file);
    error(lasterr)
    
end
    

%
% Read the data.
%

if ((attr.Length == uint32(inf)) | (isequal(attr.VR, 'SQ')) | (attr.Group == 65534))

    % It's a sequence.  Let other routines read the data.

    data = [];
    return
    
end

% Explicitly defined lengths must be even.
if (rem(attr.Length, 2) == 1)
     
    file = dicom_close_msg(file);
    err_msg = sprintf('Attribute (%04x,%04x) has odd length %d.', ...
                      attr.Group, attr.Element, attr.Length);
    error(err_msg);
    
end

% Acceptable lengths vary depending on the VR and VM.
tf = verify_length(attr.Length, attr.VR, attr.VM);

if (~tf)
   
    file = dicom_close_msg(file);
    err_msg = sprintf('Attribute (%04x,%04x) has inconsistent length %d.', ...
                      attr.Group, attr.Element, attr.Length);
    error(err_msg);
    
end

% Determine format specifier and size of data.
[precision, datasize] = find_datasize(attr);

if (rem(attr.Length, datasize) ~= 0)
    
    file = dicom_close_msg(file);
    err_msg = sprintf('Attribute (%04x,%04x) has inconsistent length %d.', ...
                      attr.Group, attr.Element, attr.Length);
    error(err_msg);
    
end

% Read the attribute's data.

if (~isempty(findstr('OverlayData', attr.Name)))
    
    % Special case for overlay data.
    data = fread(file.FID, (attr.Length * 8), 'ubit1=>uint8' , ...
                 file.Current_Endian);

else

    % Regular attributes.
    data = fread(file.FID, (attr.Length/datasize), precision, ...
                 file.Current_Endian);

end

% Process data as necessary.
if (~isempty(findstr(precision, 'char')))
    % Character data.
    
    % Convert to unpadded character array.
    data = char(data');
    data = fliplr(deblank(fliplr(deblank(data))));

    
    switch (attr.VR)
    case {'DS','IS'}

        % Convert decimal and integer strings to numbers.
        data = sscanf(data, '%f\\');
        
    case {'PN'}
        
        % Retrieve parts of person name.
        data = parse_person(data);
    
    end

elseif (findstr(attr.Name, 'xx_Creator'))

    % Convert Private data element creator to character array.
    data = char(data');
    
else
    
    switch (attr.VR)
    case {'AT'}
        
        % AT data are ordered pairs and should be stored as n-by-2 array.
        data = reshape(data, 2, length(data)/2)';
        
    case {'OB'}
        
        % Remove trailing null.
        if (data(end) == 0)
            data(end) = [];
        end
        
    end
        
    if (~isempty(findstr('OverlayData', attr.Name)))
    
        % Reshape overlay data.

        ol_num = attr.Name((findstr(attr.Name, '_') + 1):end);
        
        ol_width = info.(['OverlayColumns_' ol_num]);
        ol_height = info.(['OverlayRows_' ol_num]);

        if ((ol_width * ol_height) > 0)
            
            data = reshape(data, ol_width, ol_height)';
            data = logical(data);
            
        end
        
    end
    
end



%%%
%%% Function read_items
%%%

function items = read_items(file, info, dictionary, VR)
% Read a group of items.

% When this is called, the file pointer should be at the beginning of an
% (FFFE, E000) tag.  This tag doesn't have a VR of its own; the VR is
% inherited from the "parent" tag.  We pass this value in.

items = {};
more_items = 1;

while (more_items)

    % Read the next item.
    [attr, data, file] = dicom_read_attr(file, info, dictionary, VR);
    
    % Determine what to do with the item.
    tag = sprintf('(%04X,%04X)', attr.Group, attr.Element);
    
    switch (tag)
    case '(FFFE,E000)'
        
        % Item Tag.
        items{end+1} = data;
        
    case '(FFFE,E00D)'
        
        % Item Delimiter.
        
    case '(FFFE,E0DD)'
        
        % Sequence Delimiter.  No more items to read.
        more_items = 0;
        
    end
    
    if feof(file.FID)
        more_items = 0;
    end
    
end



%%%
%%% Function read_seq
%%%

function seq = read_seq(file, info, seq_length, dictionary)
% Read a sequence (a group of nested items of arbitrary depth).

% When this is called, the file pointer should be at the beginning of an
% (FFFE, E000) tag.

seq = struct([]);
item_num = 0;
more_items = 1;

% Some sequences have explicit length and no Sequence Delimiter.
if (isequal(file.Location, 'Local'))
    
    seq_start = ftell(file.FID);
    seq_end = seq_start + seq_length;
    
    % Handle the rare case that the sequence has 0 length.
    if (seq_length == 0)
        more_items = 0;
    end
    
else
    
    file = dicom_close_msg(file);
    error('Network access is not yet supported.');
    
end


while (more_items)
    
    % Read the next attribute of the sequence.
    [attr, data, file] = dicom_read_attr(file, info, dictionary);
    
    % Determine what to do with the item.
    tag = sprintf('(%04X,%04X)', attr.Group, attr.Element);
    
    switch (tag)
    case '(FFFE,E000)'
        
        % Item Tag.

        item_num = item_num + 1;
        
        % Create a new "Item" structure to contain the item's data.
        item_name = sprintf('Item_%d', item_num);
        item = struct([]);
        
    case '(FFFE,E00D)'
        
        % Item Delimiter.
        
    case '(FFFE,E0DD)'
        
        % Sequence Delimiter.  No more items to read.
        more_items = 0;
        
    otherwise
        
        % Data.
        
        % Assign data to "Item" structure.
        item(1).(attr.Name) = data;
        
        % Assign "Item" structure to output structure.
        seq(1).(item_name) = item;
        
    end
    
    if (isequal(file.Location, 'Local'))
        
        if (ftell(file.FID) >= seq_end)
            more_items = 0;
        end
        
        if (feof(file.FID))
            more_items = 0;
        end
        
    end

end



%%%
%%% Function find_datasize
%%%

function [precision, datasize] = find_datasize(attr)
% Determine the precision of an attribute's data.

% See PS 3.5-1999 Table 6.2-1.

switch (attr.VR)
case  {'AE','AS','CS','DA','DT','LO','LT','PN','SH','ST','TM','UI','UT'}

    precision = 'uchar=>uchar';
    datasize = 1;
    
case {'AT', 'OW', 'US'}
    
    if ((attr.Group == 32736) & (attr.Element == 16))
        
        % (7FE0,0010)
        precision = 'uint16=>uint16';
        
    else
        
        precision = 'uint16';
        
    end
    
    datasize = 2;
    
case {'DS', 'IS'}
    
    precision = 'uchar=>uchar';
    datasize = 1;
    
case 'FL'
    
    precision = 'single';
    datasize = 4;
    
case 'FD'
    
    precision = 'double';
    datasize = 8;
    
case {'OB', 'UN'}
    
    if ((attr.Group == 32736) & (attr.Element == 16))
        
        % (7FE0,0010)
        precision = 'uint8=>uint8';
        
    else
        
        precision = 'uint8';
        
    end
    
    datasize = 1;
    
case 'SL'
    
    precision = 'int32';
    datasize = 4;
    
case 'SQ'
    
    % Sequence VR.  Not actually used for data.
    % Should error if ever passed to FREAD.
    precision = '';
    datasize = NaN;
    
case 'SS'
    
    precision = 'int16';
    datasize = 2;
    
case 'UL'
    
    precision = 'uint32';
    datasize = 4;
    
otherwise
    
    % PS 3.5-1999 Sec. 6.2 indicates that all unknown VRs can be interpretted
    % as being the same as OB, OW, SQ, or UN.  The size of data is not
    % known but, the reading structure is.  So choose "UN".
    
    precision = 'uint8';
    datasize = 1;
    
end



%%%
%%% Function verify_length
%%%

function tf = verify_length(data_length, vr, vm)
%VERIFY_LENGTH  make sure that data length is within the allowable range

%
% All of these rules are in PS 3.5-2000 Table 6.2-1.
%

% Zero length data is okay (assume type 2 attribute).
if (data_length == 0)

    tf = 1;
    return;
    
end

max_vm = vm(end);

switch (vr)
case {'AE', 'FL', 'TM'}
    
    % Siemens modalities allowed (at least 26 byte character strings).
    tf = (data_length <= (26 * max_vm)); % changed 16->26 by Junjie Liu 2004/01/23
    
case {'AS', 'AT', 'SL', 'UL'}
    
    tf = (rem(data_length, 4) == 0);
    
case {'CS'}
    
    % Siemens modalities allowed (at least) 26 byte character strings.
    % Technically only 16 bytes are allowed.
    tf = (data_length <= (26 * max_vm));
    
case {'DA'}
    
    % Acuson modalities used to allow 6 byte date strings (presumably YYMMDD).
    tf = ((rem(data_length, 8) == 0) | ...
          (rem(data_length, 10) == 0) | ...
          (rem(data_length, 6) == 0));
    
case {'DS'}
    
    % The Offis Toolkit appears to allow 18 byte decimal strings.
    tf = (data_length <= (18 * max_vm));
    
case {'DT'}
    
    tf = (data_length <= (26 * max_vm));
    
case {'FD'}
    
    tf = (rem(data_length, 8) == 0);
    
case {'IS'}
    
    % ACR-NEMA appears to have allowed upto 14 bytes.
    tf = ((data_length <= (12 * max_vm)) | (data_length <= (14 * max_vm)));
    
case {'LO'}
    
    % This length is measured in CHARACTERS, which may be multi-byte.
    % See note in PS 3.5-2000 Sec. 6.2.
    
    MAX_BYTES_PER_CHAR = 2;
    tf = (data_length <= ((64 * MAX_BYTES_PER_CHAR) * max_vm));
    
case {'LT'}
    
    % This length is measured in CHARs, which may be multi-byte.
    % See note in PS 3.5-2000 Sec. 6.2.
    
    MAX_BYTES_PER_CHAR = 2;
    tf = (data_length <= ((10240 * MAX_BYTES_PER_CHAR) * max_vm));

case {'OB', 'OW'}
    
    tf = (data_length < (2^32 - 1));
    
case {'PN'}
    
    % - This length is measured in CHARs, which may be multi-byte.
    % - The attribute can also contain multiple components, each of which
    %   can contain up to the maximum number of multi-byte characters.
    % - See note in PS 3.5-2000 Sec. 6.2 and Append. H and J.
    
    MAX_COMPONENTS = 2;
    MAX_BYTES_PER_CHAR = 2;

    tf = (data_length <= ((64 * MAX_BYTES_PER_CHAR*MAX_COMPONENTS) * max_vm));
    
case {'SH'}
    
    % This length is measured in CHARs, which may be multi-byte.
    % See note in PS 3.5-2000 Sec. 6.2.
    
    MAX_BYTES_PER_CHAR = 2;
    tf = (data_length <= ((16 * MAX_BYTES_PER_CHAR * max_vm)));

case {'SQ', 'UN'}
    
    % Maximum length is not applicable.
    
    tf = 1;
    
case {'SS', 'US'}
    
    tf = (rem(data_length, 2) == 0);
    
case {'ST'}
    
    % This length is measured in CHARs, which may be multi-byte.
    % See note in PS 3.5-2000 Sec. 6.2.
    
    MAX_BYTES_PER_CHAR = 2;
    tf = (data_length <= ((1024 * MAX_BYTES_PER_CHAR) * max_vm));

case {'UI'}
    
    tf = (data_length <= (64 * max_vm));
    
case {'UT'}
    
    % Because 0xFFFFFFFF is reserved, length must be less than 2^32-1.
    
    tf = (data_length <= (2^32 - 2));
      
end



%%%
%%% Function parse_person
%%%

function person_name = parse_person(person_string)
%PARSE_PERSON  Get the various parts of a person name

% A description and examples of PN values is in PS 3.5-2000 Table 6.2-1.

pn_parts = {'FamilyName'
            'GivenName'
            'MiddleName'
            'NamePrefix'
            'NameSuffix'};

if (isempty(person_string))

    person_name.FamilyName = '';
    person_name.GivenName = '';
    person_name.MiddleName = '';
    person_name.NamePrefix = '';
    person_name.NameSuffix = '';
    
    return
    
end

people = tokenize(person_string, '\');

person_name = struct([]);

for p = 1:length(people)

    % ASCII, ideographic, and phonetic characters are separated by '='.
    components = tokenize(people{p}, '=');
    
    % Only use ASCII parts.
    
    if (~isempty(components{1}))
        
        % Get the separate parts of the person's name from the component.
        component_parts = tokenize(components{1}, '^');

        for q = 1:length(component_parts)
            
            person_name(p).(pn_parts{q}) = component_parts{q};
            
        end
        
    else
        
        % Use full string as value if no ASCII is present.
        
        if (~isempty(components))
            person_name(p).FamilyName = people{p};
        end
    
    end
    
end



%%%
%%% Function find_attr_details
%%%

function attr = find_attr_details(attr, dictionary)
%FIND_ATTR_DETAILS  Get the attribute's name

attr_dict = dicom_dict_lookup(attr.Group, attr.Element, dictionary);

if (isempty(attr_dict))
    if ((rem(attr.Group, 2) == 1) & ...
        ((attr.Group > 8) & (attr.Group < 65534)))  % 0xFFFE == 65534.
        
        % Private attribute.  Try to handle it.
        
        % Get name for attribute.
        if (attr.Element == 0)
            % (gggg,0000) is Private Group Length.
            
            attr.Name = sprintf('Private_%04x_GroupLength', attr.Group);
            
        elseif ((attr.Element >= 16) & (attr.Element <= 255))
            % (gggg,0010-00ff) are Private Creator Data Elements.
            
            % Private attributes are assigned in blocks of 256.  The
            % Private Creator Data Elements (gggg,0010-00ff) reserve a
            % block.  For example, (gggg,0030) reserves elements
            % (gggg,3000-30ff).
        
            attr.Name = sprintf('Private_%04x_%02xxx_Creator', ...
                                attr.Group, attr.Element);
            
        else
            
            attr.Name = sprintf('Private_%04x_%04x', ...
                                attr.Group, attr.Element);
            
        end
        
        % For reading only, assume VR of UN (iff implicit VR) and VM of 1-n.
        % This assumes the attribute can contain any type of data; we do not
        % verify these assumptions at all.

        if (isempty(attr.VR))
            attr.VR = 'UN';
        end

        attr.VM = [1 inf];
        
    else
        
        text = 'Attribute (%04x,%04x) was not found in the data dictionary.';
        msg = sprintf(text, attr.Group, attr.Element);
        error(msg);
        
    end
    
else
    
    attr.Name = attr_dict.Name;
    attr.VM = attr_dict.VM;
    
end
