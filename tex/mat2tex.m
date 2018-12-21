% ***********************************************************************
%  License          : GPLv3
%
%  Author           : Andreas Kaeberlein
%  eMail            : andreas.kaeberlein@web.de
%
%  File             : mat2tex.m
%  Description      : generates a Latex table from a given Matrix or data structure
%  Octave           : 4.0
%
%  Sources          : none
%
%  on               : 2018-12-01
% ************************************************************************



%-------------------------------------------------------------------------
%
function tex = mat2tex(myData, varargin)
%%
%%  Arguments
%%  ---------
%%
%%  myData              : number array                      -> table content
%%  notation            : string        [ 'si' ]            -> number format
%%  fraction            : integer       [ 1 ]               -> number of fractions in number
%%  texLevel            : string        [ 'table' ]         -> generation level of texcode
%%  texHeadSeparation   : string        [ 'doubleLine' ]    -> separation between table header and content
%%  headerText          : cell                              -> cell array with name of cols
%%  longtable           :                                   -> switch, if set tex for longtable is generated, 'headerText' then mandatory
%%  noTexUnit           :                                   -> switch, if set tex command '\unit' is used for half blank between number and unit
%%
%%  Example Call
%%  ------------
%%    >> mat2tex([1 50 5; 45 789 -0.1], 'headerText', {'foo1', 'foo2', 'foo3'})
%%



% parse input
% SRC: https://www.gnu.org/software/octave/doc/interpreter/Multiple-Return-Values.html#XREFinputParser
% SRC: https://de.mathworks.com/help/matlab/ref/inputparser.addoptional.html
%
p               = inputParser();    % create object
p.FunctionName  = 'mat2tex';        % set function name

p.addParameter('notation', 'si', @(x) any (strcmp (x, {'scientific', 'number', 'si'})));                    % type conversion if numeric table is provided
p.addParameter('fraction', 1, @isnumeric);                                                                  % number of fraction in number
p.addParameter('texLevel', 'table', @(x) any (strcmp (x, {'full', 'table', 'content'})));                   % defines level of generated code
p.addParameter('texHeadSeparation', 'doubleLine', @(x) any (strcmp (x, {'singleLine', 'doubleLine'})));     % defines level of generated code
p.addParameter('headerText', {}, @iscell);                                                                  % number of fraction in number

p.addSwitch('longtable');           % uses latex longtable instead of normal table
p.addSwitch('noTexUnit');           % forbid latex command \unit[]{} for correct space between number ans si unit

p.parse(varargin{:});               % Run created parser on inputs
%


% convert to text array
%
if ( isnumeric(myData) == true )
    %
    % numeric table is provided
    %
    [ row col ] = size(myData);     % get dimension;
    for i=1:row
        for j=1:col
            numStr = '';
            if ( isnan(myData(i,j)) )
                numStr = '';
            elseif ( isinf(myData(i,j)) )
                if ( myData(i,j) < 0 )
                    numStr = '-Inf';
                else
                    numStr = 'Inf';
                end
            else
                if ( strcmp('scientific', p.Results.notation) )
                    numStr = sprintf('%.*e', p.Results.fraction, myData(i,j));
                elseif ( strcmp('si', p.Results.notation) )
                    numStr = texTable_toSiStr(myData(i,j), p.Results.fraction, p.Results.noTexUnit);
                elseif ( strcmp('number', p.Results.notation) )
                    numStr = sprintf('%.*f', p.Results.fraction, myData(i,j));
                else
                    warning('Something went wrong');
                    return;
                end
            end
            myWorkTabContent{i,j} = numStr;
        end;
    end
else
    warning('Unsupported input data type');
    return;
end;
%


% Extract Data Size
%
[ dataRow, dataCol ] = size(myWorkTabContent);
%


% Tex Gen Preparations
%
% create tex code variable
tex = {};
% single/double header line
if ( strcmp('doubleLine',  p.Results.texHeadSeparation) )
    if ( p.Results.longtable == true )
        temp(1:dataCol) = '=';
        texHeadLineSeparator = strcat('\hhline{', temp, '}');
    else
        texHeadLineSeparator = '\hline\hline';
    end
elseif ( strcmp('singleLine',  p.Results.texHeadSeparation) )
    texHeadLineSeparator = '\hline';
else
    warning('Unknown texHeadSeparation option used, aborting...');
    return;
end;
%


% add header of full document, if requested
%
if ( strcmp('full',  p.Results.texLevel) )
    % todo
end
%


% check header, type and dimension of table
%
if ( p.Results.longtable == true && length(p.Results.headerText) == 0 )
    warning(cstrcat('Switch ', char(39), 'longtable', char(39), ' requires ', char(39), 'headerText', char(39)));
    tex = {};
    return;
end
maxFieldLen = max(cellfun('length', myWorkTabContent));     % get column based max length of elements in table
if ( length(p.Results.headerText) > 0 )
    [ ~, dataCol ] = size(myWorkTabContent);
    if ( dataCol ~= length(p.Results.headerText) )
        warning(cstrcat(char(39), 'headerText', char(39), ' dimension matches not with number of columns in table data field'));
        tex = {};
        return;
    end
    maxFieldLen = max([maxFieldLen' cellfun('length', p.Results.headerText)']');    % get field length of header array and build column based max out of table content and header
end
%



% Build Table Header
%
if ( length(p.Results.headerText) > 0 )
    tempElem = '';
    tempLine = '';
    for i=1:length(p.Results.headerText)
        tempElem                        = p.Results.headerText{i};                  % copy string
        tempElem(end+1:maxFieldLen(i))  = ' ';                                      % fill with blanks
        tempLine                        = cstrcat(tempLine, tempElem, ' & ');       % append and prepare for next col
    end
    tableHeader = cstrcat('    ', tempLine(1:end-2), '  \\', texHeadLineSeparator); % remove last &, new line, header/data separation
end
%


% Build Table Content
%
tableContent = {};
for i=1:dataRow
    tempElem = '';
    tempLine = '';
    for j=1:dataCol
        tempElem                        = myWorkTabContent{i,j};                % copy element
        tempElem(end+1:maxFieldLen(j))  = ' ';                                  % blank padding
        tempLine                        = cstrcat(tempLine, tempElem, ' & ');   % append and prepare for next col
    end
    tableContent{end+1} = cstrcat('    ', tempLine(1:end-2), '  \\\hline');  % finish table row
end
%


% build table
%
if ( p.Results.longtable == true )
    % long table
        % build table
    tex{end+1} = '\begin{longtable}{|';
    for i=1:dataCol
        tex{end} = strcat(tex{end}, 'c|');
    end
    tex{end} = strcat(tex{end}, '}');
        % Caption & lable
    tex{end+1} = '  \caption[Todo, TOC entry]{Todo, Table Description}';
    tex{end+1} = '  \label{tab:part:chapter:section:tablegen}';
        % Table Header Content
    tex{end+1} = '  % Definition Table Header on first page';
    tex{end+1} = '  \\\hline';
    tex{end+1} = tableHeader;       % append first header
    tex{end+1} = '  \endfirsthead';
    tex{end+1} = '  % Definition table header on following pages';
    tex{end+1} = '  \hline';
    tex{end+1} = tableHeader;       % append all other headers
    tex{end+1} = '  \endhead';
        % Table Footer Content
    tex{end+1} = '  % Footer ot all intermediate pages';
    tex{end+1} = cstrcat('  \multicolumn{', num2str(dataCol), '}{|r|}{go on next page}            \\\hline');
    tex{end+1} = '  \endfoot';
    tex{end+1} = '  % Footer on last page';
    tex{end+1} = cstrcat('  \multicolumn{', num2str(dataCol), '}{|r|}{{-}{-}{=}{=} end of table}  \\\hline');
    tex{end+1} = '  \endlastfoot';
        % Table content
    tex{end+1} = '  % Table content';
    tex{end+1} = cstrcat('  % ', strtrim(tableHeader(1:strfind(tableHeader, '\')(1)-1)));
    tex(end+1:end+length(tableContent)) = tableContent;
        % End of Table
    tex{end+1} = '';
    tex{end+1} = '\end{longtable}';

else
    % short table
        % header
    tex{end+1} = '\begin{table}[!htp]';
    tex{end+1} = '  \centering \capstart';
    tex{end+1} = '  \begin{tabular}{|';
        % number of cols
    for i=1:dataCol
        tex{end} = strcat(tex{end}, 'c|');
    end
    tex{end} = strcat(tex{end}, '}  \hline');
        % table header
    tex{end+1} = tableHeader;   % append header
        % table content
    tex(end+1:end+length(tableContent)) = tableContent;
        % table footer
    tex{end+1} = '  \end{tabular}';
    tex{end+1} = '  \caption[Todo, TOC entry]{Todo, Table Description}';
    tex{end+1} = '  \label{tab:part:chapter:section:tablegen}';
    tex{end+1} = '\end{table}';

end


end;
%
%-------------------------------------------------------------------------



%-------------------------------------------------------------------------
% converts number to string in scientific notation
%
function str = texTable_toSiStr (val, frac, noTexUnit)
%%
    unitPrefix  = ['yzafpnum kMGTPEZY'];                        % SI-unit prefixes: https://en.wikipedia.org/wiki/Unit_prefix
    exponent    = strsplit(sprintf('%e',val), 'e');             % exponential notation, split mantissa and exponent
    exponent    = str2num(exponent{2});                         % extract exponent
    siExp       = floor(max(min(exponent, 24), -24)/3);         % apply fence for si prefixes; every three decades new unit prefix
    mantissa    = sprintf('%.*f', frac, val/(10^(siExp*3)));    % calculate new mantissa prepared for SI prefix
    siPrefix    = strrep(unitPrefix(siExp+9), ' ', '');         % get to exponent belonging SI prefix

    if ( noTexUnit == true )
        str = sprintf('%s %s', mantissa, siPrefix);             % build converted unit, separator one blank
    else
        str = sprintf('\\unit[%s]{%s}', mantissa, siPrefix);    % build converted unit, separator half blank
    end;

end;
%-------------------------------------------------------------------------
