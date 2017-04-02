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



function solutions = resistorSubstitution(varargin)
%%
%%  Usage
%%  =====
%%
%%  value:                      double                          -> resistor value to replace;
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

p.addRequired('value', @isnumeric);             % mandatory argument

p.addOptional('eseries', 'E24', @(x) any (strcmp (x, {'E3', 'E6', 'E12', 'E24', 'E48', 'E96', 'None'})));   % Info: https://de.wikipedia.org/wiki/E-Reihe
p.addOptional('numSubstitutionResistors', 2, @isnumeric);                                                   % allowed number of resistors for substituion
p.addOptional('resistanceRange', [1 10e6], @isvector);                                                      % Min/max of resistor for E-Series generation, or collection of resistors
p.addOptional('topology', 'parallel', @(x) any (strcmp (x, {'parallel', 'serial', 'mixed'})));              % subsitution topology, parallel only at the moment
p.addOptional('numSolution', 7, @isnumeric);                                                                % maximum number of solutions
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
tic;
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
end;
%



% Reduce available resistors based on substitution mode to reduce solution space
%
if (strcmp('parallel', p.Results.topology))
    minResiError    = p.Results.value*1000;                                             % 1 promile is minimal residual error
    avlValIdx       = find(avlValues >= p.Results.value & avlValues <= minResiError);   % find values
    avlValues       = avlValues(avlValIdx);
end;
%



% build permutation table
%
permTable(1:p.Results.numSubstitutionResistors) = 1;                                                                                                                        % init permutation table
for (i=1:length(avlValues)^p.Results.numSubstitutionResistors-1)                                                                                                            % loop runs until full permutation is created                      
    permTable(end+1,1:p.Results.numSubstitutionResistors) = [permTable(end,1:p.Results.numSubstitutionResistors-1) permTable(end,p.Results.numSubstitutionResistors)+1];    % increment last index in table
    for i=p.Results.numSubstitutionResistors:-1:2
        if(permTable(end,i) > length(avlValues))                                                                                                                            % digit overflow
            permTable(end,i)    = 1;
            permTable(end,i-1)  = permTable(end,i-1)+1;
        end;
    end;
end;
%



% remove double index from list, cause it makes no difference to cal value of R1||R2 or R2||R1
%
[row col]   = size(permTable);
rmvIdx      = [];
for i=1:row
    if (sum(isnan(permTable(i,:))) == 0)                                                    % check if unvalid marked table was found
        rmvPerm             = perms(permTable(i,:));                                        % build from this line of permutation table, all permutation to look in data set
        if (range(rmvPerm) == 0)                                                            % skip all matrix uniformed value matrixes
            rmvPerm(1:end,1:col) = 0;                                                       % make removing table invalid
        end;
        rmvIdxTemp              = find(ismember(permTable, rmvPerm(2:end,:), 'rows') == 1); % get indexes from all lines who matches with permutations
        permTable(rmvIdxTemp,:) = NaN;                                                      % mark dataset is invalid
        rmvIdx                  = [rmvIdx rmvIdxTemp];                                      % collect for one-shoot remove
    end;
end;
permTable(rmvIdx,:) = [];
%



% caclulate resistance and store top values
%
solutions   = struct([]);                                               % create structure array
for i=1:length(permTable)
    % build new element
    act.Rused   = avlValues(permTable(i,:));                            % store used resistor values
    act.Rsub    = 1/sum([1./avlValues(permTable(i,:))]);                % Rges = 1 / (1/R1 + 1/R2 + 1/Rn + ...)
    act.Err     = abs((act.Rsub - p.Results.value))/p.Results.value;    % calculate relative mismatch
    
    % insert in known substitution list
    if (length(solutions) == 0)                             % check for beginning of new list
        solutions(1)    = act;                              % store first structure element in list
    else                                                    % apply insert sort
        for n=1:length(solutions)
            if(solutions(n).Err > act.Err)                  % check error and insert of element error is larger then actual elemment
                solutions(n+1:end+1)    = solutions(n:end); % shift all elements to next position
                solutions(n)            = act;              % insert new element
                break;
            end;
        end;
    end;
    
    % if longer then desired, cut off
    solutions(p.Results.numSolution+1:end)  = [];   % discard all not needed elements
end;
%



% User Output
%
if (p.Results.brief == false)
	toc;                        % print measured time to console


end;
%
