classdef myoPCATool < baseTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        patientsKS;
        normRoifeaturesArrayMap;
        lesionRoifeaturesArrayMap;
        normFtOccurMap; %number of normal features occurences by slice
        lesionFtOccurMap; %number of lesion features occurences by slice
        
        lesionPatientIdTabMap; %map storing patients id list owning a lesion roi
        normalPatientIdTabMap;%map storing patients id list owning a lesion roi
        
        isKS;%Image Serie Key Set
        ftKS;%FeaTures Key Set
        
        
        %ACPData
        coeffTabMap;
        coeffOrthTabMap;
        weightTabMap;
        scoreTabMap;
        latentTabMap;
        tSquaredTabMap;
        explainedTabMap;

    end
    
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj.lgr = logger.getInstance();
            obj.dataPath = opt.patientsFolderPath;
            obj.patientsKS = opt.patientKS;
        end%
        %%
        function obj = run(obj)
            obj.collectFeatures();
            obj.processPCAOnImSeries();
        end%run
        %%
        function weightTab = getWeightTab(obj, isName)
            weightTab = obj.weightTabMap(isName);
        end%getCoeffTab
        %%
        function coeffTab = getCoeffTab(obj, isName)
            coeffTab = obj.coeffTabMap(isName);
        end%getCoeffTab
        %%
        function coeffOrthTab = getCoeffOrthTab(obj, isName)
            coeffOrthTab = obj.coeffOrthTabMap(isName);
        end%getCoeffTab
        %%
        function scoreTab = getScoreTab(obj, isName)
            scoreTab = obj.scoreTabMap(isName);
        end%getCoeffTab
        %%
        function latentTab = getLatentTab(obj, isName)
            latentTab = obj.latentTabMap(isName);
        end%getCoeffTab
        %%
        function tSquaredTab = getTSquaredTab(obj, isName)
            tSquaredTab = obj.tSquaredTabMap(isName);
        end%getCoeffTab
        %%
        function explainedTab = getExplainedTab(obj, isName)
            explainedTab = obj.explainedTabMap(isName);
        end%getCoeffTab
        %%
        function isKS = getImSerieKS(obj)
            isKS = obj.isKS;
        end
        %% 
        function featKS = getFeaturesKS(obj)
            featKS = obj.ftKS;
        end
        %%
        function normRoifeaturesArray = getNormRoifeaturesArray(obj, isName)
            normRoifeaturesArray = obj.normRoifeaturesArrayMap(isName);
        end
        %%
        function lesionRoifeaturesArray = getLesionRoifeaturesArray(obj, isName)
            lesionRoifeaturesArray = obj.lesionRoifeaturesArrayMap(isName);
        end%getLesionRoifeaturesArray
        %%
        function [nbLesionFtOccur, nbNormFtOccur] = getFeaturesTypeOccurTab(obj, isName)
            nbLesionFtOccur = obj.lesionFtOccurMap(isName);
            nbNormFtOccur = obj.normFtOccurMap(isName);
        end
        %%
        function patientIdTab = getPatientIdTabMap(obj, isName, regionType)
            switch regionType
                case 'lesion'
                    patientIdTab = obj.lesionPatientIdTabMap(isName);
                case 'normal'
                    patientIdTab = obj.normalPatientIdTabMap(isName);
            end
        end
        
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function collectFeatures(obj)
%             roiAnalzrTool = manualMultiRoiMapDisplayRoiAnalyzerTool();
            roiAnalzrTool = strgRoiAnalyzerTool();
            obj.ftKS = {'roiTicPeakVal', 'roiTicTtp', 'roiTicAuc', 'roiTicMaxSlope', 'roiTicDelay'};
            normFeatArray = [];
            lesionFeatArray = [];
            %init tables that store the Id of the patient whose lesion owes
            lesionPatientIdTab = zeros(1, 3);
            normalPatientIdTab = zeros(1, 3);

            %tables of regions counter by slice
            normCptTab = ones(1, 3);
            lesionCptTab = ones(1, 3);
            
            for k = 1 : length(obj.patientsKS)
                curPatient = obj.patientsKS{k};
                obj.lgr.info(sprintf('patient: %s id: %d', curPatient, k));
                opt.dataPath = fullfile(obj.dataPath, curPatient);
                opt.subfolderPath = fullfile('segmentation', 'ManualMultiRoiMapDisplay');
                opt.maskFileName = 'labelsMask_';
                roiAnalzrTool.prepare(opt);
                if strcmp(class(roiAnalzrTool), 'strgRoiAnalyzerTool')
                    opt.maskType = 'strg';
                    roiAnalzrTool.loadRoisMask_public(opt);
                end
%                 roiAnalzrTool
                roiAnalzrTool.run(opt);
                obj.isKS = roiAnalzrTool.getSeriesKS();
%                 normFeatArray   = nan(length(obj.patientsKS),  length(ftKS), length(isKS));
%                 lesionFeatArray = nan(length(obj.patientsKS), length(ftKS), length(isKS));
                for l = 1 : length(obj.isKS)
                    isName = obj.isKS{l};
                    %get rois id
                    xmlSturct = xml2struct(fullfile(opt.dataPath, 'strg', ['roiInfo_' isName '.xml']));
                    roiInfoCells = xmlSturct.roisInfo;
                    for m = 1 : length(roiInfoCells.roi)
                        if iscell(roiInfoCells.roi)
                            curRoiInfo = roiInfoCells.roi{m};
                        else
                            curRoiInfo = roiInfoCells.roi;
                        end
                        if strncmp('lesion', curRoiInfo.name.Text, length('lesion'))
                            lesionFeatStruct = roiAnalzrTool.getRoiFeatures(obj.ftKS,...
                                            str2double(curRoiInfo.id.Text), isName);
                           lesionPatientIdTab(lesionCptTab(l), l) = k; 
                        elseif strcmp('normal', curRoiInfo.name.Text, length('normal'))
                            normalFeatStruct = roiAnalzrTool.getRoiFeatures(obj.ftKS,...
                                str2double(curRoiInfo.id.Text), isName);
                            normalPatientIdTab(normCptTab(l), l) = k;
                        end
                        
                        
                        for n = 1 : length(obj.ftKS)
                            curfeat = obj.ftKS{n};
                            try
                                normFeatArray(normCptTab(l), n, l) = normalFeatStruct.(curfeat);
                                
                            catch e
                                normFeatArray(normCptTab(l), n, l) = nan;
                            end
                            
                            if ~isempty(lesionFeatStruct.(curfeat))
                                lesionFeatArray(lesionCptTab(l), n, l) = lesionFeatStruct.(curfeat);
                            else
%                                 obj.lgr.err(sprintf('could not load features(patient: %s, imserie: %s)', curPatient, isName));
                                lesionFeatArray(lesionCptTab(l), n, l) = nan;
                            end
                        end%for n = 1
                        normCptTab(l) = normCptTab(l) + 1;
                        lesionCptTab(l) = lesionCptTab(l) + 1;
                    end%for m=1
                end%for l = 1
            end
            
            
            for l = 1 : length(obj.isKS)
                isName = char(obj.isKS(l));
                
%                 lesionPatientIdTab = (1 : length(obj.patientsKS))';
%                 normalPatientIdTab = (1 : length(obj.patientsKS))';
                
                lesionPatientId = lesionPatientIdTab(:, l);
                normalPatientId = normalPatientIdTab(:, l);
                
                isNormFtArray = normFeatArray(:, :, l);
                %remove patient ID with no representative region
%                 normalPatientIdTab( any(isnan(isNormFtArray(:, 1)), 2) ) = [];
                normalPatientId(normalPatientId == 0) = [];
                isNormFtArray(any(isnan(isNormFtArray), 2), :) = [];
                
                isLesionFtTArray = lesionFeatArray(:, :, l);
                %remove patient ID with no representative region
%                 lesionPatientIdTab( any(isnan(isLesionFtTArray(:, 1)), 2) ) = [];
                isLesionFtTArray(any(isnan(isLesionFtTArray), 2), :) = [];
                
                % remove zero padding
                lesionPatientId(lesionPatientId == 0) = [];
                isLesionFtTArray(~any(isLesionFtTArray, 2), :) = [];
                
                obj.normRoifeaturesArrayMap = mapInsert(obj.normRoifeaturesArrayMap, isName, isNormFtArray);
                obj.lesionRoifeaturesArrayMap = mapInsert(obj.lesionRoifeaturesArrayMap, isName, isLesionFtTArray);
                
                obj.lesionPatientIdTabMap = mapInsert(obj.lesionPatientIdTabMap, isName, lesionPatientId);
                obj.normalPatientIdTabMap = mapInsert(obj.normalPatientIdTabMap, isName, normalPatientId);
                
                obj.normFtOccurMap = mapInsert(obj.normFtOccurMap, isName, size(isNormFtArray, 1) );
                obj.lesionFtOccurMap = mapInsert(obj.lesionFtOccurMap, isName, size(isLesionFtTArray, 1));
            end
        end%collectFeatures
        
        %%
        function processPCAOnImSeries(obj)
            for l = 1 : length(obj.isKS)
                isName = char(obj.isKS(l));
                featuresTab = [obj.lesionRoifeaturesArrayMap(isName);
                                obj.normRoifeaturesArrayMap(isName)];
                            
                   
                w = 1 ./ var(featuresTab);
%                  [wcoeff, score, latent, tsquared, explained] = pca(featuresTab, 'VariableWeights', w);
                 [wcoeff, score, latent, tsquared, explained] = pca(featuresTab, 'VariableWeights', 'variance');
%                 [wcoeff, score, latent, tsquared, explained] = pca(featuresTab);
                coeffOrth = inv(diag(std(featuresTab))) * wcoeff;
                
                obj.weightTabMap = mapInsert(obj.weightTabMap, isName, w);
                obj.coeffTabMap = mapInsert(obj.coeffTabMap, isName, wcoeff);
                obj.coeffOrthTabMap = mapInsert(obj.coeffTabMap, isName, coeffOrth);
                obj.scoreTabMap = mapInsert(obj.scoreTabMap, isName, score);
                obj.latentTabMap = mapInsert(obj.latentTabMap, isName, latent);
                obj.tSquaredTabMap = mapInsert(obj.tSquaredTabMap, isName, tsquared);
                obj.explainedTabMap = mapInsert(obj.explainedTabMap, isName, explained);
                
%                 obj.normRoifeaturesArrayMap(isName) = princomp(obj.normRoifeaturesArrayMap(isName));
%                 obj.normRoifeaturesArrayMap(isName);
%                 biplot(coeff);
            end
        end%processPCAOnImSeries
    end%methods (Access = protected)
end

