% aifFit.m
% brief:
% process and returns fit of aif curve
%       from two gaussian and a sigmoidal curve
%       parmeters can be set by the user, and one can use autofit.
%       the more the manual fit is close to the real aif, the more 
%       the more the autofit accurate. At the end The user has the last
%       word. Then, if he manually tuned parameters, the returned function
%       will be the manual fit. otherwise, it will be the auto fitted.
% references:
%
%
% input:
% arg1: ...
% arg2: ...
% output:
%
% aifFit:  fitted AIF
% params: parameter values
%
%
% author: C.Daviller
% date: 08-Mar-2017


function [aifFit, params] = aifFit(aif, tAcq)

if ~nargin
    aif = loadmat('D:\02_Matlab\Data\deconvTool\patientDataPrep\Arbane\stress\Aif\aifCtc.mat');
    aif = aif(4:end);
    tAcq = getDicomSerieAcquisitionTime('D:\02_Matlab\Data\referenceSet\aif');
    tAcq = (tAcq(4:end) - tAcq(4)) * 1e-3;
    tAcq = tAcq(1:length(aif));
end


fm = figureMgr.getInstance();
fm.closeFig('aifFitUI');
figHdle = fm.newFig('aifFitUI');
fm.resize('aifFitUI', 2, 2)

A1ini = max(aif); pkPos = find(aif == max(aif(:)), 1, 'first');

initUI(A1ini, tAcq(pkPos));

waitfor(figHdle);





%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inner functions

    function initUI(A1ini, T1ini)
                %A1
        Pini = [A1ini, T1ini, 2.6,... % A1, T1, sigma1
                    A1ini / 8, T1ini * 2.5, 5, ... % A2, T2, sigma2
                    A1ini / 10, 200e-6, T1ini * 3.5, 1];% ...% A3, beta, T3, sigma3
%                      A1ini / 10, T1ini * 2.5, 0.1]; % A4, T4, w4
        % sliders only accept interger values. set values as integers 
        % and the real value will be managed by the factor map
        Pini = Pini .* [ 1e3, 1e3, 1e1,...
                            1e3, 1e1, 1e1,...
                            1e4, 1e6, 1e2, 1e1];
        Pmin = Pini * 0.1; Pmax = Pini * 2.5; 
        keySet     =  {  'A1',    'T1',  'sigma1',   'A2',     'T2',    'sigma2',    'A3',    'beta',   'T3',    'sigma3'}; % append set name here
        initValSet =  { Pini(1), Pini(2), Pini(3),  Pini(4),  Pini(5),   Pini(6),   Pini(7),  Pini(8),  Pini(9),  Pini(10)}; %append new param init value
        minValSet  =  { Pmin(1), Pmin(2), Pmin(3),  Pmin(4),  Pmin(5),   Pmin(6),   Pmin(7),  Pmin(8),  Pmin(9),  Pmin(10)}; %append new param min value
        maxValSet  =  { Pmax(1), Pmax(2), Pmax(3),  Pmax(4),  Pmax(5),   Pmax(6),   Pmax(7),  Pmax(8),  Pmax(9),  Pmax(10)}; %append new param max value
        factorSet  =  { 1e-3,    1e-3,     1e-1,        1e-3,     1e-1,     1e-1,      1e-4,     1e-6,     1e-2,      1e-1};%append new factor value (1 if no need to factor)
        
        
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
        
        % buttons
        uicontrol('Style', 'pushbutton',...
            'Position', [10 30 120 50],...
            'String', 'Fit',...
            'Callback', @fitCb);
        
        uicontrol('Style', 'pushbutton',...
            'Position', [130 30 120 50],...
            'String', 'Reset',...
            'Callback', @resetCb);
        
        uicontrol('Style', 'pushbutton',...
            'Position', [260 30 120 50],...
            'String', 'OK',...
            'Callback', @saveNquitCb);
        
        function sldrCb(source, ~, arg2)
            val  =  floor(get(source, 'Value'))  * factorMap(char(arg2));
            %str = char(cell(floor(get(source, 'Value'))));
            %nbPE  = str2num(str);
            valMap(char(arg2)) = val;
            set(editBoxMap(char(arg2)), 'String', val);
            dispCurves(prefitCb());
        end
        
        function eboxCb(source, ~, arg2)
            val  =  str2num(get(source, 'String'));
            %str = char(cell(floor(get(source, 'Value'))));
            %nbPE  = str2num(str);
            valMap(char(arg2)) = val;
            set(sldrMap(char(arg2)), 'Value', valMap(char(arg2)) / factorMap(char(arg2)));
            dispCurves(prefitCb());
        end
        
        F = @(p, tSimu)p(1) .* exp(-(tSimu - p(2)).^2 / (2 * p(3)^2)) + ...
                           p(4) .* exp(-(tSimu - p(5)).^2 / (2 * p(6)^2)) + ...
                            p(7) .* exp(-p(8).*(tSimu - p(9)))./ (1 + exp(-p(10) .* (tSimu - p(9))));
                        
        function aifPrefit = prefitCb()
            p0 = [valMap(char(keySet(1))),...
                valMap(char(keySet(2))),...
                valMap(char(keySet(3))),...
                valMap(char(keySet(4))),...
                valMap(char(keySet(5))),...
                valMap(char(keySet(6))),...
                valMap(char(keySet(7))),...
                valMap(char(keySet(8))),...
                valMap(char(keySet(9))),...
                valMap(char(keySet(10)))];
            aifPrefit = F(p0, tAcq);
           % aifPrefit(pkPos) = A1ini;
        end
        
        function fitCb(~, ~)
            p0 = [valMap(char(keySet(1))),...
                valMap(char(keySet(2))),...
                valMap(char(keySet(3))),...
                valMap(char(keySet(4))),...
                valMap(char(keySet(5))),...
                valMap(char(keySet(6))),...
                valMap(char(keySet(7))),...
                valMap(char(keySet(8))),...
                valMap(char(keySet(9))),...
                valMap(char(keySet(10)))];
            
            [popt, resnorm,~,exitflag, output] = lsqcurvefit(F, p0, tAcq, aif);
            aifFit = F(popt, tAcq);
            %aifFit(pkPos) = A1ini;
            updateControls(popt);
            dispCurves(prefitCb());
        end
        
        function resetCb(~,~)
            for k = 1 : valMap.length
                valMap(char(keySet(k))) = Pini(k) * factorMap(char(keySet(k)));
                set(editBoxMap(char(keySet(k))), 'String', Pini(k));
                set(sldrMap(char(keySet(k))), 'Value', valMap(char(keySet(k))) / factorMap(char(keySet(k))) );
            end
            dispCurves(prefitCb());
        end
        
        function updateControls(p)
            for k = 1 : valMap.length;
                valMap(char(keySet(k))) = p(k);
                set(sldrMap(char(keySet(k))), 'Value', p(k) / factorMap(char(keySet(k))));
                set(editBoxMap(char(keySet(k))), 'String', p(k));
            end
        end
        function dispCurves(aifPrefit)
            
            subplot(1,2,2); hold off; 
            plot(tAcq, aif,'*'); hold all; 
            plot(tAcq, aifPrefit);
            plot(tAcq, aifFit);
            legend('aif', 'aifPrefit', 'aif fit');
        end
        function saveNquitCb(~,~)
            aifFit = prefitCb();
            for k = 1 : length(keySet)
                params.(char(keySet(k))) = valMap(char(keySet(k)));
            end
            fm.closeFig('aifFitUI');
        end
        
        aifFit = prefitCb();
        dispCurves(aifFit);
        
        
        
    end % initUI
    

end