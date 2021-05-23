% ************************************************************************
%  @author:         Andreas Kaeberlein
%  @copyright:      Copyright 2021
%  @credits:        AKAE
%
%  @license:        GPLv3
%  @maintainer:     Andreas Kaeberlein
%  @email:          andreas.kaeberlein@web.de
%
%  @file:           listFile.m
%  @date:           2016-06-13
%
%  @brief:          file selection dialog
%
% ************************************************************************



function files = listFile(dirPath, varargin)
%%  Usage
%%  =====
%%
%%  Arguments:
%%  ----------
%%    dirPath       string      -> path to the file
%%    name          string      -> file name with extension for files to look for, '*' is wildcard
%%    subfolder     integer     -> search until subfolder level
%%    dironly       boolean     -> only dir to file is listed
%%    uiSel         boolean     -> enable interactive selection
%%    fullPath      boolean     -> provides full path to file
%%
%%  Return:
%%  -------
%%    files         cell array  -> paths to files
%%
%%



% parse input
% SRC: https://www.gnu.org/software/octave/doc/interpreter/Multiple-Return-Values.html#XREFinputParser
% SRC: https://de.mathworks.com/help/matlab/ref/inputparser.addoptional.html
%
p = inputParser();      % create parser

p.addSwitch('uiSel');                       % user interface file selection enable
p.addSwitch('dironly');                     % no files, only paths are returned
p.addSwitch('fullPath');                    % prepend entry point to returned file path
p.addParameter('name', '*.*', @ischar);     % file name, or part of it
p.addParameter('subfolder', 0, @isnumeric); % file name, or part of it

p.parse(varargin{:});   % parse inputs
%



% Prepare Path
%
% allign to OS path separator
dirPath = strrep(dirPath, '/', filesep);
dirPath = strrep(dirPath, '\', filesep);
% drop last path separator if specified
if ( (filesep == dirPath(end)) )
    dirPath = dirPath(1:end-1);
end
%


% search recursive
%
files = {};
files = listFile_recursion( files, dirPath, '.', p.Results.name, p.Results.subfolder );
%


% drop first './' -> artifact from search
%
for i=1:length(files)
    files{i} = files{i}(3:end);
end
%


% propagate paths to files only
%
if ( p.Results.dironly )
    for i=1:length(files)
        [files{i}, ~, ~] = fileparts(files{i}); % filepath only
    end
    files = unique(files);  % if multiples files are in one directory
end;
%


% file selection dialog
%
if ( p.Results.uiSel )
    numDigit = length(num2str(length(files)));  % get number of digits
    disp(cstrcat('Found ', char(39), p.Results.name, char(39), ' files:'));
    for i=1:length(files)
        disp(cstrcat('  [', sprintf('%0*d', numDigit, i), ']:  ', files{i}));
    end
    disp('');
    % user input
    selector = input(sprintf(cstrcat('Select Files, ', char(39), ':', char(39), ' - for all\n')), 's'); % read all as character
    if ( 0 == length(selector) )
        files = {};
    elseif ( 1 == strcmp(selector, ':'))
    else
        files = files(str2num(selector));
    end
end
%


% Provide full path
%
if ( p.Results.fullPath )
    if ( 0 < length(files) )
        files = strcat(dirPath, filesep, files);
    end
end
%


end
%%



%%
function files = listFile_recursion( files, entryPath, curPath, fileName, maxSubDir )
%%  Usage
%%  =====
%%
%%  Arguments:
%%  ----------
%%    files         cell        -> listing of files which meet given specification
%%    entryPath     char        -> start path for folder/file discover
%%    curPath       char        -> current file search path
%%    fileName      char        -> file name with extension to search for, wildcards ('*') allowed
%%    maxSubDir     integer     -> maximum sub folder recursion deep
%%
%%  Return:
%%  -------
%%    files         cell        -> paths to files
%%
%%



% list files in current dir
%
listing = dir(cstrcat(entryPath, filesep, curPath, filesep, fileName)); % list complete content
for i=1:length(listing)
    if ( 0 == listing(i).isdir )    % file found
        files{end+1} = cstrcat(curPath, filesep, listing(i).name);
    end;
end
%


% list dirs in current dir
%
listing = dir(cstrcat(entryPath, filesep, curPath));    % list complete content
for i=1:length(listing)
    if ( 1 == listing(i).isdir )    % directory found
        if ( (1 ~= strcmp(listing(i).name, '.')) && (1 ~= strcmp(listing(i).name, '..')) )
            if ( maxSubDir > length(strfind(curPath, filesep)) )    % go one dir level deeper
                files = listFile_recursion( files, entryPath, cstrcat(curPath, filesep, listing(i).name), fileName, maxSubDir );
            end
        end
    end
end
%


end
%%
