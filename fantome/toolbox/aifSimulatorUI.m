% aifSimulatorUI.m
% brief: 
% aifSimulator User Interface
% author: C.Daviller
% date: 13-Dec-2017 


 function  aifSimulatorUI()

 close all;
%clear all;
clc;


fm = figureMgr.getInstance();
fm.newFig('aifSimulator UI');
fm.resize('aifSimulator UI', 1, 2)

% A1=0.4;A2=0.15;A3=0.151;
% T1=15;T2=29;T3=34;
% sigma1=3.58;sigma2=8.35;
% s=0.5; beta=1.94e-3;

keySet =     {     'A1',    'A2',  'A3',  'A4', 'T1', 'T2', 'T3',  'T4', 'sigma1',  'sigma2', 's', 'w4', 'beta'}; % append set name here
initValSet = {       34,      4,    3,    5,    137,   50,   67,   70,   358,           400,   5,  10,   194}; %append new param init value
minValSet =  {       10,      1,     1,    1,    10,    1,    1,   30,   100,           300,   1,  1,    100}; %append new param min value
maxValSet =  {      200,    100,   100,   10,  300,   70,   80,   90,   400,           15e3,  10,  1e2,  250};%append new param max value
factorSet =  {     1e-3,  1e-3,  1e-3,  1e-3,  1e-1,    1,    1,    1,  1e-2,          1e-2, 0.1, 1e-2,   1e-6};%append new factor value (1 if no need to factor)

valMap = containers.Map(keySet, initValSet);
minValMap = containers.Map(keySet, minValSet);
maxValMap = containers.Map(keySet, maxValSet);
editBoxMap = containers.Map(keySet, initValSet);
sldrMap = containers.Map(keySet, initValSet);
factorMap = containers.Map(keySet, factorSet);

for i = 1 : size(keySet, 2)
    %set real value for val map
    valMap(char(keySet(i))) = valMap(char(keySet(i))) * factorMap(char(keySet(i)));
    % text
    hPos = 30 * (size(keySet, 2) + 1 - i) + 90;
    uicontrol('Style', 'text',...
        'Position', [10 hPos 80 20],...
        'String', keySet(i));
    
    %slider
    sldrMap(char(keySet(i))) = ...
        uicontrol('Style', 'slider',...
        'Value', valMap(char(keySet(i))) / factorMap(char(keySet(i))),...
        'Min',minValMap(char(keySet(i))), ...
        'Max', maxValMap(char(keySet(i))), ...
        'Position', [100 hPos 300 20],...
        'Callback', {@sldrCb, keySet(i)});
    
    %edit box
    editBoxMap(char(keySet(i))) = ...
        uicontrol('Style', 'edit',...
        'String', valMap(char(keySet(i))),...
        'Position', [430 hPos 50 20], ...
        'Callback', {@eboxCb, keySet(i)});
end

% button
uicontrol('Style', 'pushbutton',...
    'Position', [10 30 520 50],...
    'String', 'GO!',...
    'Callback', @GoCb);


%% CB functions
    function sldrCb(source, arg1, arg2)
        % arg1??? don't know what is used for...
        val  =  floor(get(source, 'Value'))  * factorMap(char(arg2));
        %str = char(cell(floor(get(source, 'Value'))));
        %nbPE  = str2num(str);
        valMap(char(arg2)) = val;
        set(editBoxMap(char(arg2)), 'String', val);
        GoCb();
    end

    function eboxCb(source, arg1, arg2)
        val  =  str2num(get(source, 'String'));
        %str = char(cell(floor(get(source, 'Value'))));
        %nbPE  = str2num(str);
        valMap(char(arg2)) = val;
        set(sldrMap(char(arg2)), 'Value', valMap(char(arg2)) / factorMap(char(arg2)));
        GoCb();
    end


    function GoCb(source, arg)
%         str = sprintf('%s: %f, %s: %f, %s: %f, %s: %f',...
%             char(keySet(1)), valMap(char(keySet(1))), ...
%             char(keySet(2)), valMap(char(keySet(2))), ...
%             char(keySet(3)), valMap(char(keySet(3))), ...
%             char(keySet(4)), valMap(char(keySet(4))));
%         h = msgbox(str);
        fm.closeAllBut('aifSimulator UI');
        try
            params = getParameters();
        % call your function here:
        aifSimulator(params);
%         valMap(char(keySet(1))),...
%             valMap(char(keySet(2))),...
%             valMap(char(keySet(3))),...
%             valMap(char(keySet(4))),...
%             valMap(char(keySet(5))),...
%             valMap(char(keySet(6))),...
%             valMap(char(keySet(7))),...
%             valMap(char(keySet(8))),...
%             valMap(char(keySet(9))),...
%             valMap(char(keySet(10))),...
%             valMap(char(keySet(11))),...
%             valMap(char(keySet(12))),...
%             valMap(char(keySet(13))));
        catch e
            msgbox('Error while executing you script. See matlab console for information');
            rethrow(e);
        end
    end

     function params = getParameters()
        for k = 1 : 13
            params.(char(keySet(k))) = valMap(char(keySet(k)));
        end
     end
end