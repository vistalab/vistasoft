function [newVal,newUnitStr,oldUnitStr] = unitConvert(oldVal,valueType,oldUnitStr,newUnitStr)
% [newVal,newUnitStr,oldUnitStr] = unitConvert(oldVal,valType,oldUnitStr)
%
% Value types:
%  'length' - recognized units: 'nm', 'um', 'mm', 'cm'
%  'time'   - recognized units: 'usec', 'msec', 'sec'
%
% Adapted from isetbio unitConvert 
%
% Examples
%
% newVal = unitConvert(1500,'time','ms' ,'s')
% newVal = unitConvert(1,'length','cm' ,'mm')

% Switch on value type
switch (valueType)
    case 'length'
        % Length
        
        % Factor from old to default
        switch oldUnitStr
            case 'm'
                oldConversionFactor = 1;
            case 'nm'
                oldConversionFactor = 1e-9;
            case 'um'
                oldConversionFactor = 1e-6;
            case 'mm'
                oldConversionFactor = 1e-3;
            case 'cm'
                oldConversionFactor = 1e-2;
            otherwise
                error('Bad units %s passed for type %s',oldUnitStr,valueType);
        end
        
         % Factor from old to default
        switch newUnitStr
            case 'm'
                newConversionFactor = 1;
            case 'nm'
                newConversionFactor = 1e9;
            case 'um'
                newConversionFactor = 1e6;
            case 'mm'
                newConversionFactor = 1e3;
            case 'cm'
                newConversionFactor = 1e2;
            otherwise
                error('Bad units %s passed for type %s',oldUnitStr,valueType);
        end
        

    case 'time'
        % Time
        
        % Factor from old to default
        switch oldUnitStr
            case {'s' 'sec' 'seconds'}
                oldConversionFactor = 1;
            case {'ms' 'msec' 'milliseconds'}
                oldConversionFactor = 1e-3;
            otherwise
                error('Bad units %s passed for type %s',oldUnitStr,valueType);
        end
        
         % Factor from old to default
        switch newUnitStr
            case {'s' 'sec' 'seconds'}
                newConversionFactor = 1;
            case {'ms' 'msec' 'milliseconds'}
                newConversionFactor = 1e3;
            otherwise
                error('Bad units %s passed for type %s',oldUnitStr,valueType);
        end
        
    otherwise
        error('Unknown value type passed');
end

% Convert
newVal = oldConversionFactor*newConversionFactor*oldVal;

end
