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



function subsResistors = resistorSubstitution(varargin)
%%
%%  Usage
%%  =====
%%
%%  value:          double          -> resistor value to replace
%%  tolerance:      double          -> residualer relative deviation (tolerance = dR/R)     [ 1% ]
%%  eseries:        string          -> used E series for searching                          [ E24 ]
%%  resistors:      double array    -> collection of resistors or min/max value for eseries [ 1 10e6 ]
%%


% parse input
% SRC: https://www.gnu.org/software/octave/doc/interpreter/Variable_002dlength-Argument-Lists.html
% SRC: https://de.mathworks.com/help/matlab/ref/inputparser.addoptional.html
%
p 				= inputParser();            % create object
p.FunctionName	= 'resistorSubstitution';   % set function name

p.addRequired('value', @isnumeric);             % mandatory argument

p.addOptional('tolerance', 0.01, @isnumeric);                                                                       % tolerance with 0.01 default
p.addOptional('eseries', 'E24', @(x) any (strcmp (x, {'E3', 'E6', 'E12', 'E24', 'E48', 'E96', 'E192', 'None'})));   % Info: https://de.wikipedia.org/wiki/E-Reihe
p.addOptional ('resistors', [1 10e6], @isvector);                                                                   % Min/max of resistor for E-Series generation, or collection of resistors

p.parse(varargin{:});   % Run created parser on inputs
%






p.Results.value
p.Results.tolerance
p.Results.eseries
p.Results.resistors


