classdef roiTicFeaturesUI < baseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %UI
        imSerieStructUI;
        %tools
        roiFtRdrTool;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = roiTicFeaturesUI;
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
           
            set(obj.dataPathEditBoxUI, 'enable', 'off');
            set(obj.browsePatientPathBnUI, 'enable', 'off');
            obj.updateSavePath(fullfile('0000_Results', 'roiTicFeatures'));
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
        function goCb(obj, ~, ~)
            clc
%              obj.wipeResults();
            obj.setFooterStr('start running');
            try
                opt.patientsFolderPath = obj.getDataPath();
                opt.patientKS = {'0001_ARGE', '0002_FACL', '0003_CHAL', ...
                    '0004_JUMI', '0005_COJE', '0006_THRO', ...
                    '0007_OUGW', '0009_DEAL', '0012_RIAL', ...
                    '0015_ROJE', '0018_SALI', '0019_GRIR', ...
                    '0021_CUCH', '0022_HODO', '0024_IBOU', ...
                    '0027_CRCH', '0029_HURO', '0030_MARE', ...
                    '0039_MOBE', '0040_SEJO', '0041_LUEL', ...
                    '0042_BELA', '0045_TICH', '0048_BUJA', ...
                    '0049_POAI', '0050_BRFR', '0052_CLYV', ...
                    '1001_BODA', '1002_NEMO', '1003_GAJE'};
                            
%                 opt.patientKS = {'0001_ARGE', '0002_FACL'};
                
                obj.roiFtRdrTool = roiFeatReaderTool();
                obj.roiFtRdrTool.prepare(opt);
                obj.roiFtRdrTool.run();
                obj.dispResults();
            catch e
                obj.setFooterStr('something bad hapenned x_x');
                rethrow(e);
            end
            obj.setFooterStr('running completed');
        end%goCb(obj)
        %%
        function dispResults(obj)
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(2, 2, [.05 .05], [.01 .01], [.01 .01], obj.rPanel);
            end
            isKS = obj.roiFtRdrTool.getIsKS();
            for k = 1 : length(isKS)
                axes(obj.handleAxesTab(k));
                ftMap = obj.roiFtRdrTool.getfeaturesMap(isKS{k});
                ftMap(:, 3) = ftMap(:, 3) ./ 100;
%                 for n = 1 : size(ftMap, 2)
%                     minVal = min(ftMap(:, n));
%                     maxVal = max(ftMap(:, n));
%                     ftMap(:, n) = (ftMap(:, n) - minVal) ./ (maxVal - minVal);
%                 end
                imagesc(ftMap);
                axis image;
                title(isKS{k});
            end
        end%dispResults
        %%
        function saveCb(obj, ~,~)
            try
                isKS = obj.roiFtRdrTool.getIsKS();
                emptyDir(obj.getSavePath());
                for k = 1 : length(isKS)
                    ftMap = obj.roiFtRdrTool.getfeaturesMap(isKS{k});
                    lgdCells = obj.roiFtRdrTool.getLegendCells(isKS{k});
                    txtMatrix = sprintf('\tpeakVal\tttp\tauc\tmaxSlope\tmaxSlopePos\tdelay\n');
                    for n = 1 : size(ftMap, 1)
                        txtMatrix = sprintf('%s%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n', ...
                            txtMatrix, lgdCells{n}, ftMap(n, 1), ftMap(n, 2), ftMap(n, 3) ./ 10, ...
                            ftMap(n, 4), ftMap(n, 5), ftMap(n, 6));
                    end
                    fd = fopen(fullfile(obj.getSavePath(),  ['featuresMatrix_' isKS{k} '.txt']), 'w');
                    try
                        fprintf(fd,'%s', txtMatrix);
                    catch e
                        fclose(fd);
                        rethrow(e);
                    end
                    fclose(fd);
                end
            catch e
                obj.setFooterStr('something bad hapenned x_x');
                rethrow(e);
            end
            obj.setFooterStr('saving completed');
        end%saveCb
    end
    
end

