%***********************************************************************
% License           : LGPL v3
%
% Author            : Andreas Kaeberlein
% eMail             : andreas.kaeberlein@web.de
%
% File              : listFile.m
% Description       : list files in given directory
%
% Sources           : none
%
% on                : 2017-02-09
%************************************************************************



function listings = listFile(path, pattern, uiSel, subfolder)
%%
%%  Usage
%%  =====
%%
%%  path:           string          -> path to file location
%%  pattern:        string          -> matching pattern
%%  uiSel:          boolean         -> user interface selection
%%  subfolder:      integer         -> numbers of sub folder levels [-1 for inifnity search]
%%  listings:       string array    -> found files
%%


% process default params
switch nargin
    case 1
        pattern     = '*';      % matching pattern
        uiSel       = false;    % disable user selection
        subfolder   = 0;        % skip all sub folders
    
    case 2
        uiSel       = false;    % disable user selection
        subfolder   = 0;        % skip all sub folders
        
    case 3
        subfolder   = 0;        % skip all sub folders
end


% append '/' if path not ends
if (path(end) != '/')
    path(end+1) = '/';
end


% init some variables
listings        = {};
discoverGoesOn  = true;
actSubFoldLevel = 0;
subPathsOld     = {''};


% diretory structure discovering loop
while (discoverGoesOn == true)
    
    % disable discover, enable at first sub dir match
    discoverGoesOn  = false;
    subPathsNew     = {};
    
    % look for directories in path
    for i=1:length(subPathsOld)
        tempList    = dir(strcat(path, subPathsOld{i}, '*'));                               % list complete content
        % process found elements in subpath
        for j=1:length(tempList)
            if (tempList(j).isdir == 1)                                                     % directory found
                if ((tempList(i).name != '.') || (tempList(i).name != '..'))
                    discoverGoesOn      = true;
                    subPathsNew{end+1}  = strcat(subPathsOld{i}, tempList(j).name, '/');    % build subpath
                end
            end
        end
    end
    
    % look for pattern matching files
    for i=1:length(subPathsOld)
        tempList    = dir(strcat(path, subPathsOld{i}, pattern));               % list complete content
        % process pattern matching files
        for j=1:length(tempList)
            if (tempList(j).isdir == 0)
                listings{end+1} = strcat(subPathsOld{i}, tempList(j).name);     % store filename
            end
        end
    end
    
    % check for abort condition
    if ((subfolder != -1) && (actSubFoldLevel >= subfolder))
        break;
    end;    
    
    % increment subfolderlevel
    actSubFoldLevel = actSubFoldLevel + 1;

    % store new list
    subPathsOld = subPathsNew;
    
end


% return function if no user selection
if (~uiSel)
    return
end


% selection dialog header
disp('');
tempLine = cstrcat('Found ', char(39), pattern, char(39), ' matching Files:');
disp(tempLine);
tempLine(1:end) = '-';  % underline table head
disp(tempLine);


% list files to select
printDigits = length(num2str(length(listings)));
for i=1:length(listings)
    tempLine = '';
    tempLine(1:printDigits-length(num2str(i))+1) = ' ';
    tempLine = cstrcat(tempLine, '[', sprintf('%d', i), ']:   ', listings{i});
    disp(tempLine);
end;
disp('');


% input selection dialog
userSel = input(sprintf('Please select files to process (f.e. [1])\n'));


% if no selection return complete list
if (length(userSel) == 0)
    return
end


% check input typ for selection
if (ischar(userSel))
    listings = listings(str2num(userSel));
else
    listings = listings(userSel);
end
