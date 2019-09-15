classdef roiFeatReaderTool < baseTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        patientsKS;
        isKS;%Image Serie Key Set
        ftKS;%FeaTures Key Set
        ftStrctTab;
        featuresMapsMap;
        legendCellsMap;
    end
    
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj.isKS = {'base', 'mid', 'apex'};
            obj.lgr = logger.getInstance();
            obj.dataPath = opt.patientsFolderPath;
            obj.patientsKS = opt.patientKS;
        end%
        %%
        function obj = run(obj)
            obj = obj.collectFeatures();
            obj.generateMaps();
            obj.generateLegendMaps();
        end%run
        %%getters
        %%
        function isKS = getIsKS(obj)
            isKS = obj.isKS;
        end
        %%
        function featuresMap = getfeaturesMap(obj, isName)
            featuresMap = obj.featuresMapsMap(isName);
        end
        %%
        function legendCells = getLegendCells(obj, isName)
            legendCells = obj.legendCellsMap.(isName);
        end
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = collectFeatures(obj)
            for k = 1 : length(obj.patientsKS)
                ftStruct = xml2struct(fullfile(obj.dataPath, obj.patientsKS{k}, 'roiAnalyzer', 'strg', 'summary.xml'));
                ftStruct.patientName = obj.patientsKS{k};
                try
                    obj.ftStrctTab = [obj.ftStrctTab ftStruct];
                catch
                    obj.ftStrctTab =  ftStruct;
                end
            end
        end
        %% 
        function generateMaps(obj)
            ftMap.apex = zeros(1, 6);
            ftMap.mid = zeros(1, 6);
            ftMap.base = zeros(1, 6);
            for k = 1 : length(obj.ftStrctTab)
                ftStruct = obj.ftStrctTab(k).root;
                for n = 1 : length(obj.isKS)
                    for p = 1 : str2double(ftStruct.(obj.isKS{n}).nbRoi.Text)
                        try
                            ftVect = [str2double(ftStruct.(obj.isKS{n}).roi{p}.peakVal.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi{p}.ttp.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi{p}.auc.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi{p}.maxSlope.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi{p}.maxSlopePos.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi{p}.delay.Text)];
                        catch
                            ftVect = [str2double(ftStruct.(obj.isKS{n}).roi(p).peakVal.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi(p).ttp.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi(p).auc.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi(p).maxSlope.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi(p).maxSlopePos.Text), ...
                                str2double(ftStruct.(obj.isKS{n}).roi(p).delay.Text)];
                        end
                        ftMap.(obj.isKS{n}) = [ftMap.(obj.isKS{n});
                            ftVect];
                    end
                end
            end
            for n = 1 : length(obj.isKS)
                tmp = ftMap.(obj.isKS{n});
                obj.featuresMapsMap = mapInsert(obj.featuresMapsMap, obj.isKS{n}, tmp(2:end, :));
            end
        end
        %% 
        function generateLegendMaps(obj)
            obj.legendCellsMap.apex = {};
            obj.legendCellsMap.mid = {};
            obj.legendCellsMap.base = {};
            for k = 1 : length(obj.ftStrctTab)
                ptName = obj.ftStrctTab(k).patientName;
                ftStruct = obj.ftStrctTab(k).root;
                for n = 1 : length(obj.isKS)
                    for p = 1 : str2double(ftStruct.(obj.isKS{n}).nbRoi.Text)
                        obj.legendCellsMap.(obj.isKS{n}) = ...
                            [obj.legendCellsMap.(obj.isKS{n}) sprintf('%s_%s_roi%.2d', ptName, obj.isKS{n}, p)];
                    end
                end
            end
        end%generateLegendMaps
    end%methods (Access = protected)
end

