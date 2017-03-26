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



function subsResistors = resistorSubstitution(value, varargin)
%%
%%  Usage
%%  =====
%%
%%  value:          double          -> resistor value to replace
%%  rele:           double          -> residualer relative replacement error (rele = dR/R)      [ 1% ]
%%  eseries:        integer         -> used E series for searching                              [ 96 ]
%%  listings:       string array    -> found files
%%


% parse input
% SRC: https://www.gnu.org/software/octave/doc/interpreter/Variable_002dlength-Argument-Lists.html
%
p                   = inputParser;  % init input parsewr
defaultResRelError  = 1e-2;         % default relative resistor mismatch is 1%
defaultEseries      = 24;           % E24 is the default series
defaultResRange     = [1 10e6];     % Min/Max of avialable Resistors for substitution

%addOptional(p, 'ResistorRange', defaultResRange, @ismatrix);    % optional parameter
addRequired(p,'width',@isnumeric);


parse(p, value, varargin{:});       % parse arguments
%




disp(num2str(defaultResRange))
