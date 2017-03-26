% ***********************************************************************
%  License          : LGPL v3
%
%  Author           : Andreas Kaeberlein
%  eMail            : andreas.kaeberlein@web.de
%
%  File             : resistorSubstitution.m
%  Description      : replaces given resistor value by E-series combination
%
%  Sources          : none
%
%  on               : 2017-03-26
% ************************************************************************



function subsResistors = resistorSubstitution(value, rele, eseries)
%%
%%  Usage
%%  =====
%%
%%  value:          double          -> resistor value to replace
%%  rele:           double          -> residualer relative replacement error (rele = dR/R)      [ 1% ]
%%  eseries:        integer         -> used E series for searching                              [ 96 ]
%%  listings:       string array    -> found files
%%