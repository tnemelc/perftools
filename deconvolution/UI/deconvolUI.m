classdef deconvolUI < maskOverlayBaseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
%% private properties
    properties (Access = private)
        image;
        methodChUI;
        aifPathUI;
        phantomPathUI;
        deconvTool; % data processor object
        patientDeconvTooTab;
        slcList;
        deconvModeUI;% checkbox for selection type of data (phantom or patient)
        roiDisplayModeUI;% checkbox for selection of results display
        sldrTimeAcqUI;% slider for time portion to use for deconvolution
        eBoxTimeAcqUI; % slider value
        summaryUI;% proccessing summary
        chbxProcessMeasUncertaintyUI;% check box that specifies if mesurement uncertainty is required
        
        mbfBAResults;% mbf Bland Altman results
        mbvBAResults;% mbv Bland Altman results
    end
%% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = deconvolUI;
            end
            obj = localObj;
        end
    end
%% public methods
    methods (Access = public)
        function setdefaultImage(obj)
            delete(get(obj.rPanel,'Children'));
            P = phantom('Modified Shepp-Logan',200);
            subplot(1, 2, 2);
            imshow(P);
        end
        
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.setAifPathUI();
            obj = obj.initPhantomPathUI();
            obj = obj.setMethodChoiceUI();
            obj = obj.setSldrTAcqUI();
%             obj = obj.initSavePathUI();
            obj.updateSavePath(fullfile(obj.basePath, 'phantom\1_Myocarde\deconvolution\', obj.getMethod()));
            obj = obj.setdeconvModeUI();
            obj = obj.setRoiDisplayModeUI();
            obj = obj.setChbxProcessMeasUncertaintyUI();
        end
        
        %getters
        function aifPath = getAifPath(obj)
            aifPath = get(obj.aifPathUI, 'String');
        end
        
        function phantomPath = getPhantomPath(obj)
            phantomPath = get(obj.phantomPathUI, 'String');
        end
        
        function method = getMethod(obj)
             methodList = get(obj.methodChUI, 'String');
             methodVal = get(obj.methodChUI, 'Value');
             method = char(methodList(methodVal));
        end%getMethod
        
        function savePath = getSavePath(obj)
            savePath = get(obj.savePathUI, 'String');
        end%getSavePath
        
        function timePortion = getTimePortion(obj)
            timePortion = get(obj.sldrTimeAcqUI, 'Value') / 100;
        end
        
        function deconvMode = getDeconvMode(obj)
            deconvMode = get(obj.deconvModeUI, 'Value');
            % true => patient
            % false => phantom
        end%getDeconvMode
        
        function displayMode = getDisplayMode(obj)
            val  = get(obj.roiDisplayModeUI, 'Value');
            list  = get(obj.roiDisplayModeUI, 'String');
            displayMode = char(list(val));
        end%getDisplayMode
        
        function processMeasUncertainty = getProcessMeasUncertainty(obj)
            processMeasUncertainty  = get(obj.chbxProcessMeasUncertaintyUI, 'value');
        end%getProcessMeasUncertainty
    end
    
    
%% protected methods
    methods (Access = protected)
        function obj = goCb(obj, src, ~)
            figureMgr.getInstance().closeAllBut('deconvTool');
            delete(get(obj.rPanel,'Children'));
            obj.setProcessingDisplay();
            obj.setFooterStr('initialize');
            if ~obj.getDeconvMode()
                switch getMethod(obj)
                    case 'Fermi'
                        obj.deconvTool = deconvToolFermi();
                    case 'Bayesian'
                        obj.deconvTool = deconvToolBayesian();
                    case 'BayesianParallel'
                        obj.deconvTool = deconvToolBayesianParallel();
                    case 'FtKpsVpVe'
                        obj.deconvTool = deconvToolFtKpsVpVe();
                    case 'SpatioTemp'
                        obj.deconvTool = deconvToolSpatioTemp();
                    case 'Bayesian>>Fermi'
                        obj.deconvTool = deconvToolBayesianFermi();
                    case 'Bayesian>>FtKpsVpVe'
                        obj.deconvTool = deconvToolBayesianFtKpsVpVe();
                    case 'oSVD'
                        msgbox('TBD');
                    case 'Rdm'
                        obj.deconvTool = deconvToolRandom();
                end
                obj.setFooterStr('running');
                try
                    obj.runDeconvPhantom();
                catch e
                    obj.setFooterStr('x_x something bad happened (see console)');
                    rethrow(e);
                end
            else
                switch getMethod(obj)
                    case 'Fermi'
                        obj.patientDeconvTooTab = [deconvToolFermi(),...
                                                    deconvToolFermi(),...
                                                    deconvToolFermi()];
                    case 'Bayesian'
                        obj.patientDeconvTooTab = [deconvToolBayesian(),...
                                                    deconvToolBayesian(),...
                                                    deconvToolBayesian()];
                    case 'BayesianParallel'
                        obj.patientDeconvTooTab = [deconvToolBayesianParallel(), ...
                                                     deconvToolBayesianParallel(),...
                                                     deconvToolBayesianParallel()];
                    case 'FtKpsVpVe'
                        obj.patientDeconvTooTab = [deconvToolFtKpsVpVe(), ...
                                                    deconvToolFtKpsVpVe(), ...
                                                    deconvToolFtKpsVpVe()];
                    case 'SpatioTemp'
                        obj.patientDeconvTooTab = [deconvToolSpatioTemp(), ...
                                                    deconvToolSpatioTemp(),...
                                                    deconvToolSpatioTemp()];
                    case 'Bayesian>>Fermi'
                        obj.patientDeconvTooTab = [deconvToolBayesianFermi(), ...
                                                    deconvToolFtKpsVpVe(), ...
                                                    deconvToolFtKpsVpVe()];
                    case 'Bayesian>>FtKpsVpVe'
                        obj.patientDeconvTooTab = [deconvToolBayesianFtKpsVpVe(), ...
                                                    deconvToolBayesianFtKpsVpVe(),...
                                                    deconvToolBayesianFtKpsVpVe()];
                    case 'oSVD'
                        msgbox('TBD');
                    case 'Rdm'
                        obj.patientDeconvTooTab = [deconvToolRandom(),...
                                                    deconvToolRandom(),...
                                                    deconvToolRandom()];
                end
                try 
                    obj.runDeconvPatient();
                catch e
                    obj.setFooterStr('x_x something bad happened (see console)');
                    rethrow(e);
                end
            end
            obj.setFooterStr('displaying results');
            obj.dispResults();
            obj.setFooterStr('running terminated succesfully.');
        end %goCb
        
        function obj = runDeconvPhantom(obj)
            options = loadmat([obj.getPhantomPath() '\generationOptions.mat']);
            options.timePortion = obj.getTimePortion();
            options.deconvMode = 'phantom';
            options.processMeasUncertainty = obj.getProcessMeasUncertainty();
            options.aifDataPath = obj.getAifPath();
            options.slicePath = obj.getPhantomPath();
            curveSet = loadmat([obj.getPhantomPath() '\noisedCtc.mat']);
            
            [H, W, ~] = size(curveSet);
            obj.deconvTool.prepare(options);
%             loadmat(), ...
%                                     curveSet,...
%                                     loadmat([obj.getPhantomPath() '\tAcq.mat']),...
%                                     options, ...
%                                     ones(H, W), 0);
            obj.deconvTool.runDeconvolution();
            obj.deconvTool.runRoiDeconvolution();
            obj.deconvTool.processSigmaMaps();
        end%runDeconvPhantom
        
        function obj = runDeconvPatient(obj)
            %options = loadmat([obj.getPhantomPath() '\generationOptions.mat']);
            options.timePortion = obj.getTimePortion();
            options.deconvMode = 'patient';
            options.patchWidth = 1;
            options.processMeasUncertainty = obj.getProcessMeasUncertainty();
            options.aifDataPath = obj.getAifPath();
            options.dataPath = obj.getPhantomPath();
            obj.slcList = {}; cpt = 1; 
            %create slices list
            if isdir(fullfile(obj.getPhantomPath(), 'dataPrep\base')); obj.slcList(cpt) = {'base'}; cpt = cpt + 1; end
            if isdir(fullfile(obj.getPhantomPath(), 'dataPrep\mid')); obj.slcList(cpt) = {'mid'}; cpt = cpt + 1; end
            if isdir(fullfile(obj.getPhantomPath(), 'dataPrep\apex')); obj.slcList(cpt) = {'apex'}; cpt = cpt + 1; end               

            % load slices data
            for k = 1 : length(obj.slcList)
                %aif = loadmat(obj.getAifPath());
                options.slicePath = fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)));
                %tAcq = loadmat(fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'tAcq.mat'));
                %ctcSet = loadmat(fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'ctcSet.mat'));
                %mask = loadmat(fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'mask.mat'));
%                 disp('runDeconvPatient: trying to load ROI mask...');
%                 try 
%                     roiMask = loadmat(fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'labeledImg.mat'));
%                     disp('runDeconvPatient: ROI mask loaded');
%                 catch
%                     % no further roi, just calculate the mean myocardium ctc roi
%                     disp('runDeconvPatient: no ROI mask. will load mask.mat instead');
%                     roiMask = loadmat(fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'mask.mat'));
%                 end
                
                cprintf('green', 'deconvolUI::runDeconvPatient: runDeconvPatient: prepare for slice: %s \n', char(obj.slcList(k)));
                obj.patientDeconvTooTab(k).prepare(options);
%                 aif, ...
%                     ctcSet(:, :, 1 : end),...
%                     tAcq(1:end) - tAcq(1),...
%                     options, ...
%                     mask, ...
%                     roiMask);
%                 obj.patientDeconvTooTab(k) = ...
                cprintf('green', 'deconvolUI::runDeconvPatient: run for slice: %s\n', char(obj.slcList(k)));
                obj.patientDeconvTooTab(k).runDeconvolution();
                obj.patientDeconvTooTab(k).runRoiDeconvolution();
            end
        end%runDeconvPatient
        
        function obj = saveCb(obj, src, ~)
            try
            if ~obj.getDeconvMode()% phantom
                obj.savePhantomResults(obj.getSavePath());
            else
                obj.savePatientResults(obj.getSavePath());
            end
            catch e
                obj.setFooterStr('deconvolUI::saveCb: x_x something bad happened (see console).');
                rethrow(e);
            end
            obj.setFooterStr('save finished succesfully');
        end%saveCb
        
        function obj = savePhantomResults(obj, savePath)
            obj.save_createSaveDir(savePath);
            %raw data
            savemat(fullfile(savePath, 'mbfMap'), obj.deconvTool.getMbfMap());
            savemat(fullfile(savePath, 'mbvMap'), obj.deconvTool.getMbvMap());
            savemat(fullfile(savePath, 'delayMap'), obj.deconvTool.getDelayMap());
            savemat(fullfile(savePath, 'ctcSet'), obj.deconvTool.getCtcSet());
            savemat(fullfile(savePath, 'fitCtcSet'), obj.deconvTool.getFitCtcSet());
            savemat(fullfile(savePath, 'mbfSigmaMap'), obj.deconvTool.getMbfSigmaMap());
            savemat(fullfile(savePath, 'mbvSigmaMap'), obj.deconvTool.getMbvSigmaMap());
            %savemat([savePath 'mbfMeasUncertaintyMap'], obj.deconvTool.getMbfUncertaintyMap());
            %figures
            figureMgr.getInstance().saveAll(savePath);
            
            % processing summuray
            root.timeProcessing = obj.deconvTool.getProcessingTime();
            root.timeAcquisitionPortion = obj.getTimePortion();
            root.PhantomPath = obj.getPhantomPath();
            root.Method = strrep(obj.getMethod(), '>>', '_');
            root.aifPath = getAifPath(obj);
            root.mbfBlandAltmanRes = obj.mbfBAResults;
            root.mbvBlandAltmanRes = obj.mbvBAResults;
            
            if strcmp('SpatioTemp', obj.getMethod())
                root.parameters.lambda_s = obj.deconvTool.getLambdaS();
                root.parameters.lambda_t = obj.deconvTool.getLambdaT();
                root.parameters.delta = obj.deconvTool.getDelta();
            end
            struct2xml(struct('summary', root), fullfile(savePath, 'summary.xml'));
        end%savePhantomResults
        
        function obj = savePatientResults(obj, savePath)
            % processing summuray
                [~, root.patientName] = fileparts(obj.getPhantomPath());
                root.Method = strrep(obj.getMethod(), '>>', '_');
                
                savePath = obj.getSavePath();
                root.timeAcquisitionPortion = obj.getTimePortion();
                root.initDataPath = obj.getPhantomPath();
                root.aifPath = getAifPath(obj);
                
                obj.save_createSaveDir(savePath);
            for k = 1 : length(obj.slcList)
                saveCurSlcPath = fullfile(savePath, char(obj.slcList(k)));
                if ~isdir(saveCurSlcPath); mkdir(saveCurSlcPath); end
                
                savemat(fullfile(saveCurSlcPath, 'mbfMap'), obj.patientDeconvTooTab(k).getMbfMap('pixels', [], 'ml/min/g'));
                savemat(fullfile(saveCurSlcPath, 'mbvMap'), obj.patientDeconvTooTab(k).getMbvMap());
                savemat(fullfile(saveCurSlcPath, 'delayMap'), obj.patientDeconvTooTab(k).getDelayMap());
                
                savemat(fullfile(saveCurSlcPath, 'mbfUncertaintyMap'), obj.patientDeconvTooTab(k).getMbfUncertaintyMap('ml/min/g'));
                
                savemat(fullfile(saveCurSlcPath, 'ctcSet'), obj.patientDeconvTooTab(k).getCtcSet());
                savemat(fullfile(saveCurSlcPath, 'fitCtcSet'), obj.patientDeconvTooTab(k).getFitCtcSet());
                savemat(fullfile(saveCurSlcPath, 'ttpMap'), obj.patientDeconvTooTab(k).getTimeToPeakMap());
                
                savemat(fullfile(saveCurSlcPath, 'mbfRoiMapSet'), obj.patientDeconvTooTab(k).getMbfRoiMapSet());
                savemat(fullfile(saveCurSlcPath, 'mbvRoiMapSet'), obj.patientDeconvTooTab(k).getMbvRoiMapSet());
                savemat(fullfile(saveCurSlcPath, 'fitRoiCtcSet'), obj.patientDeconvTooTab(k).getFitRoiCtcSet());
                savemat(fullfile(saveCurSlcPath, 'roiCtcSet'), obj.patientDeconvTooTab(k).getRoiCtcSet());
                savemat(fullfile(saveCurSlcPath, 'roiMaskSet'), obj.patientDeconvTooTab(k).getRoiMaskSet());
                
                
                %copy peak image from PatientDataPrep folder
                copyfile(fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'peakImage.mat'),...
                    fullfile(saveCurSlcPath, 'peakImage.mat'));
                % copy baselineAvgMap  from PatientDataPrep folder
                copyfile (fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'baselineAvgMap.mat'), ...
                    fullfile(saveCurSlcPath, 'baselineAvgMap.mat'));
                % copy baselineLengthMap from PatientDataPrep folder
                copyfile (fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'baselineLengthMap.mat'), ...
                    fullfile(saveCurSlcPath, 'baselineLengthMap.mat'));
                % copy baselineSigmaMap from PatientDataPrep folder
                copyfile (fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'baselineSigmaMap.mat'), ...
                    fullfile(saveCurSlcPath, 'baselineSigmaMap.mat'));
                
                
                
                if obj.getProcessMeasUncertainty()
                    % get voxels pos of representative curves
                    [x, y] = obj.patientDeconvTooTab(k).getRoiRepresentativePosSet();
                    mbfMap = obj.patientDeconvTooTab(k).getMbfMap('pixels', [], 'ml/min/g');
                    for l = 1 : obj.patientDeconvTooTab(k).getNbRoi();
                        roiMBFUnscertaintyStruct = obj.patientDeconvTooTab(k).getRoiMbfUncertainty(l);
                        root.slc.(char(obj.slcList(k))).bfRoiUncertainty.(sprintf('roi%02d', l)).roiAvgCtc = 60 * obj.patientDeconvTooTab(k).getRoiMbfByIdx(l);
                        root.slc.(char(obj.slcList(k))).bfRoiUncertainty.(sprintf('roi%02d', l)).roiRepresentativeCtc = mbfMap(x(l), y(l));
                        root.slc.(char(obj.slcList(k))).bfRoiUncertainty.(sprintf('roi%02d', l)).wildBootstrap.mean = 60 * roiMBFUnscertaintyStruct.avg;
                        root.slc.(char(obj.slcList(k))).bfRoiUncertainty.(sprintf('roi%02d', l)).wildBootstrap.std = 60 * roiMBFUnscertaintyStruct.std;
                        root.slc.(char(obj.slcList(k))).bfRoiUncertainty.(sprintf('roi%02d', l)).wildBootstrap.min = 60 * roiMBFUnscertaintyStruct.minVal;
                        root.slc.(char(obj.slcList(k))).bfRoiUncertainty.(sprintf('roi%02d', l)).wildBootstrap.max = 60 * roiMBFUnscertaintyStruct.maxVal;
                    end
                end
            % slice wise processing summuray
                root.slc.(char(obj.slcList(k))).timeProcessing = obj.patientDeconvTooTab(k).getProcessingTime();
            end
            if strcmp('SpatioTemp', obj.getMethod())
                root.parameters.lambda_s = obj.patientDeconvTooTab(k).getLambdaS();
                root.parameters.lambda_t = obj.patientDeconvTooTab(k).getLambdaT();
                root.parameters.delta = obj.patientDeconvTooTab(k).getDelta();
            end
            % number of bootstrap iterations
            root.bootstrap.nbIterations = obj.patientDeconvTooTab(k).getNbBsIterations();
            
            struct2xml(struct('summary', root), fullfile(savePath, 'summary.xml'));
            %figures
            figureMgr.getInstance().saveAll(savePath);
            disp('save finisfed succesfully.');
        end% savePatientResults
        
        function success = save_createSaveDir(obj, path)
                        %check if dir dir exist
            success = true;
            if isdir(path)
                switch questdlg(sprintf('%s:\n this folder already exist. Squeeze?', path))
                    case {'No', 'Cancel'}
                        success = false;
                        return;
                    case 'Yes'
                        success = rmdir(path, 's');
                end
            end
            if ~success
                return;
            end
            success = mkdir(path);
        end%save_createSaveDir
        
        function dispResults(obj)
            delete(get(obj.rPanel,'Children'));
            if ~obj.getDeconvMode()
                obj.dispResultsPhantom();
            else
                obj.handleAxesTab = tight_subplot(3,2,[.05 .03],[.01 .01],[.01 .01], obj.rPanel);
                obj.dispResultsPatient(obj.getDisplayMode(), 1);
            end
        end%dispResults
        
        function dispResultsPhantom(obj)
            orglMbfMat = 60 * loadmat([obj.getPhantomPath() '\mbfMap.mat']);
            orglMbvMat = loadmat([obj.getPhantomPath() '\mbvMap.mat']);
            switch obj.getDisplayMode()
                case 'pixels'
                    mbfMat = obj.deconvTool.getMbfMap(obj.getDisplayMode(), 1, 'ml/min/g');
                    mbvMat = obj.deconvTool.getMbvMap(obj.getDisplayMode(), 1);
                case 'rois'
                    mbfMat = obj.deconvTool.getMbfRoiMapSet('ml/min/g');
                    mbvMat = obj.deconvTool.getMbvRoiMapSet();
            end
            
            bfRange = [min(min(orglMbfMat(:)), min(min(mbfMat))), ...
                max(max(orglMbfMat(:)), max(max(mbfMat)))];
            bvRange = [min(min(orglMbvMat(:)), min(min(mbvMat))), ...
                max(max(orglMbvMat(:)), max(max(mbvMat)))];
            
            delete(get(obj.rPanel,'Children'));
            %axes('parent', obj.rPanel);
            colormap jet;
            switch obj.getMethod
                case {'FtKpsVpVe', 'Bayesian>>FtKpsVpVe'}
                    obj.handleAxesTab = tight_subplot(3,2,[.05 .03],[.01 .01],[.01 .01], obj.rPanel);
                    obj.dispMap(orglMbfMat, bfRange, 'original mbf map (cc/min/g)', obj.handleAxesTab(1));
                    obj.dispMap(orglMbvMat, bvRange, 'original mbv map(cc/g)', obj.handleAxesTab(2));
                    obj.dispMap(60 * mbfMat, bfRange, 'deconv mbf map', obj.handleAxesTab(3));
                    obj.dispMap(obj.deconvTool.getMbvMap(), bvRange, 'deconv mbv map', obj.handleAxesTab(4));
                    kpsMap = obj.deconvTool.getKpsMap();
                    obj.dispMap(kpsMap, [min(kpsMap(:)) max(kpsMap(:))], 'deconv kps map', obj.handleAxesTab(5));
                    veMap = obj.deconvTool.getVeMap();
                    obj.dispMap(veMap, [min(veMap(:)) max(veMap(:))], 'deconv ve map', obj.handleAxesTab(6));
                    
                otherwise
                    obj.handleAxesTab = tight_subplot(2, 2,[.05 .03],[.01 .01],[.01 .01], obj.rPanel);
                    obj.dispMap(orglMbfMat, bfRange, 'original mbf map (cc/min/g)', obj.handleAxesTab(1));
                    obj.dispMap(orglMbvMat, bvRange, 'original mbv map(cc/g)', obj.handleAxesTab(2));
                    obj.dispMap(mbfMat, bfRange, 'deconv mbf map', obj.handleAxesTab(3));
                    obj.dispMap(mbvMat, bvRange, 'deconv mbv map', obj.handleAxesTab(4));
            end
            
            opt.paramName = 'mbf'; opt.title = ['MBF theoritical vs ' obj.getMethod() ' deconvolution'];
            obj.mbfBAResults = obj.procBA(orglMbfMat, mbfMat, opt);
            opt.paramName = 'mbv'; opt.title = ['MBV theoritical theo vs ' obj.getMethod() ' deconvolution'];
            obj.mbvBAResults = obj.procBA(orglMbvMat, mbvMat, opt);
            %disp sigma map
            
            figureMgr.getInstance().newFig('mbfSigmaMap');
            imagesc(obj.deconvTool.getMbfSigmaMap('ml/min/g')); title('mbf sigma map (ml/min/g)');
            figureMgr.getInstance().newFig('mbvSigmaMap');
            imagesc(obj.deconvTool.getMbvSigmaMap()); title('mbv sigma map');
            
            % disp processing time
            obj.setSummaryUI(['time elapsed: ' , num2str(obj.deconvTool.getProcessingTime())]);
        end%dispResultsPhantom
        
        function dispResultsPatient(obj, mode, roiIdx)
%             axes('parent', obj.rPanel);
            
            msg = 'time elapsed:';
            totalTimeElapsed = 0;
            for k = 1 : length(obj.slcList)
                %gather data
                pkImage = loadmat(fullfile(obj.getPhantomPath(), 'dataPrep', char(obj.slcList(k)), 'peakImage.mat'));
                [mbfMap, mbvMap] = obj.getMaps(k, mode, roiIdx);
                %display
                [map, scale] = overlay(obj.correctImage(pkImage), mbfMap);
%                 axes(obj.handleAxesTab(2 * k - 1));
                obj.dispMap(map, scale, ['mbf map ' char(obj.slcList(k)) ' (ml/min/g)'], obj.handleAxesTab(2 * k - 1));
                [map, scale] = overlay(obj.correctImage(pkImage), mbvMap);
                obj.optimizeFocus(obj.handleAxesTab(2 * k - 1), logical(obj.patientDeconvTooTab(k).getMbfMap('rois', roiIdx, 'ml/min/g')));
%                 axes(obj.handleAxesTab(2 * k));
                obj.dispMap(map, scale, ['mbv map ' char(obj.slcList(k)) ' (ml/g)'], obj.handleAxesTab(2 * k));
                obj.optimizeFocus(obj.handleAxesTab(2 * k), logical(obj.patientDeconvTooTab(k).getMbfMap('rois', roiIdx, 'ml/min/g')));
                totalTimeElapsed = totalTimeElapsed + obj.patientDeconvTooTab(k).getProcessingTime();
                msg = sprintf('%s | %s: %.1f s', msg, char(obj.slcList(k)), obj.patientDeconvTooTab(k).getProcessingTime());
            end
            %obj = obj.setSummaryUI(msg);
            obj.setFooterStr(msg);
        end% dispResultsPatient
        
        function [mbfMap, mbvMap] = getMaps(obj, slcIdx, mode, roiIdx)
            mbfMap = obj.patientDeconvTooTab(slcIdx).getMbfMap(mode, roiIdx, 'ml/min/g');
            mbvMap = obj.patientDeconvTooTab(slcIdx).getMbvMap(mode, roiIdx);
        end%getMaps
        
        function dispMap(obj, map, colorbarRge, titleStr, axHdle)
%             xlim = get(axHdle, 'XLim');
%             ylim = get(axHdle, 'YLim');
            axes(axHdle);
            cla(axHdle)
            hdle = imagesc(map);
            set(hdle, 'ButtonDownFcn', @obj.onBnClickCb);
            try
                colorbar('YColor', [1 1 1]); caxis(colorbarRge);
            catch e
                if e.identifier == 'MATLAB:caxis:InvalidVector'
                    obj.lgr.warn('could not display colorbar');
                end
            end
                
            axis off image; 
            text('units','normalized','position', [0.25, 0.05],'fontsize',...
                8, 'color', 'white', 'string', titleStr);
%             if xlim(1) && xlim(2) > 1 
%                 set(axHdle, 'XLim', xlim);
%                 set(axHdle, 'YLim', ylim);
%             end
            
        end%dispMap
        
        function baResults = procBA(~, orgMap, deconvMap, opt)
            fm = figureMgr.getInstance();
            label = {'Theoritical value','Measured value'}; % Names of data sets
            corrinfo = {'n','SSE','r2','eq'}; % stats to display of correlation scatter plot
            BAinfo = {'RPC(%)'}; % stats to display on Bland-ALtman plot
            limits = 'auto'; % how to set the axes limits
            orgMap = reshape(orgMap, 1, numel(orgMap));
            deconvMap = reshape(deconvMap, 1, numel(deconvMap));
            figHdl = fm.newFig(['BA_' opt.paramName]);
            [~, ~, baResults] = BlandAltman(figHdl, orgMap(:), deconvMap(:), label, opt.title, opt.paramName, ...
                                     corrinfo, BAinfo, limits, 'br', '');
%             set(figHdl, 'Name', );
            
        end%procBA
        
        function onBnClickCb(obj, arg1, ~)
            axesHandle  = get(arg1, 'Parent');
            coordinates = get(axesHandle, 'CurrentPoint');
            coordinates = round(coordinates(1, 1:2));
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end
            obj.setFooterStr(sprintf('clicked on (%d; %d)', coordinates(2), coordinates(1)));
            
            ldeconvTool = obj.getDeconvTool(axesHandle);
            
            switch obj.getMethod()
                case 'SpatioTemp'
                    
                case 'Bayesian'
                    obj.dispResultsBayesian(ldeconvTool, coordinates);
                case 'Fermi'
                    obj.dispResultsFermi(ldeconvTool, coordinates);
                otherwise
                    %             sg = ldeconvTool.getCtc(coordinates(2), coordinates(1));
                    %             sgFit =  ldeconvTool.getCtcFit(coordinates(2), coordinates(1));
                    %             tAcq = ldeconvTool.getTAcq();
                    %             tAcqDeconv = tAcq(1:length(sgFit));
                    %             bf = ldeconvTool.getMbf(coordinates(2), coordinates(1));
                    %             bv = ldeconvTool.getMbv(coordinates(2), coordinates(1));
                    [sg, sgFit, tAcqAif, tAcqSlc, bf, bv, residue, bfStd] = ...
                        obj.getLocalProperties(coordinates(2), coordinates(1), ldeconvTool);
                    
                    if obj.getDeconvMode()
                        [roiId, roiSurf, avgRoiSg, avgRoiSgFit, roiBf, roiBv] = ...
                            obj.getRoiProperties(coordinates(2), coordinates(1), ldeconvTool);
                    end
                    figureMgr.getInstance().newFig('fitCurve');
                    hold all;
                    plot(tAcqSlc, sg); plot(tAcqSlc(1:length(sgFit)), sgFit', '--');
                    if obj.getDeconvMode(); plot(tAcqSlc, avgRoiSg); plot(tAcqSlc(1 : length(sgFit)), avgRoiSgFit, '--'); end
                    
                    if obj.getDeconvMode()
                        legend('signal', 'fitted signal', 'roi signal', 'roi fitted signal');
                        title(sprintf('concentration time curve with:\n bf : %f mL/min/g, bv: %f mL/g\n roi bf : %f mL/min/g, roi bv: %f mL/g, roi surface: %d vx', bf * 60, bv, 60 * roiBf, roiBv, roiSurf));
                        obj.setSummaryUI(sprintf('current pix:\n\t x: %d, y: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g \ncurrent roi:\n\t id: %d\n\t surface: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g\n\t bf uncertainty : %0.2fmL/min/g\n',...
                            coordinates(2), coordinates(1), bf * 60, bv, roiId, roiSurf, roiBf, roiBv, bfStd * 60));
                    else
                        legend('signal', 'fitted signal');
                        title(sprintf('concentration time curve with:\n bf : %f mL/min/g, bv: %f mL/g\n', bf * 60, bv));
                        obj.setSummaryUI(sprintf('current pix:\n\t x: %d, y: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g \n\t bf uncertainty : %0.2fmL/min/g (%0.2f%%)\n',...
                            coordinates(2), coordinates(1), bf * 60, bv, bfStd * 60, 100 * bfStd / bf));
                    end
                    %plot aif
                    plot(tAcqAif, ldeconvTool.getNormaAifCtc);
                    %             plot residue function
            end
        end%onBnClickCb
        
        function dispResultsBayesian(obj, ldeconvTool, coor)
            
            switch obj.getDisplayMode()
                case 'rois'
                [roiId, roiSurf, sg, fit, bf, bv, tAcqAif, tAcqSlc] = ...
                    obj.getRoiProperties(coor(2), coor(1), ldeconvTool);
                sgFit.t_acq = tAcqSlc';
                sgFit.est_acq = fit;
                sgFit.sig_acq = (ones(size(fit)) .* 1e-6);
                otherwise
                    [sg, sgFit, tAcqAif, tAcqSlc, bf, bv, residue, ~, p_bf] = ...
                        obj.getLocalPropertiesBayesian(coor(2), coor(1), ldeconvTool);
                    if obj.getDeconvMode()
                        [roiId, roiSurf, ~, ~, ~, ~, ~, ~, bfUncert] = ...
                            obj.getRoiProperties(coor(2), coor(1), ldeconvTool);
                    end
                    bfStd = -1;
            end
            c = 'r';
            figureMgr.getInstance().newFig('fitCurve');
            h = subplot(2, 2, [1, 2]); %cla(h); 
            hold all;
            lgdList = {};
            plot(tAcqSlc, sg, 'o', 'color', c); lgdList = [lgdList  'signal'];
            plot(sgFit.t_acq, sgFit.est_acq', '--', 'color', c); lgdList = [lgdList  'fitted signal'];
            %if obj.getDeconvMode(); plot(tAcqSlc, avgRoiSg, 'o'); plot(sgFit.t_acq, avgRoiSgFit.est_acq, '--'); end
            %plot aif
            plot(tAcqAif, ldeconvTool.getNormaAifCtc, 'o', 'color', [0 0.5 0]); lgdList = [lgdList  'AIF'];
            %plot fit error
            fillPlot(sgFit.t_acq, sgFit.est_acq + sgFit.sig_acq,  sgFit.est_acq - sgFit.sig_acq, c); lgdList = [lgdList  'error'];
            
            if obj.getDeconvMode()
                legend(lgdList);
                title(sprintf('concentration time curve with:\n bf : %f mL/min/g, bv: %f mL/g\n, roi surface: %d vx', bf * 60, bv, roiSurf));
                obj.setSummaryUI(sprintf('current pix:\n\t x: %d, y: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g \ncurrent roi:\n\t id: %d\n\t surface: %d\n\t bf uncertainty : %0.2fmL/min/g\n',...
                    coor(2), coor(1), bf * 60, bv, roiId, roiSurf, bfUncert.avg * 60));
            else
                legend('signal', 'fitted signal');
                title(sprintf('concentration time curve with:\n bf : %f mL/min/g, bv: %f mL/g\n', bf * 60, bv));
                obj.setSummaryUI(sprintf('current pix:\n\t x: %d, y: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g \n\t bf uncertainty : %0.2fmL/min/g (%0.2f%%)\n',...
                    coor(2), coor(1), bf * 60, bv, bfStd * 60, 100 * bfStd / bf));
            end
            xlabel('time (s)'); ylabel('[Gd] mol/L');
            %plot residue function
            h = subplot(2, 2, 3); %cla(h);
            plot(residue.t, residue.est, c); hold all;
            fillPlot(residue.t, residue.est + residue.sig,  residue.est - residue.sig, c);
            legend('residue function');
            xlabel('time (s)'); ylabel('A.U');
            set(h, 'YLim', [0, 1.5]);
            %plot bf probability
            h = subplot(2, 2, 4); hold on;
            plot(p_bf.bf .* 60, p_bf.p, c);
            xlabel('mbf (ml/min/g)')
            ylabel('P(mbf)');
            set(h, 'YLim', [0, 200]);
        end%dispResultsBayesian
        
        
        function dispResultsFermi(obj, ldeconvTool, coor)
            [sg, sgFit, tAcqAif, tAcqSlc, bf, bv, residue, bfStd] = ...
                obj.getLocalProperties(coor(2), coor(1), ldeconvTool);
            try 
                [roiId, roiSurf, avgRoiSg, avgRoiSgFit, roiBf, roiBv, ~, ~, bfUncert] = ...
                        obj.getRoiProperties(coor(2), coor(1), ldeconvTool);
            catch
                obj.lgr.err('could not retreive ROI properties');
            end
            c = 'r';
            figureMgr.getInstance().newFig('fitCurve');
            subplot(2,1,1); hold all;
            plot(tAcqSlc, sg, 'o', 'color', c); plot(tAcqSlc(1:length(sgFit)), sgFit', '--', 'color', c);
            %if obj.getDeconvMode(); plot(tAcqSlc, avgRoiSg); plot(tAcqSlc(1 : length(sgFit)), avgRoiSgFit, '--'); end
            
            if obj.getDeconvMode()
                legend('signal', 'fitted signal', 'roi signal', 'roi fitted signal');
                title(sprintf('concentration time curve with:\n bf : %f mL/min/g, bv: %f mL/g\n roi bf : %f mL/min/g, roi bv: %f mL/g, roi surface: %d vx', bf * 60, bv, 60 * roiBf, roiBv, roiSurf));
                obj.setSummaryUI(sprintf('current pix:\n\t x: %d, y: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g \ncurrent roi:\n\t id: %d\n\t surface: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g\n\t bf uncertainty : %0.2fmL/min/g\n',...
                    coor(2), coor(1), bf * 60, bv, roiId, roiSurf, roiBf, roiBv, 60 * bfUncert.avg));
            else
                legend('signal', 'fitted signal');
                title(sprintf('concentration time curve with:\n bf : %f mL/min/g, bv: %f mL/g\n', bf * 60, bv));
                obj.setSummaryUI(sprintf('current pix:\n\t x: %d, y: %d\n\t bf: %0.2f mL/min/g, bv: %0.2f mL/g \n\t bf uncertainty : %0.2fmL/min/g (%0.2f%%)\n',...
                    coor(2), coor(1), bf * 60, bv, bfStd * 60, 100 * bfStd / bf));
            end
            %plot aif
            plot(tAcqAif, ldeconvTool.getNormaAifCtc, 'o', 'color', [0 .5 0]);
            subplot(2,1,2); hold all;
            residue = [zeros(6, 1); residue(1:end-6)];
            plot(tAcqAif(1 : length(residue)), residue ./ max(residue(:)), c);
        end%dispResultsFermi
        
        function deconvTool = getDeconvTool(obj, axesHandle)
            if obj.getDeconvMode % patient
                %get axes pos
                for k = 1 : length(obj.handleAxesTab)
                    if obj.handleAxesTab(k) == axesHandle
                        pos = k; break;
                    end
                end
                    deconvTool = obj.patientDeconvTooTab(ceil(pos/2));
            else % phantom
                    deconvTool = obj.deconvTool;
            end
        end%getDeconvTool
        
        function [localCtc, localCtcFit, tAcqAif, tAcqSlc, bf, bv, residue, bfStd] = getLocalProperties(obj, x, y, deconvTool)
            localCtc = deconvTool.getCtc(x, y);
            localCtcFit =  deconvTool.getCtcFit(x, y);
            tAcqAif = deconvTool.getTAcqAif();
            tAcqSlc = deconvTool.getTAcqSlc();%tAcqAif(1 : length(localCtcFit));
            bf = deconvTool.getMbf(x, y);
            bv = deconvTool.getMbv(x, y);
            try
                bfStd = deconvTool.getMbfUncertainty(x, y);
            catch
                bfStd = -1;
            end
            switch obj.getMethod()
                case 'SpatioTemp'
                    residue = deconvTool.getResidue(x, y);
                case 'Fermi'
                    residue = deconvTool.getResidue(x, y);
                case 'Bayesian'
                    [localCtc, localCtcFit, tAcqAif, tAcqSlc, bf, bv, residue, bfStd] = ...
                        obj.getLocalPropertiesBayesian(x, y, deconvTool);
                otherwise
                residue = -1;
            end
        end%getLocalCtc
        
        function [localCtc, localCtcFit, tAcqAif, tAcqSlc, bf, bv, residue, bfStd, p_bf] = ...
                getLocalPropertiesBayesian(obj, x, y, deconvTool)
            res = deconvTool.getDeconvResults(x, y);
            localCtc = deconvTool.getCtc(x, y);
            localCtcFit = res.ctcFit;
            bf = deconvTool.getMbf(x, y);
            bv = deconvTool.getMbf(x, y);
            tAcqAif = deconvTool.getTAcqAif();
            tAcqSlc = deconvTool.getTAcqSlc();
            residue = res.residue;
            bfStd = -1;
            p_bf = res.p_bf;
        end%getLocalPropertiesBayesian
        
        function [roiId, roiSurf, avgRoiCtc, avgRoiCtcFit, bf, bv, tAcqAif, tAcqSlc, bfUncert] = getRoiProperties(obj, x, y, deconvTool)
            roiId = deconvTool.getRoiId(x, y);
            %[xRoi, yRoi] = deconvTool.getRoiVoxels(roiId);
            if roiId ~= -1
                roiSurf = deconvTool.getRoiSurf(roiId);
                avgRoiCtc = deconvTool.getAvgRoiCtc(roiId);
                avgRoiCtcFit = deconvTool.getAvgRoiCtcFit(roiId);
                bf = deconvTool.getRoiMbf(x, y);%deconvTool.getRoiMbf(roiId);vTool)
                if obj.getProcessMeasUncertainty()
                    bfUncert = deconvTool.getRoiMbfUncertainty(roiId);
                else
                    bfUncert.avg = -1;
                end
                bv = deconvTool.getRoiMbv(x, y);%deconvTool.getRoiMbv(roiId);
                tAcqAif = deconvTool.getTAcqAif();
                tAcqSlc = deconvTool.getTAcqSlc();
            else
                %roiId == -1 means not applicable
                T = length(deconvTool.getTAcq());
                roiSurf = -1;
                avgRoiCtc = zeros(1, T);
                avgRoiCtcFit = zeros(1, T);
                bf = -1;
                bv = -1;
            end
        end%getRoiProperties
    
        function browsePatientPathCb(obj, ~, ~)
            path = uigetdir(obj.basePath());
            set(obj.phantomPathUI, 'String', path);
            obj.updateAifPath(fullfile(path, 'dataPrep\Aif\'));
            obj.updateSavePath(fullfile(path, 'deconvolution\', obj.getMethod()));
        end%browsePatientPathCb
        
        function updateAifPath(obj, path)
            if obj.getDeconvMode()
                set(obj.aifPathUI, 'String', path);
            end
        end%updateAifPath
    
    end%methods (Access = protected)

%% private methods
    methods (Access = private)
        function obj = setAifPathUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 2) 0.1 obj.HdleHeight],...
                'String', 'aif Path');
            %edit box
            obj.aifPathUI = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', 'D:\02_Matlab\Data\SignalSimulation\aifShaper\',...
                'Position', [obj.col(2) obj.lin(end - 2) 0.5 obj.HdleHeight]);
        end%setAifPathUI
        
        function obj = initPhantomPathUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 3) 0.1 obj.HdleHeight],...
                'String', 'phantom Path');
            %edit box
            obj.phantomPathUI = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', [obj.basePath 'phantom\1_Myocarde\'],...
                'Position', [obj.col(2) obj.lin(end - 3) 0.5 obj.HdleHeight]);
            
            % browse
            obj.browsePatientPathBnUI = uicontrol(obj.lPanel, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.col(7) obj.lin(end - 3) 0.1 obj.HdleHeight],...
                'String', '...',...
                'Callback', @obj.browsePatientPathCb);
        end%setPhantomPathUI
        
        function obj = setMethodChoiceUI(obj)
            
            obj.methodChUI = uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(1) 0.4 obj.HdleHeight],...
                'String', {'Fermi', 'Bayesian', 'BayesianParallel',...
                'FtKpsVpVe', 'SpatioTemp', 'oSVD', 'Bayesian>>Fermi',...
                'Bayesian>>FtKpsVpVe', 'Rdm'},...
                'Callback', @obj.updateMethodCb);
        end %setMethodChoiceUI
        
        function obj = setSldrTAcqUI(obj)
            
            % text
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 4) 0.1 0.05],...
                'String', 'time portion');
            
            obj.sldrTimeAcqUI = ...
                uicontrol(obj.lPanel, 'Style', 'slider',...
                'Units',  'normalized',...
                'Value', 100,...
                'Min',10, ...
                'Max',100, ...
                'Position', [obj.col(2) obj.lin(end - 4) 0.35 0.04], ...
               'Callback', @obj.sldrCb);
            
            obj.eBoxTimeAcqUI = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String',    '100', ...
                'Position', [obj.col(6) obj.lin(end - 4) 0.1 0.05], ...
                'Callback', @obj.eboxCb);
            %unit
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(8) obj.lin(end - 4) 0.07 0.05],...
                'String', '%');
            
        end%setSldrTAcqUI
        
        function obj = setdeconvModeUI(obj)
            obj.deconvModeUI = ...
                uicontrol('Style', 'checkbox',...
                'Units',  'normalized', 'Position', [obj.col(1) + 0.03, obj.lin(3), 0.1, obj.HdleHeight], ...
                'String',   'patient deconv', 'Value',    0, ...
                'Callback', @obj.updateDeconvModeCb);
        end %setdeconvModeUI
        
        function obj = setRoiDisplayModeUI(obj)
             % text
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) (obj.lin(5) + 0.025) 0.2 0.05],...
                'String', 'parameter display mode');
            
            obj.roiDisplayModeUI = ...
            uicontrol('Style', 'popup',...
                'Units',  'normalized', 'Position', [obj.col(2) , obj.lin(5), 0.1, obj.HdleHeight], ...
                'String',   {'pixels', 'rois', 'invisible'}, 'Value',  1, ...
                'Visible', 'on', ...
                'Callback', @obj.updateDisplayCb);
        end%setRoiViewModeUI
        
        function obj = setSummaryUI(obj, text)
            if isempty(obj.summaryUI) || ~ishandle(obj.summaryUI)
                obj.summaryUI = uicontrol(obj.lPanel, 'Style', 'edit',...
                    'Min',0, 'Max',10, ...
                    'Units',  'normalized',...
                    'horizontalalignment','left',...
                    'Position', [obj.col(2) obj.lin(8) 0.5 0.15],...
                    'String', sprintf('Summary:\n %s', text));
            else
               set(obj.summaryUI, 'String', sprintf('Summary:\n%s', text));
            end
        end%setSummaryUI
        
        function obj = setChbxProcessMeasUncertaintyUI(obj)
            obj.chbxProcessMeasUncertaintyUI = ...
            uicontrol('Style', 'checkbox',...
                'Units',  'normalized', 'Position', [obj.col(1) + 0.03, obj.lin(4), 0.1, obj.HdleHeight], ...
                'String',   'process meas uncertainty', 'Value',    0);
%                 'Callback', @obj.updateDeconvModeCb);
        end%setChbxProcessMeasUncertaintyUI
        
        
%         Callback function
        function obj = eboxCb(obj, ~, ~)
            set(obj.sldrTimeAcqUI, 'Value', floor(str2num(get(obj.eBoxTimeAcqUI, 'String'))));
        end%eboxCb
        
        function obj = sldrCb(obj, ~, ~)
            set(obj.eBoxTimeAcqUI, 'String', num2str(floor(get(obj.sldrTimeAcqUI, 'Value'))));
        end%sldrCb
        
        function obj = updateDeconvModeCb(obj, ~, ~)
            if obj.getDeconvMode() % patient
                set(obj.phantomPathUI, 'String', fullfile(obj.basePath, '\patientData\02_CHUSE\'));
                set(obj.aifPathUI, 'String', fullfile(obj.basePath, '\patientData\patient\Aif\'));
                %set(obj.roiDisplayModeUI, 'Visible', 'on');
            else % phantom
                set(obj.phantomPathUI, 'String', fullfile(obj.basePath, '\phantom\1_Myocarde\'));
                set(obj.aifPathUI, 'String', 'D:\02_Matlab\Data\SignalSimulation\aifShaper\');%AIF_PATH
                %obj.initSavePathUI();
                %set(obj.roiDisplayModeUI, 'Visible', 'off');
            end
            obj.updateSavePath(fullfile(obj.getPhantomPath(), 'deconvolution', obj.getMethod()));
        end%updateDeconvModeCb
        
        function updateMethodCb(obj, ~, ~)
            obj.updateSavePath(fullfile(obj.getPhantomPath(), 'deconvolution', obj.getMethod()));
        end%updateMethodCb
        
        function obj = updateDisplayCb(obj, ~, ~)
            obj.dispResults();
        end%updateDisplayCb
        
        function setProcessingDisplay(obj)
            delete(get(obj.rPanel,'Children'));
            h = tight_subplot(1,1,[.05 .03],[.3 .3],[.01 .01], obj.rPanel);
            gifplayer('D:\02_Matlab\src\deconvTool\ressources\processing.gif', 0.1, h);
        end%setProcessingDisplay
        
        
    end%methods (Access = private)
end

