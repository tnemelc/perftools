% 2CXMUI.m
% brief: 2CXM user interface (for test)
% 2CXM User Interface
% author: C.Daviller
% date: 16-Aug-2017


function  TwoCXMUI()

fm = figureMgr.getInstance();
fm.newFig('UI');
f = fm.getFig('UI');
hleList = [];

lin = [0.85 0.05];
col = [0.05 0.3 0.9];


uicontrol('Parent',f,...
    'Style','text',...
    'units', 'normalized', ...
    'Position',[col(1) lin(1) 0.2 0.1],...
    'String','AIF input path');

%edit boxes
editInputAif = uicontrol('Parent',f,...
    'Style','edit',...
    'units', 'normalized', ...
    'Position',[col(2) lin(1) 0.55 0.1],...
    'String','D:\02_Matlab\Data\SignalSimulation\aifShaper\',...
    'Callback',@popup_callback);


% browse button1
uicontrol('Style', 'pushbutton',...
    'units', 'normalized', ...
    'Position', [col(3) lin(1) 0.05 0.1],...
    'String', '...',...
    'Callback', @browseInputCb);



keySet =     {'Fp',          'PS',          'vp',     've',    'Tsample'}; % append set name here
initValSet = {30,             10,             5,        20,          7  }; %append new param init value
minValSet =  {1,               3,             1,         1,          5  }; %append new param min value
maxValSet =  {45,             90,            20,        60,         15  };%append new param max value
factorSet =  {0.1,           0.1,           0.01,     0.01,        0.1  };%append new factor value (1 if no need to factor)
unitSet =    {'ml/(g*min)', 'ml/(g*min)',  'A.U',     'A.U',       's'  };

valMap = containers.Map(keySet, initValSet);
minValMap = containers.Map(keySet, minValSet);
maxValMap = containers.Map(keySet, maxValSet);
editBoxMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
sldrMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
factorMap = containers.Map(keySet, factorSet);


nbControls = size(keySet, 2);
ctrlMargin = 0.05;

ctrlHgt = (0.5 / nbControls) - ctrlMargin;

for i = 1 : nbControls
    %set real value for val map
    valMap(char(keySet(i))) = valMap(char(keySet(i))) * factorMap(char(keySet(i)));
    
    hPos = 0.75 - (i * (ctrlHgt + ctrlMargin));
    
    % text
    uicontrol('Style', 'text',...
        'units', 'normalized', ...
        'position', [0.05 hPos 0.1 ctrlHgt],...
        'string', keySet(i));
    
    %slider
    sldrMap(char(keySet(i))) = ...
        uicontrol('Style', 'slider',...
        'units', 'normalized', ...
        'Value', valMap(char(keySet(i))) / factorMap(char(keySet(i))),...
        'Min',minValMap(char(keySet(i))), ...
        'Max', maxValMap(char(keySet(i))), ...
        'Position', [0.2 hPos 0.45 ctrlHgt],...
        'Callback', {@sldrCb, keySet(i)});
    
    %edit box
    editBoxMap(char(keySet(i))) = ...
        uicontrol('Style', 'edit',...
        'units', 'normalized', ...
        'String', valMap(char(keySet(i))),...
        'Position', [0.7 hPos 0.1 ctrlHgt], ...
        'Callback', {@eboxCb, keySet(i)});
    
    % units
    %     hPos = 30 * (size(keySet, 2) + 1 - i) + 90;
    uicontrol('Style', 'text',...
        'units', 'normalized', ...
        'Position', [0.85 hPos 0.1 ctrlHgt],...
        'String', unitSet(i));
end




%go button
goBtn = uicontrol('Style', 'pushbutton',...
    'units', 'normalized', ...
    'Position', [col(1) lin(2) 0.9 0.1],...
    'String', 'GO!',...
    'Callback', @GoCb);


%% callback functions

    function GoCb(source, arg1)
        %fm.closeAllBut('UI');
        fm.closeUnmanaged();
        aif = loadmat(fullfile(get(editInputAif, 'String'), 'aifSimu.mat'));
        tAcq = loadmat(fullfile(get(editInputAif, 'String'), 'tAcq.mat'));
        for k = 1 : valMap.length
           param.(char(keySet(k))) =  valMap(char(keySet(k)));
        end
        time = tAcq(1) : param.Tsample : tAcq(end);
        aif = interp1(tAcq, aif, time);
        TwoCXM(aif, time, param, true, true);
    end

    function browseInputCb(source, arg1)
        % arg1??? don't know what is used for...
        set(editInputDcm, 'String', uigetfile('D:\02_Matlab\Data\SignalSimulation\aifShaper\'));
    end
    function sldrCb(source, arg1, arg2)
        % arg1??? don't know what is used for...
        val  =  floor(get(source, 'Value'))  * factorMap(char(arg2));
        %str = char(cell(floor(get(source, 'Value'))));
        %nbPE  = str2num(str);
        valMap(char(arg2)) = val;
        set(editBoxMap(char(arg2)), 'String', val);
    end%sldrCb

    function eboxCb(source, arg1, arg2)
        val  =  str2num(get(source, 'String'));
        %str = char(cell(floor(get(source, 'Value'))));
        %nbPE  = str2num(str);
        valMap(char(arg2)) = val;
        set(sldrMap(char(arg2)), 'Value', valMap(char(arg2)) / factorMap(char(arg2)));
    end%eboxCb
end