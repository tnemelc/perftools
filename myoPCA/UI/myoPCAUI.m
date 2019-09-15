classdef myoPCAUI < baseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %UI
        imSerieStructUI;
        pcaDimNbStructUI;
        resultsSubPanelsTab;
        handleFeatSignatureAxesTab;
        %tools
        pcaTool;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = myoPCAUI;
            end
            obj = localObj;
        end
    end%methods (Static)  
    %% public methods
    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.initDataPathUI(fullfile(obj.basePath, 'patientData', '02_CHUSE', 'clustering'));
            obj = obj.initVisibleImSerieUI();
            obj = obj.initPcaDimNbUI();
            set(obj.dataPathEditBoxUI, 'enable', 'off');
            set(obj.browsePatientPathBnUI, 'enable', 'off');
        end%initialize
        %% getters
        %% 
        function isName = getVisibleImSerie(obj)
            isList = get(obj.imSerieStructUI.popupUI, 'String');
            isName = char(isList(get(obj.imSerieStructUI.popupUI, 'Value')));
        end%getVisibleImSerie
        %%
        function nbPcaDims = getNbPcaDims(obj)
            isList = get(obj.pcaDimNbStructUI.popupUI, 'String');
            nbPcaDims = str2num(char(isList(get(obj.pcaDimNbStructUI.popupUI, 'Value'))));
        end%getVisibleImSerie
        
    end%methods (Access = public)
    
    %%
    methods (Access = protected)
        %% 
        function obj = initVisibleImSerieUI(obj)
            obj.imSerieStructUI.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(10) 0.1 0.05],...
                'String', sprintf('current Image Serie'));
            
            obj.imSerieStructUI.popupUI = ...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(10) 0.4 obj.HdleHeight],...
                'String', {'all', 'base', 'mid', 'apex'}, ...
                'Callback', @obj.onVisibleImSerieCb);
        end%initVisibleImSerieUI
        
        %% 
        function obj = initPcaDimNbUI(obj)
            obj.pcaDimNbStructUI.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(8) 0.1 0.05],...
                'String', sprintf('PCA dimensions nb'));
            
            obj.pcaDimNbStructUI.popupUI = ...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(8) 0.4 obj.HdleHeight],...
                'String', {'2', '3'}, ...
                'Callback', @obj.onPcaDimNbCb);
        end%initVisibleImSerieUI
        
        %%
        function goCb(obj, ~, ~)
            clc
%              obj.wipeResults();
            obj.setFooterStr('start running');
            try
                opt.patientsFolderPath = obj.getDataPath();
                opt.patientKS = {'0001_ARGE', '1001_BODA',  '0003_CHAL', ...
                                '0005_COJE', '0009_DEAL',  '0002_FACL',...
                                '0004_JUMI', '0007_OUGW',  '0012_RIAL',...
                                '0018_SALI', '0006_THRO'};
%                 opt.patientKS = {'0002_FACL'}, '1001_BODA',  '0003_CHAL'};
%                 opt.patientKS = {'0002_FACL'};
                opt.patientKS =  {
                    '0001_ARGE', '0002_FACL', '0003_CHAL', ...
                    '0004_JUMI', '0005_COJE', '0006_THRO', ...
                    '0007_OUGW', '0009_DEAL', '0012_RIAL', ...
                    '0015_ROJE', '0018_SALI', '0019_GRIR', ...
                    '0021_CUCH', '0022_HODO', '0024_IBOU', ...
                    '0027_CRCH', '0029_HURO', '0030_MARE', ...
                    '0039_MOBE', '0040_SEJO', '0041_LUEL', ...
                    '0042_BELA', '0045_TICH', '0048_BUJA', ...
                    '0049_POAI', '0050_BRFR', '0052_CLYV', ...
                    '1001_BODA', '1002_NEMO', '1003_GAJE', ...
                    '1004_GEMI'};
                
                obj.pcaTool = myoPCATool();
                obj.pcaTool.prepare(opt);
                obj.pcaTool.run();
                obj.dispResults();
            catch e
                obj.setFooterStr('something bad hapenned x_x');
                rethrow(e);
            end
            obj.setFooterStr('running completed');
        end%goCb(obj)
        %%
        function dispResults(obj)
            
            isKS = obj.pcaTool.getImSerieKS();
            tgroup = uitabgroup('Parent', obj.rPanel);
            obj.resultsSubPanelsTab(1) = uitab('Parent', tgroup, 'Title', 'PCA');
            obj.resultsSubPanelsTab(2) = uitab('Parent', tgroup, 'Title', 'box plot');
            obj.resultsSubPanelsTab(3) = uitab('Parent', tgroup, 'Title', 'Pareto');
            obj.resultsSubPanelsTab(4) = uitab('Parent', tgroup, 'Title', 'Feat Signature');
            
            
            %PCA plot
            obj.dispResultsPCA();
            %features signature
            obj.dispResultsFtSignature();
            
            
            featuresKS = obj.pcaTool.getFeaturesKS();
            handleAxesTabPanel2 = tight_subplot(3, 1, [.1 .1], [.05 .05], [.1 .01], obj.resultsSubPanelsTab(2));
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                axes(handleAxesTabPanel2(k));
                normRoifeaturesArray = obj.pcaTool.getNormRoifeaturesArray(isName);
                boxplot(normRoifeaturesArray, 'Orientation', 'horizontal', 'Labels', featuresKS);
                title(isName);
            end
            
            handleAxesTabPanel3 = tight_subplot(3, 1, [.1 .1], [.05 .05], [.1 .01], obj.resultsSubPanelsTab(3));
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                
                %h = subplot(3, 1, k);
                explainedTab = obj.pcaTool.getExplainedTab(isName);
                obj.pareto(handleAxesTabPanel3(k), explainedTab);
                hold on; plot(0 : length(explainedTab) + 1, 95 * ones(1, length(explainedTab) + 2), 'linestyle', '--', 'color', [.7 0 0]);
                title(isName);
            end
            
        end%dispResults
        %%
        function dispResultsPCA(obj)
            switch obj.getVisibleImSerie()
                case 'all'
                    obj.handleAxesTab = tight_subplot(2, 2, [.1 .05], [.05 .05], [.01 .01], obj.resultsSubPanelsTab(1));
                    isKS = obj.pcaTool.getImSerieKS();
                    %unsed axis
                    set(obj.handleAxesTab(4), 'visible', 'off')
                otherwise
                    obj.handleAxesTab = tight_subplot(1, 1, [.1 .05], [.05 .05], [.01 .01], obj.resultsSubPanelsTab(1));
                    isKS = {obj.getVisibleImSerie()};
            end%switch
            featuresKS = obj.pcaTool.getFeaturesKS();
            nbPcaDims = obj.getNbPcaDims();
            for k = 1 : length(isKS)
                isName = isKS{k};
                [nbLesionFtOccur, ~] = obj.pcaTool.getFeaturesTypeOccurTab(isName);
                lesionPatientIdTab = obj.pcaTool.getPatientIdTabMap(isName, 'lesion');
                normalPatientIdTab = obj.pcaTool.getPatientIdTabMap(isName, 'normal');
                
                coeffOrthTab = obj.pcaTool.getCoeffOrthTab(isName);
                scoreTab = obj.pcaTool.getScoreTab(isName);
                
                axes(obj.handleAxesTab(k));
                [~, scaledScores] = biplot(coeffOrthTab(:, 1 : nbPcaDims ),...
                                        'Scores', scoreTab(:, 1 : nbPcaDims),...
                                        'Varlabels', featuresKS);
                hold on;
                circle(0, 0, 1, [1, 0.5, 0]);
                xlim([-1.1 1.1]); ylim([-1.1 1.1]);
                set(gca,'DataAspectRatio', [1, 1, 1])
                set(gca,'xticklabel', [])
                set(gca,'yticklabel', [])
                
                % vectors that contain indexes of patients 
                % with dense or diffuse lesions
                 densePatientVect = [1, 2, 4, 6, 7, 8, 9, 11, 12, 13, 15, 16, 18, 19, 23, 25, 26, 27, 28, 29, 30, 31];
                 diffusePatientVect = [3, 10, 14, 17, 20, 21, 22, 24];
                 densePatientPosVect = ismember(lesionPatientIdTab, densePatientVect);
                 diffusePatientPosVect = ismember(lesionPatientIdTab, diffusePatientVect);
                 
                switch obj.getNbPcaDims()
                    case 2
                        %plot(scaledScores(1 : nbLesionFtOccur, 1), scaledScores(1 : nbLesionFtOccur, 2), 'or');
                        plot(scaledScores(densePatientPosVect == 1, 1), scaledScores(densePatientPosVect == 1, 2), 'color', [0 .749 .749], 'linestyle', 'o');
                        plot(scaledScores(densePatientPosVect == 1, 1), scaledScores(densePatientPosVect == 1, 2), 'color', [0 .749 .749], 'linestyle', '+');
                        plot(scaledScores(diffusePatientPosVect == 1, 1), scaledScores(diffusePatientPosVect == 1, 2), 'om');
                        plot(scaledScores(diffusePatientPosVect == 1, 1), scaledScores(diffusePatientPosVect == 1, 2), '+m');
                        
                        %text(scaledScores(1 : nbLesionFtOccur, 1), scaledScores(1 : nbLesionFtOccur, 2), num2str(lesionPatientIdTab));
%                         text(scaledScores(:, 1), scaledScores(:, 2), num2str(lesionPatientIdTab));
%                         text(scaledScores(diffusePatientVect, 1), scaledScores(diffusePatientVect, 2), num2str(lesionPatientIdTab(diffusePatientVect)));
                        
                        %plot normal types
%                         plot(scaledScores(nbLesionFtOccur + 1 : end, 1), scaledScores(nbLesionFtOccur + 1 : end, 2), 'linestyle', '+', 'color', [0 .5 0]);
%                         text(scaledScores(nbLesionFtOccur + 1 : end, 1), scaledScores(nbLesionFtOccur + 1 : end, 2), num2str(normalPatientIdTab));
                    case 3
%                         plot3(scaledScores(1 : nbLesionFtOccur, 1), ...
%                                 scaledScores(1 : nbLesionFtOccur, 2), ...
%                                 scaledScores(1 : nbLesionFtOccur, 3), 'or');
                        plot3(scaledScores(densePatientVect, 1), ...
                            scaledScores(densePatientVect, 2), ...
                            scaledScores(densePatientVect, 3), 'color', [0 .749 .749], 'linestyle', 'o');
                        
                       plot3(scaledScores(diffusePatientVect, 1), ...
                            scaledScores(diffusePatientVect, 2), ...
                            scaledScores(diffusePatientVect, 3), 'om'); 
                        
                        text(scaledScores(densePatientVect, 1), ...
                            scaledScores(densePatientVect, 2), ...
                            scaledScores(densePatientVect, 3), ...
                            num2str(lesionPatientIdTab(densePatientVect)));
                        
                        text(scaledScores(diffusePatientVect, 1), ...
                            scaledScores(diffusePatientVect, 2), ...
                            scaledScores(diffusePatientVect, 3), ...
                            num2str(lesionPatientIdTab(diffusePatientVect)));
                        
                        %plot normal types
                        plot3(scaledScores(nbLesionFtOccur + 1 : end, 1),...
                                scaledScores(nbLesionFtOccur + 1 : end, 2),...
                                scaledScores(nbLesionFtOccur + 1 : end, 3), '+g');
                end
                
                explainedTab = obj.pcaTool.getExplainedTab(isName);
                xlabel(sprintf('Comp 1 (%0.02f%%)', explainedTab(1)), 'fontsize', 12, 'fontweight', 'bold');
                ylabel(sprintf('Comp 2 (%0.02f%%)', explainedTab(2)), 'fontsize', 12, 'fontweight', 'bold');
                zlabel(sprintf('Comp 3 (%0.02f%%)', explainedTab(3)), 'fontsize', 12, 'fontweight', 'bold');
                
                title(isName);
            end
            
        end%dispResultsPCA
        
        %%
        function dispResultsFtSignature(obj)
            switch obj.getVisibleImSerie()
                case 'all'
                    obj.handleFeatSignatureAxesTab = tight_subplot(3, 1, [.1 .1], [.05 .05], [.05 .1], obj.resultsSubPanelsTab(4));
                    isKS = obj.pcaTool.getImSerieKS();
                otherwise
                    obj.handleFeatSignatureAxesTab = tight_subplot(1, 1, [.1 .1], [.05 .05], [.05 .1], obj.resultsSubPanelsTab(4));
                    isKS = {obj.getVisibleImSerie()};
            end%switch
            featSet = obj.pcaTool.getFeaturesKS();
            
            for k = 1 : length(isKS)
                axes(obj.handleFeatSignatureAxesTab(k)); hold on; 
                normalRoiFeaturesArray = obj.pcaTool.getNormRoifeaturesArray(isKS{k});
                lesionRoiFeaturesArray = obj.pcaTool.getLesionRoifeaturesArray(isKS{k});
                %concatenate features in a single array
                allRoisFeaturesArray = [normalRoiFeaturesArray; lesionRoiFeaturesArray]; 
                %normalize them
                allRoisFeaturesArray = obj.normalizeRoiFeaturesArray(allRoisFeaturesArray')';
                
                %re-split the arrays 
                normalRoiFeaturesArray = allRoisFeaturesArray(1 : size(normalRoiFeaturesArray, 1), :);
                lesionRoiFeaturesArray = allRoisFeaturesArray(size(normalRoiFeaturesArray, 1) + 1 : end, :);
                
                plot(normalRoiFeaturesArray', '*', 'color', [0 .5 0]);
                plot(lesionRoiFeaturesArray', '*', 'color', [.8 0 0]);
                set(gca, 'xtick', 1 : length(featSet), 'xticklabel', featSet, 'fontsize', 10);
                set(gca, 'ytick', 0 : 0.2 : 1.2, 'yticklabel', 0 : 0.2 : 1.2);
                xlim([0 (length(featSet) + 1)]);
                ylim([0 1.2]);
                title(isKS{k});
                grid;
            end
        end%dispResultsFtSignature
        
        function ftArray = normalizeRoiFeaturesArray(obj, ftArray)
            for k = 1 : size(ftArray, 1)
                maxVal = max(ftArray(k, :));
                minVal = 0;%min(ftArray(k, :));
                for m = 1 : size(ftArray, 2)
                    ftArray(k, m) = (ftArray(k, m) - minVal) / (maxVal - minVal);
                end
            end
        end%normalizeRoiFeaturesArray
        
        %%
        function pareto(obj, ax, explainedTab)
            axes(ax);
            bar(explainedTab);
            hold on; plot(cumsum(explainedTab));
        end
        %%
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = obj.onKeyPressCb@baseUI([], arg);
            if ~validKey
                switch arg.Character
                    case '2'
                        obj.setFooterStr('2 dimensions display');
                        obj.nbDimsDisplay = 2;
                        obj.dispResults();
                    case '3'
                        obj.setFooterStr('3 dimensions display');
                        obj.nbDimsDisplay = 3;
                        obj.dispResults();
                    otherwise
                        validKey = false;
                end%switch
            end
        end%onKeyPressCb
        %%
        function saveCb(obj, ~,~)
        end
        %%
        function onVisibleImSerieCb(obj, ~, ~)
            % clear panel1
            delete(get(obj.resultsSubPanelsTab(1), 'Children'));
            delete(get(obj.resultsSubPanelsTab(4), 'Children'));
            %display
            obj.dispResultsPCA();
            obj.dispResultsFtSignature();
        end
        %%
        function onPcaDimNbCb(obj, ~, ~)
            msgbox('Analysis must be restarted. Press Go! button.');
        end
    end
    
end

