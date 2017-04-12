% ***********************************************************************
%  License          : LGPLv3
%
%  Author           : Andreas Kaeberlein
%  eMail            : andreas.kaeberlein@web.de
%
%  File             : resistorSubstitution.m
%  Description      : replaces given resistor value by E-series combination
%  Octave           : 4.0
%
%  Sources          : none
%
%  on               : 2017-03-26
% ************************************************************************



%-------------------------------------------------------------------------
%
function solutions = resistorSubstitution(varargin)
%%
%%  Usage
%%  =====
%%
%%  value:                      double                          -> resistor value to replace;
%%  relSubstitutionError:       double          [ 0 ]           -> relative error due resistor value substitution; zero means full search
%%  eseries:                    string          [ E24 ]         -> used E series for searching;
%%  numSubstitutionResistors:   integer         [ 2 ]           -> maximum number of resistors for substitution; 
%%  resistanceRange:            double array    [ 1 10e6 ]      -> collection of resistors or min/max value for eseries;
%%  topology                    string          [ parallel ]    -> resistor substituion topology    
%%



% parse input
% SRC: https://www.gnu.org/software/octave/doc/interpreter/Multiple-Return-Values.html#XREFinputParser
% SRC: https://de.mathworks.com/help/matlab/ref/inputparser.addoptional.html
%
p               = inputParser();            % create object
p.FunctionName  = 'resistorSubstitution';   % set function name

p.addRequired('value', @isnumeric);         % mandatory argument

p.addOptional('relSubstitutionError', 0, @isnumeric);                                                       % relative resistor substitution error
p.addOptional('eseries', 'E24', @(x) any (strcmp (x, {'E3', 'E6', 'E12', 'E24', 'E48', 'E96', 'None'})));   % Info: https://de.wikipedia.org/wiki/E-Reihe
p.addOptional('numSubstitutionResistors', 2, @isnumeric);                                                   % allowed number of resistors for substituion
p.addOptional('resistanceRange', [1 10e6], @isvector);                                                      % Min/max of resistor for E-Series generation, or collection of resistors
p.addOptional('topology', 'parallel', @(x) any (strcmp (x, {'parallel', 'serial', 'mixed'})));              % subsitution topology, parallel only at the moment
p.addOptional('numSolution', 3, @isnumeric);                                                                % maximum number of solutions
p.addSwitch('brief');                                                                                       % if set console output is disabled

p.parse(varargin{:});   % Run created parser on inputs
%



% E3 to E96 Tables
% SRC: http://www.elektronik-kompendium.de/sites/bau/1109071.htm
%
ser.E3  =   [   1.00 2.20 4.70                                              ];

ser.E6  =   [   1.00 1.50 2.20 3.30 4.70 6.80                               ];

ser.E12 =   [   1.00 1.20 1.50 1.80 2.20 2.70 3.30 3.90 4.70 5.60 6.80 8.20 ];

ser.E24 =   [   1.00 1.10 1.20 1.30 1.50 1.60 1.80 2.00 2.20 2.40 2.70 3.00 ...
                3.30 3.60 3.90 4.30 4.70 5.10 5.60 6.20 6.80 7.50 8.20 9.10 ];

ser.E48 =   [   1.00 1.05 1.10 1.15 1.21 1.27 1.33 1.40 1.47 1.54 1.62 1.69 ...
                1.78 1.87 1.96 2.05 2.15 2.26 2.37 2.49 2.61 2.74 2.87 3.01 ...
                3.16 3.32 3.48 3.65 3.83 4.02 4.22 4.42 4.64 4.87 5.11 5.36 ...
                5.62 5.90 6.19 6.49 6.81 7.15 7.50 7.87 8.25 8.66 9.09 9.53 ];

ser.E96 =   [   1.00 1.02 1.05 1.07 1.10 1.13 1.15 1.18 1.21 1.24 1.27 1.30 ...
                1.33 1.37 1.40 1.43 1.47 1.50 1.54 1.58 1.62 1.65 1.69 1.74 ...
                1.78 1.82 1.87 1.91 1.96 2.00 2.05 2.10 2.15 2.21 2.26 2.32 ...
                2.37 2.43 2.49 2.55 2.61 2.67 2.74 2.80 2.87 2.94 3.01 3.09 ...
                3.16 3.24 3.32 3.40 3.48 3.57 3.65 3.74 3.83 3.92 4.02 4.12 ...
                4.22 4.32 4.42 4.53 4.64 4.75 4.87 4.99 5.11 5.23 5.36 5.49 ...
                5.62 5.76 5.90 6.04 6.19 6.34 6.49 6.65 6.81 6.98 7.15 7.32 ...
                7.50 7.68 7.87 8.06 8.25 8.45 8.66 8.87 9.09 9.31 9.53 9.76 ];
%



% Start Processing Time measurement
%
if (p.Results.brief == false)
    tic;
end;
%



% build available resistor table
%
if (strcmp('None', p.Results.eseries))
    avlValues   = p.Results.resistanceRange;  % copy values
else
    if (length(p.Results.resistanceRange) > 2)                % check parameters
        error('Use [MinVal MaxVal] in Eseries mode');   % generate user message
    end

    % some preparations
    [s expRmin]     = strread(strrep(sprintf('%E',p.Results.resistanceRange(1)),'E','#'),'%f#%f');  % extract exponents
    [s expRmax]     = strread(strrep(sprintf('%E',p.Results.resistanceRange(2)),'E','#'),'%f#%f');

    % build decade series
    avlValues = [];
    for i=expRmin:1:expRmax
        for j=1:length(ser.(p.Results.eseries))
            avlValues(end+1) = ser.(p.Results.eseries)(j)*10^i;
        end;
    end;
    
    % filter to fence
    avlValues = avlValues(find(avlValues >= p.Results.resistanceRange(1) & avlValues <= p.Results.resistanceRange(2)));
    
end;
%



% Check if resistor value is in standard series located
%
if (length(find(avlValues == p.Results.value)) > 0)
    act.Rused       = p.Results.value;
    act.Rsub        = p.Results.value;
    act.Err         = 0;
    solutions(1)    = act;
    skipSearch      = true;                 % skip solution searching loop
else
    act.Rused       = [Inf];                % fill with dummy data to avoid check for first element in loop
    act.Rsub        = [Inf];                % 
    act.Err         = 1;                    %
    solutions       = act;                  % create structure array    
    skipSearch      = false;                % start solution searching loop
end;
%



% Reduce available resistors based on substitution mode to reduce solution space
%
if ((skipSearch == false) && (strcmp('parallel', p.Results.topology)))
    if (p.Results.relSubstitutionError == 0)                                        % reduce number of substitution value based on allowed relativ error
        maxValue    = Inf;
    else
        maxValue    = p.Results.value*(1/p.Results.relSubstitutionError);
    end;
    avlValIdx       = find(avlValues >= p.Results.value & avlValues <= maxValue);   % find values
    avlValues       = avlValues(avlValIdx);
end;
%



% calculate resistor permutations
%
varies(1:p.Results.numSubstitutionResistors)    = 1;                                                    % init Array
calced                                          = [];                                                   % collection of tryed permutations
maxLoopIteration                                = length(avlValues)^p.Results.numSubstitutionResistors; % maximum number of loop iteration for full decicion tree calculation
while(skipSearch == false)
    % calculate notryed resistor combination
    if(sum(ismember(calced, varies(end,:), 'rows')) == 0)                   % check if actual permutation was once again tryed
        % build permutation from actual veriations
        actCalced   = unique(perms(varies(end,:)), 'rows');                 % in parallel mode makes no difference to calc R1||R2 or R2||R1
        calced      = vertcat(calced, actCalced);                           % save varied values
    
        % calculate actual resistor combination
        act.Rused   = avlValues(varies(end,:));                             % store used resistor values
        act.Rsub    = 1/sum([1./avlValues(varies(end,:))]);                 % Rges = 1 / (1/R1 + 1/R2 + 1/Rn + ...)
        act.Err     = abs((act.Rsub - p.Results.value))/p.Results.value;    % calculate relative mismatch
        
        % inject element in solution table  
        for n=1:length(solutions)
            if(solutions(n).Err > act.Err)                                  % check error and insert of element error is larger then actual elemment
                solutions(n+1:end+1)                    = solutions(n:end); % shift all elements to next position
                solutions(n)                            = act;              % insert new element
                solutions(p.Results.numSolution+1:end)  = [];               % discard all not needed elements
                if (act.Err <= p.Results.relSubstitutionError)              % check if actual combination meets requirements
                    skipSearch = true;                                        % leave while loop
                end;
                break;                                                      % after insertion leave loop
            end;
        end;
    end;
    
    % build new resistor combination
    varies(end+1,1:p.Results.numSubstitutionResistors) = [varies(end,1:p.Results.numSubstitutionResistors-1) varies(end,p.Results.numSubstitutionResistors)+1]; % increment last index in table
    for n=p.Results.numSubstitutionResistors:-1:2                                                                                                               % downto 2, cause left value index needs no overflow, then we are finished
        if(varies(end,n) > length(avlValues))                                                                                                                   % digit overflow
            varies(end,n)   = 1;
            varies(end,n-1) = varies(end,n-1)+1;
        end;
    end;
        
    % check for next iteration
    [rowCalced colCalced]   = size(calced);     % get size of caclulated table
    [rowVaries colVaries]   = size(varies);     %
    if (rowCalced >= maxLoopIteration || rowVaries >= maxLoopIteration)
        skipSearch = true;
    end;
end;
%



% Function finished in case of brief output
%
if (p.Results.brief == true)
    return;
end;
%



% Warning of non reaching error requirement
%
toc;                                                                                                                % print measured time to console
if (solutions(1).Err > p.Results.relSubstitutionError)
    warning(sprintf('%s%0.2e%s', 'Relative Resistor Substitution Error with |', solutions(1).Err, '| not met'));    % warning of not meeting of relative error constraint
end;
%



% Convert Resulst to string table for CLI output
%
printBuffer{1,1} = 'Resistors';  % build table header
printBuffer{1,2} = 'Rval';
printBuffer{1,3} = 'Error';
for i=1:length(solutions)
    % prepare resistor substituion for table output
    printBuffer(i+1,1) = {'( '};
    for n=1:length(solutions(i).Rused)-1 
        printBuffer(i+1,1) = cstrcat(printBuffer{i+1,1}, resistorSubs_num2sci(solutions(i).Rused(n), 2), ' || ');
    end;
    printBuffer(i+1,1)  = cstrcat(printBuffer{i+1,1}, resistorSubs_num2sci(solutions(i).Rused(end), 2), ' )');
    % prepare absoulte value and relative error
    printBuffer(i+1,2)  = resistorSubs_num2sci(solutions(i).Rsub, 2);
    printBuffer(i+1,3)  = strcat(resistorSubs_num2sci(((solutions(i).Rsub-p.Results.value)/p.Results.value)*100, 0), '%');
end;
%


% Print table
%
disp('');
numChar(1)  = max(cellfun('length', printBuffer(:,1)));         % get length of substitution resistor array
numChar(2)  = max(cellfun('length', printBuffer(:,2)));
numChar(3)  = max(cellfun('length', printBuffer(:,3)));
[row col]   = size(printBuffer);
for i=1:row
    temp                    = printBuffer{i,1};
    temp(end+1:numChar(1))  = ' ';
    printBuffer{i,1}        = temp;
    temp                    = printBuffer{i,2};
    temp(end+1:numChar(2))  = ' ';
    printBuffer{i,2}        = temp;
    temp                    = printBuffer{i,3};
    temp(end+1:numChar(3))  = ' ';
    printBuffer{i,3}        = temp;
    disp(cstrcat(printBuffer{i,1}, ' ', printBuffer{i,2}, ' ', printBuffer{i,3}));
end;

end;
%
%-------------------------------------------------------------------------




%-------------------------------------------------------------------------
% Help Function for SI-Number conversion
%
function str = resistorSubs_num2sci(num, nonZeroFrac)
%%
    unitPrefix  = ['yzafpnum kMGTPEZY'];                                            % SI-unit prefixes: https://en.wikipedia.org/wiki/Unit_prefix https://de.wikipedia.org/wiki/Vorsätze_für_Maßeinheiten
    [s e]       = strread(strrep(sprintf('%E',num),'E','#'),'%f#%f');               % extract exponent
    preIdx      = floor(max(min(e, 24), -24)/3);                                    % apply fence for si prefixes; every three decades new unit prefix 
    dig         = 0;
    if (nonZeroFrac != 0)                                                           % if zero frac required skip
        digStr  = strsplit(sprintf('%.*f', nonZeroFrac, num/(10^(3*preIdx))), '.'); % build float with defined digits after decimal; split at '.';
        digStr  = digStr{end};                                                      % get digits
        for i=length(digStr):-1:1                                                   % look from trailing end forward of digits equal zero
            if (digStr(i) != '0')
                dig = i;
                break;
            end;
        end;
    end;    
    str = sprintf('%.*f%s', dig, num/(10^(3*preIdx)), strrep(unitPrefix(preIdx+9), ' ', ''));   % build relaeasing string, with variable number of digits after decimal
end;
%
%-------------------------------------------------------------------------
