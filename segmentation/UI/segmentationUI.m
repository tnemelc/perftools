classdef segmentationUI < baseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        methodChoiceUI;%editbox
        mergeoptionUI;
        eraseOptionUI;
        overlayOptionUIStruct;
        thresholdTypeUIStruct;
        roiSelectionUIStruct;
        slrData;
        segTool;
        slcTimePos;
        axesHandles;
        seedCriterion;
    end
        %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = segmentationUI;
            end
            obj = localObj;
        end
    end
    %% protected  methods
    methods (Access = protected)
        function obj = goCb(obj, ~, ~)
            clc;
            obj.resetSeedCriterion();
            obj.setFooterStr('running');
            obj.wipeResults();
            obj.axesHandles = [];
            obj.segTool.prepare(obj.getPatientPath(), obj.getParameters());
            
            obj.segTool.run();
            
            switch obj.getMethodChoice()
                case 'auto_lesion_detect'
                    obj = obj.dispResults(false);
                    obj.dispResultsAutoLesionDetect();
                case 'rectangle'
                    obj.dispResultsRectangle();
                otherwise
                obj = obj.dispResults(false);
            end
        end%goCb
        
        function obj = saveCb(obj, ~, ~)
            
            switch obj.getMethodChoice()
                case 'auto_lesion_detect'
                    obj.saveAutoLesionResults();
                    return;
                case 'rectangle'
                    obj.saveRectangleResults();
                    return;
                case 'ManualMultiRoi'
                    obj.saveManualMultiRoi();
                    return;
                case 'ManualMultiRoiMapDisplay'
                    obj.saveManualMultiRoiMapDisplay();
                    return;
            end%switch
            
            slcList = obj.segTool.getSlcList();
            savePath = obj.getSavePath();
            if ~obj.checkSavePath()
                msgbox('path not allowed');
                obj.setFooterStr(sprintf('save canceled'));
                return;
            end
            
            if isdir(savePath)
                switch questdlg('patient folder already exist. Squeeze?')
                    case 'Yes'
                        rmdir(savePath, 's');
                    otherwise
                        obj.setFooterStr('save canceled');
                        return;
                end
            end
            
            if strcmp('Yes', questdlg('should save labeled region in idependant files (mask1, mask2, ...)?'));
                independantMaskFlag = true;
            else
                independantMaskFlag = false;
            end
            squeezeOriginalSearchingMasksFlag = false;
            if obj.segTool.checkMaskModification()
                if strcmp('Yes', questdlg('Original searching mask has been modified. want to squeeze it?'));
                    squeezeOriginalSearchingMasksFlag = true;
                end
            end
            
            for k = 1 : numel(slcList)
                slcName = char(slcList(k));
                curDir = [savePath '\' slcName];
                mkdir(curDir);
                curLabeldImg = obj.segTool.getLabledSlcImg(slcName);
                if ~independantMaskFlag
                    savemat(fullfile(curDir, 'labeledImg.mat'), curLabeldImg);
                else
                    nbRegions = max(curLabeldImg(:));
                    for l = 1 : nbRegions
                        curRegionMask = curLabeldImg;
                        curRegionMask(curLabeldImg ~= l) = 0;
                        curRegionMask(curLabeldImg == l) = 1;
                        savemat(fullfile(curDir, sprintf('labeledImg%03d.mat', l)), curRegionMask);
                    end
                end
                
                if squeezeOriginalSearchingMasksFlag
                        %save the searching mask in patient path
                        copyfile(fullfile(obj.getPatientPath(), 'dataPrep', slcName, 'mask.mat'),fullfile(obj.getPatientPath(), slcName, 'mask.mat.bak'), 'f')
                        savemat(fullfile(obj.getPatientPath(), 'dataPrep', slcName, 'mask.mat'), obj.segTool.getSearchingMask(slcName));
                end
                
                if strcmp('STMS', obj.getMethodChoice())
                    savemat([curDir '\filtCtcSet.mat'], obj.segTool.getfilteredCtcSet(slcName));
                end
                savemat(fullfile(curDir, 'peakImage.mat'), obj.segTool.getSlcPkImage(slcName));
                savemat(fullfile(curDir, 'ctcSet.mat'), obj.segTool.getCtcSet(slcName));
            end
            obj.saveParameters();
            obj.setFooterStr(sprintf('save finished successfully in %s', savePath));
        end%saveCb
        
        function saveAutoLesionResults(obj)
            slcList = obj.segTool.getSlcList();
            savePath = obj.getSavePath();
            
            if ~obj.checkSavePath(savePath)
                msgbox('path not allowed');
                obj.setFooterStr(sprintf('save canceled'));
                return;
            end
            mkdir(savePath);
            for k = 1 : numel(slcList)
                slcName = char(slcList(k));
                %save roi mask
                savemat(fullfile(savePath, ['firstRoiMask_' slcName]), obj.segTool.getRoiMask(slcName, 2));
    
            end%for
            
            featApex = obj.segTool.getFeatures('apex');
            featMid  = obj.segTool.getFeatures('mid');
            featBase = obj.segTool.getFeatures('base');
            
            maxNbEl = max([numel(featApex.avgTicAUCTab); numel(featMid.avgTicAUCTab); numel(featBase.avgTicAUCTab)]);
            AUC = zeros(maxNbEl, 3); maxSlope = zeros(maxNbEl, 3); maxSlopePos = zeros(maxNbEl, 3);
            TTP = zeros(maxNbEl, 3); peakVal = zeros(maxNbEl, 3);
            
            
            AUC(1 : numel(featApex.avgTicAUCTab), 1) = [featApex.avgTicAUCTab];
            AUC(1 : numel(featMid.avgTicAUCTab), 2) = [featMid.avgTicAUCTab];
            AUC(1 : numel(featBase.avgTicAUCTab), 3) = [featBase.avgTicAUCTab];
            
            maxSlope(1 : numel(featApex.avgTicMaxSlopeTab), 1) = [featApex.avgTicMaxSlopeTab];
            maxSlope(1 : numel(featMid.avgTicMaxSlopeTab), 2) = [featMid.avgTicMaxSlopeTab];
            maxSlope(1 : numel(featBase.avgTicMaxSlopeTab), 3) = [featBase.avgTicMaxSlopeTab];
            
            maxSlopePos(1 : numel(featApex.avgTicMaxSlopePosTab), 1) = [featApex.avgTicMaxSlopePosTab];
            maxSlopePos(1 : numel(featMid.avgTicMaxSlopePosTab), 2) = [featMid.avgTicMaxSlopePosTab];
            maxSlopePos(1 : numel(featBase.avgTicMaxSlopePosTab), 3) = [featBase.avgTicMaxSlopePosTab];
            
            ttp(1 : numel(featApex.avgTicTTPTab), 1) = [featApex.avgTicTTPTab];
            ttp(1 : numel(featMid.avgTicTTPTab), 2) = [featMid.avgTicTTPTab];
            ttp(1 : numel(featBase.avgTicTTPTab), 3) = [featBase.avgTicTTPTab];
            
            peakVal(1 : numel(featApex.avgTicPeakValueTab), 1) = [featApex.avgTicPeakValueTab];
            peakVal(1 : numel(featMid.avgTicPeakValueTab), 2) = [featMid.avgTicPeakValueTab];
            peakVal(1 : numel(featBase.avgTicPeakValueTab), 3) = [featBase.avgTicPeakValueTab];

            savemat(fullfile(savePath, 'AUC'), AUC);
            savemat(fullfile(savePath, 'maxSlope'), maxSlope);
            savemat(fullfile(savePath, 'maxSlopePos'), maxSlope);
            savemat(fullfile(savePath, 'ttp'), TTP);
            savemat(fullfile(savePath, 'peakVal'), peakVal);
            savemat(fullfile(savePath, 'FirstROISurface'), peakVal);
        end%saveAutoLesionResults
        
        function saveRectangleResults(obj)
            slcList = obj.segTool.getSlcList();
            if isdir(fullfile(obj.getSavePath()))
                rmdir(fullfile(obj.getSavePath()));
            end
            mkdir(fullfile(obj.getSavePath()));
            
            for k = 1 : numel(slcList)
                str = [];
                slcName = char(slcList(k));
                slcImgSerie = obj.segTool.getSlcSerie(slcName); colormap gray;
                [H, W, ~] = size(slcImgSerie);
                imagesc(obj.correctImage(slcImgSerie(:,:, obj.slcTimePos)));
                axis off image;
                rect = obj.segTool.getMyoRect(slcName);
                str = sprintf('<myocardium> <%f> <%f> <%f> <%f>\n', rect(1) / W, rect(2) / H, rect(3) / W, rect(4) / H);
                rect = obj.segTool.getVDRect(slcName);
                str = [str sprintf('<right-ventricle> <%f> <%f> <%f> <%f>\n', rect(1) / W, rect(2) / H, rect(3) / W, rect(4) / H)];
                rect = obj.segTool.getVGRect(slcName);
                str = [str sprintf('<left-ventricle> <%f> <%f> <%f> <%f>\n', rect(1) / W, rect(2) / H, rect(3) / W, rect(4) / H)];
                
                fID = fopen(fullfile(obj.getSavePath(),  [slcName '_labels.txt']), 'w');
                fprintf(fID,'%s', str);
                fclose(fID);
            end
            
        end%saveRectangleResults
        
        function saveManualMultiRoi(obj)
            slcList = obj.segTool.getSlcList();
            savePath = obj.getSavePath();
            
            if ~obj.checkSavePath()
                msgbox('path not allowed');
                obj.setFooterStr('save canceled');
                return;
            end
            mkdir(savePath);
            for k = 1 : numel(slcList)
                slcName = char(slcList(k));
                %save roi mask
                savemat(fullfile(savePath, ['firstRoiMask_' slcName]), obj.segTool.getLabledSlcImg(slcName));
                roiNameMap = obj.segTool.getRoiNameList(slcName);
                fID = fopen(fullfile(obj.getSavePath(),  [slcName '_labels.txt']), 'w');
                try
                    for l = 1 : length(roiNameMap)
                        fprintf(fID, 'roi %0.2d : %s\n', l, roiNameMap(l));
                    end
                catch e
                    fclose(fID);
                    obj.setFooterStr('x_x something bad happened during saving');
                    rethrow(e);
                end
            end%for
            obj.setFooterStr('save completed');
        end%saveManualMultiRoi
        
        function saveManualMultiRoiMapDisplay(obj)
            slcList = obj.segTool.getSlcList();
            savePath = obj.getSavePath();
            
            if ~obj.checkSavePath()
                msgbox('path not allowed');
                obj.setFooterStr('save canceled');
                return;
            end
            mkdir(savePath);
            for k = 1 : numel(slcList)
                slcName = char(slcList(k));
                %save roi mask
                labeledSlcImg = obj.segTool.getLabledSlcImg(slcName);
                savemat(fullfile(savePath, ['labelsMask_' slcName '.mat']), labeledSlcImg);
                seedsMask = obj.segTool.getSeedMap(slcName);
                savemat(fullfile(savePath, ['seedsMask_' slcName '.mat']), seedsMask);
                %save rois info
                root.roisInfo.roi = obj.segTool.getRoiInfoCell(slcName);
                struct2xml(root, fullfile(savePath, ['roiInfo_' slcName '.xml']));
                roiNameStruct = obj.segTool.getLblNameStruct(slcName);
                fid = fopen(fullfile(obj.getSavePath(), ['labels_' slcName '.txt']), 'w');
                try
                    roiNameStructFields = fields(roiNameStruct);
                    for l = 1 : length(roiNameStructFields)
                        fprintf(fid, 'roi name: %s, id: %d', char(roiNameStructFields(l)), roiNameStruct.(char(roiNameStructFields(l))));
                        parametricMap_bay = obj.segTool.getParametricMap(slcName, 'Bayesian', 'mbfMap');
                        if ~isnan(parametricMap_bay)
                            %get parametric map values of current region
                            roiParametricValues = parametricMap_bay(labeledSlcImg == roiNameStruct.(char(roiNameStructFields(l))));
                            fprintf(fid, ', surface: %d\n', length(roiParametricValues));
                            fprintf(fid, 'parametric values (bayesian):\n');
                            str = '';
                            for m = 1 : length(roiParametricValues)
                                str = sprintf('%s%0.02f;', str, roiParametricValues(m));
                            end
                            fprintf(fid, '%s\n', str);
                        else
                            obj.lgr.warn('saveManualMultiRoiMapDisplay');
                        end
                        
                        parametricMap_fermi = obj.segTool.getParametricMap(slcName, 'Fermi', 'mbfMap');
                        if ~isnan(parametricMap_fermi)
                            %get parametric map values of current region
                            roiParametricValues = parametricMap_fermi(labeledSlcImg == roiNameStruct.(char(roiNameStructFields(l))));
                            fprintf(fid, 'parametric values (fermi):\n');
                            str = '';
                            for m = 1 : length(roiParametricValues)
                                str = sprintf('%s%0.02f;', str, roiParametricValues(m));
                            end
                            fprintf(fid, '%s\n', str);
                        else
                            obj.lgr.warn('saveManualMultiRoiMapDisplay');
                        end
                        
                    end%for l = 1 : length(roiNameStructFields)
                catch e
                    fclose(fid);
                    obj.setFooterStr('x_x something bad happened during saving');
                    rethrow(e);
                end
                fclose(fid);
                
            end%for
            obj.setFooterStr('save completed');
        end%savesaveManualMultiRoiDisplay
        
        function saveParameters(obj)
            options = obj.getParameters();
            options.savePath = obj.getSavePath();
            options.patientPath = obj.getPatientPath();
            
            if strcmp('auto_lesion_detect', obj.getMethodChoice())
                slcList = obj.segTool.getSlcList();
                for k = 1 :  numel(slcList)
                    slcName = char(slcList(k));
                    options.optimalThreshold.(slcName) = obj.segTool.getOptimalThreshold(slcName);
                end
            end
            struct2xml(struct('root', options), fullfile(options.savePath, '\segmentationOptions.xml'));
        end%saveParameters
        
        function obj = dispResults(obj, keepAxesFlag)
            slcList = obj.segTool.getSlcList();
            if isempty(obj.axesHandles)
                obj.axesHandles = tight_subplot(2, 2, [.01 .01], [.01 .01], [.01 .01], obj.rPanel);
                for k = 1 : length(obj.axesHandles)
                    set(obj.axesHandles(k), 'color', 'k');
                end
            end
            cpt = 1;
            summaryStr = [];
            for k = 1 : numel(slcList)
                try
                    sliceName = char(slcList(k));
                    axes(obj.axesHandles(cpt)); 
                    xlim = get(obj.axesHandles(cpt), 'XLim'); ylim = get(obj.axesHandles(cpt), 'YLim');
                    obj.displaySliceImage(sliceName);
                    sliceStack(:, :, k) = obj.segTool.getLabledSlcImg(sliceName);
                    summaryStr = [summaryStr sprintf('%s : %d labels | ', sliceName, obj.segTool.getSlcNbLabels(sliceName))];
                    
                    if keepAxesFlag
                        set(obj.axesHandles(cpt), 'XLim', xlim); set(obj.axesHandles(cpt), 'YLim', ylim);
                    end
                    
                catch e
                    cprintf('orange','segmentationUI::dispResults: exception caught: %s\n', e.message);
                end
                cpt = cpt + 1;
            end
            obj.setFooterStr(summaryStr);
            dcm_obj = datacursormode(figureMgr.getInstance().getFig('deconvTool'));
            set(dcm_obj, 'UpdateFcn', {@updateDataTipCb, sliceStack, obj.axesHandles});
            
        end%dispResults
        
        
        function dispResultsAutoLesionDetect(obj)
            slcList = obj.segTool.getSlcList();
            axes(obj.axesHandles(4)); hold all;
            summaryStr = [];
            for k = 1 : numel(slcList)
                plot(obj.segTool.getFeatGradientNorm(char(slcList(k))));
                summaryStr = [summaryStr sprintf('%s: %d | ', ...
                                    char(slcList(k)), obj.segTool.getOptimalThreshold(char(slcList(k))))];      
            end
            summaryStr = ['optimal threshold -> ' summaryStr];
            obj.setFooterStr(summaryStr);
            legend(slcList);
        end%dispResultsAutoLesionDetect
        
        function dispResultsRectangle(obj)
            slcList = obj.segTool.getSlcList();
            if isempty(obj.axesHandles)
                obj.axesHandles = tight_subplot(2, 2, [.01 .01], [.01 .01], [.01 .01], obj.rPanel);
            end
            cpt = 1;
            for k = 1 : numel(slcList)
                axes(obj.axesHandles(cpt));
                slcName = char(slcList(k));
                slcImgSerie = obj.segTool.getSlcSerie(slcName); colormap gray;
                imagesc(obj.correctImage(slcImgSerie(:,:, obj.slcTimePos)));
                axis off image;
                rectangle('Position', obj.segTool.getMyoRect(slcName), 'EdgeColor', 'b');
                rectangle('Position', obj.segTool.getVDRect(slcName), 'EdgeColor', 'g');
                rectangle('Position', obj.segTool.getVGRect(slcName), 'EdgeColor', 'r');
                cpt = cpt + 1;
            end
        end%dispResultsRectangle
        
        
        function imHdle = displaySliceImage(obj, sliceName)
            try 
            slcImgSerie = obj.segTool.getSlcSerie(sliceName);
            
            switch obj.getOverlayOption
                case 'labeledROI'
                    mask = obj.filterMask(obj.segTool.getLabledSlcImg(sliceName));
                    try
                        imHdle = imagesc(overlay(obj.correctImage(slcImgSerie(:,:, obj.slcTimePos)), mask));
                    catch
                        cprintf([1,0.5,0], 'could not perform contrast/brightness correction\n');
                        imHdle = imagesc(overlay(slcImgSerie(:,:, obj.slcTimePos), mask));
                    end
                case 'seeds'
                    mask = obj.filterMask(obj.segTool.getSeedsMask(sliceName));
                    try
                        imHdle = imagesc(overlay(obj.correctImage(slcImgSerie(:,:, obj.slcTimePos)), mask));
                    catch
                        cprintf([1,0.5,0], 'could not perform contrast/brightness correction\n');
                        imHdle = imagesc(overlay(slcImgSerie(:,:, obj.slcTimePos), mask));
                    end
                otherwise
                    imHdle = imagesc(obj.correctImage(slcImgSerie(:, :, obj.slcTimePos)));
                    colormap('gray');
            end
            
            set(imHdle, 'ButtonDownFcn', {@obj.onBnClickCb, sliceName});
            set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, sliceName});
            text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                'color', 'white', 'string', ...
                sprintf('%s, %d/%d', sliceName, obj.slcTimePos, size(slcImgSerie,3)));
            axis off image;
            catch
                cprintf('orange','segmentationUI::displaySliceImage: exception caught: %s\', e.message);
%                 cprintf([1,0.5,0],'no slice %s\n', sliceName);
            end
        end%displaySliceImage
        
        function mask = filterMask(obj, mask)
            filter = obj.getRoiFilterTab();
            
            if filter(1) == -1
                return;
            end
            tmpMask = zeros(size(mask));
            for k = 1 : length(filter)
                tmpMask(mask == filter(k)) = 1;
            end
            mask = tmpMask .* mask;
        end%filterMask
        
        function params = getParameters(obj)
            for k = 1 : obj.slrData.sldrMap.length
                params.(char(obj.slrData.keySet(k))) = obj.slrData.valMap(char(obj.slrData.keySet(k)));
            end
            params.merge = obj.getStmsMergeOption();
            
            params.thresholdType = obj.getThresholdType();
            
            if strcmp('auto_temp_region_growing', obj.getMethodChoice())
                params.seedCriterion  = obj.getSeedCriterion();
            elseif strcmp('auto_lesion_detect', obj.getMethodChoice())
                params.seedCriterion  = 'min_area_under_curve';
            end
            
        end%getParameters
        
        function seedCriterion  = getSeedCriterion(obj)
            if obj.seedCriterion == -1
                obj.seedCriterion = questdlg('Select seed criterion', ...
                    'seed criterion', ...
                    'min_area_under_curve', 'max_area_under_curve', ...
                    'min_area_under_curve');
            end
            seedCriterion = obj.seedCriterion;
        end%getSeedCriterion
        
        function resetSeedCriterion(obj)
            obj.seedCriterion = -1;
        end
        
        function obj = setMethodChoiceUI(obj)
            obj.methodChoiceUI = uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(1) 0.4 obj.HdleHeight],...
                'String', {'STMS', 'Manual', 'ManualMultiRoi', 'ManualMultiRoiMapDisplay', 'rectangle', 'AHA_Segments',...
                'temporal_region_growing', 'auto_temp_region_growing',...
                'auto_lesion_detect'});
            set(obj.methodChoiceUI, 'Callback', @obj.methodChoiceCb);
        end%setMethodChoiceUI
        
        function obj = methodChoiceCb(obj, ~, ~)
            switch obj.getMethodChoice()
                case 'Manual'
                    visibilityFlag = 'off';
                    obj.segTool = segmentationToolManual();
                case 'STMS'
                    visibilityFlag = 'on';
                    obj.segTool = segmentationToolSTMS();
                case 'AHA_Segments'
                    visibilityFlag = 'off';
                    obj.segTool = SegmentationToolAhaSegments();
                case 'temporal_region_growing'
                    visibilityFlag = 'off';
                    obj.segTool = SegmentationToolTempRegionGrowing();
                case 'auto_temp_region_growing'
                    visibilityFlag = 'on';
                    obj.segTool = SegmentationToolAutoTempRegionGrowing();
                case 'auto_lesion_detect'
                    visibilityFlag = 'off';
                    obj.segTool = SegmentationToolAutoLesionDetect();
                case 'rectangle'
                    visibilityFlag = 'off';
                    obj.segTool = SegmentationToolRectangle();
                case 'ManualMultiRoi'
                    visibilityFlag = 'off';
                    obj.segTool = SegmentationToolManualMultiRoi();
                case 'ManualMultiRoiMapDisplay'
                    visibilityFlag = 'off';
                    obj.segTool = SegmentationToolManualMultiRoiMapDisplay();
            end%switch
            for i = 1 : size(obj.slrData.keySet, 2)
                set(obj.slrData.paramTextMap(char(obj.slrData.keySet(i))), 'Visible', visibilityFlag);
                set(obj.slrData.sldrMap(char(obj.slrData.keySet(i))), 'Visible', visibilityFlag);
                set(obj.slrData.editBoxMap(char(obj.slrData.keySet(i))), 'Visible', visibilityFlag);
                set(obj.slrData.unitTextMap(char(obj.slrData.keySet(i))), 'Visible', visibilityFlag);
            end%for
            %merge checkbox
            set(obj.mergeoptionUI, 'Visible', visibilityFlag);
            obj.updateSavePath(fullfile('segmentation', obj.getMethodChoice()));
        end%methodChoiceCb
        
        function obj = initParametersMap(obj)
            switch obj.getMethodChoice()
                case 'STMS'
            % create key sets
            obj.slrData.keySet =     {'xScale', 'yScale', 'rScale', 'lwTCrop', 'upTCrop'}; % append set name here
            obj.slrData.initValSet = { 20,         20,      6,              4,              60}; %append new param init value
            obj.slrData.minValSet =  {  2,          2,      1,               1,              25}; %append new param min value
            obj.slrData.maxValSet =  { 60,         60,     40,              25,             100};%append new param max value
            obj.slrData.factorSet =  {  1,            1,      1,              1,               1};%append new factor value (1 if no need to factor)
            obj.slrData.unitSet =    {'pixels', 'pixels', 'A.U',           'frame',    'frame'};
            % create maps
            obj.slrData.valMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.minValMap = containers.Map(obj.slrData.keySet, obj.slrData.minValSet);
            obj.slrData.maxValMap = containers.Map(obj.slrData.keySet, obj.slrData.maxValSet);
            obj.slrData.paramTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.editBoxMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.sldrMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.unitTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.factorMap = containers.Map(obj.slrData.keySet, obj.slrData.factorSet);
            %display sliders
                case 'auto_temp_region_growing'
                    obj.slrData.keySet =     {'limInfarct', 'limIschemia'}; % append set name here
                    obj.slrData.initValSet = { 0.001,        20          }; %append new param init value
                    obj.slrData.minValSet =  {  2,            2          }; %append new param min value
                    obj.slrData.maxValSet =  { 60,           60          };%append new param max value
                    obj.slrData.factorSet =  {  1,            1          };%append new factor value (1 if no need to factor)
                    obj.slrData.unitSet =    {'A.U',         'A.U'       };
                    % create maps
                    obj.slrData.valMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
                    obj.slrData.minValMap = containers.Map(obj.slrData.keySet, obj.slrData.minValSet);
                    obj.slrData.maxValMap = containers.Map(obj.slrData.keySet, obj.slrData.maxValSet);
                    obj.slrData.paramTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
                    obj.slrData.editBoxMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
                    obj.slrData.sldrMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
                    obj.slrData.unitTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
                    obj.slrData.factorMap = containers.Map(obj.slrData.keySet, obj.slrData.factorSet);
            end
            obj.dispSldrSet();
        end%initParametersMap
        
        function obj = dispSldrSet(obj)
            for i = 1 : size(obj.slrData.keySet, 2)
                %set real value for val map
                obj.slrData.valMap(char(obj.slrData.keySet(i))) = obj.slrData.valMap(char(obj.slrData.keySet(i))) * obj.slrData.factorMap(char(obj.slrData.keySet(i)));
                % text
                hPos = obj.lin(i + 1);
                obj.slrData.paramTextMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.col(1) hPos 0.1 0.05],...
                    'String', obj.slrData.keySet(i));
                
                %slider
                obj.slrData.sldrMap(char(obj.slrData.keySet(i))) = ... 
                    uicontrol(obj.lPanel, 'Style', 'slider',...
                    'Units',  'normalized',...
                    'Value', obj.slrData.valMap(char(obj.slrData.keySet(i))) / obj.slrData.factorMap(char(obj.slrData.keySet(i))),...
                    'Min',obj.slrData.minValMap(char(obj.slrData.keySet(i))), ...
                    'Max',obj.slrData.maxValMap(char(obj.slrData.keySet(i))), ...
                    'Position', [obj.col(2)  hPos 0.35 0.045],...
                    'Callback', {@obj.sldrCb, obj.slrData.keySet(i)});
                
                %edit box
                obj.slrData.editBoxMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'edit',...
                    'Units',  'normalized',...
                    'String', obj.slrData.valMap(char(obj.slrData.keySet(i))),...
                    'Position', [obj.col(6) hPos 0.1 0.05], ...
                    'Callback', {@obj.eboxCb, obj.slrData.keySet(i)});
                
                % units
                
                obj.slrData.unitTextMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.col(8) hPos 0.1 0.05],...
                    'String', obj.slrData.unitSet(i));
            end
        end%dispSldrSet
        
        function obj = dispMergeOption(obj)
            obj.mergeoptionUI = uicontrol('Style', 'checkbox',...
                'Units',  'normalized', 'Position', [obj.col(1) + 0.03, obj.lin(9), 0.1, obj.HdleHeight], ...
                'String',   'use merge option', 'Value',    0);
        end%dispMergeOption
        
        function obj = dispOverlayOptionUI(obj)
            obj.overlayOptionUIStruct.text = uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.col(1) (obj.lin(10) - 0.025) 0.1 0.05],...
                    'String', 'overlay');
            
            obj.overlayOptionUIStruct.popup = uicontrol(obj.lPanel, 'Style', 'popup',...
                    'Units',  'normalized', 'String', 'all',...
                    'Position', [obj.col(2) obj.lin(10) 0.3 0.03], ...
                    'String', {'labeledROI', 'seeds', 'none'},...
                    'Callback', @obj.onOverlayOptionCb);
        end%dispOverlayOptionUI
        
         function obj = dispEraseModeUI(obj)
             obj.eraseOptionUI = uicontrol('Style', 'checkbox',...
                'Units',  'normalized', 'Position', [obj.col(1) + 0.03, obj.lin(11), 0.1, obj.HdleHeight], ...
                'String',   'erase mode', 'Value',    0, 'Callback', @obj.onEraseOptionCb);
         end%dispEraseModeUI
        
        function obj = initRoiSelectionUI(obj)
            
            obj.roiSelectionUIStruct.text = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized', 'Position', [obj.col(5) (obj.lin(11) - 0.025) 0.05 0.05],...
                    'String', 'ROI');
            
            obj.roiSelectionUIStruct.editBox = ...
                    uicontrol(obj.lPanel, 'Style', 'edit',...
                    'Units',  'normalized', 'String', 'all',...
                    'Position', [obj.col(6) obj.lin(11) 0.3 0.03], ...
                    'Callback', @obj.onRoiEditboxCb);
            
        end%dispRoiSelectionUI
        
        function obj = initThresholdTypeUI(obj)
            obj.thresholdTypeUIStruct.text = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized', 'Position', [obj.col(5) (obj.lin(10) - 0.025) 0.1 0.05],...
                    'String', 'thresh. type');
            
            obj.thresholdTypeUIStruct.popup = ...
                    uicontrol(obj.lPanel, 'Style', 'popup',...
                    'Units',  'normalized', 'String', 'all',...
                    'Position', [obj.col(6) obj.lin(10) 0.3 0.03], ...
                    'String', {'absolute', 'percentage'});
        end %initThresholdTypeUI
        
        function toggleRoiSelection(obj, showFlag)
            if showFlag
                showFlag = 'on';
            else
                showFlag = 'off';
            end
            set(obj.roiSelectionUIStruct.text, 'visible', showFlag);
            set(obj.roiSelectionUIStruct.editBox, 'visible', showFlag);
        end%toggleRoiSelection
        
        function sldrCb(obj, ~, ~, arg2)
            val  =  floor(get(obj.slrData.sldrMap(char(arg2)), 'Value')) * obj.slrData.factorMap(char(arg2));
            obj.slrData.valMap(char(arg2)) = val;
            set(obj.slrData.editBoxMap(char(arg2)), 'String', num2str(val));
        end%sldrCb
        
        function eboxCb(obj, ~, ~, arg2)
            val  =  str2num(get(obj.slrData.editBoxMap(char(arg2)), 'String'));
            obj.slrData.valMap(char(arg2)) = val;
        end
        
        function onOverlayOptionCb(obj, ~, ~)
            obj.toggleRoiSelection(getOverlayOption(obj));
            obj.dispResults(true);
        end%onOverlayOptionCb
        
        function onEraseOptionCb(obj, ~, ~)
        end%onEraseOptionCb
        
        function onRoiEditboxCb(obj, ~, ~, ~)
            obj.dispResults(true);
        end%onRoiEditboxCb
        
        function onBnClickCb(obj, arg1, ~, slcName)
            
            if obj.getEraseOption()
                obj.startErase(slcName);
            else
                %
                
                axesHandle  = get(arg1, 'Parent');
                coordinates = get(axesHandle, 'CurrentPoint');
                xlimit = get(axesHandle, 'XLim'); ylimit = get(axesHandle, 'YLim');
                set(axesHandle, 'XLim', xlimit); set(axesHandle, 'YLim', ylimit);
                coordinates = floor(coordinates(1, 1 : 2));
                if ~coordinates(1); coordinates(1) = 1; end
                if ~coordinates(2); coordinates(2) = 1; end
                roiImg = obj.segTool.getLabledSlcImg(slcName);
                roiIdx = roiImg(coordinates(2), coordinates(1));
                
                slcSerie = obj.segTool.getSlcSerie(slcName);
                
                %get roi avg curve
                [H, W] = size(roiImg);
                [xPos, yPos] = ind2sub([H, W], find(roiImg == roiIdx));
                tmp = 0;
                for k = 1 : length(xPos)
                    tmp = tmp + squeeze(slcSerie(xPos(k), yPos(k), :));
                end
                avgCtc = tmp./length(xPos);
                
                ctc = squeeze(slcSerie(coordinates(2), coordinates(1), :));
                
                figureMgr.getInstance.newFig('segmentationTool:filteredCtc');
                clf; hold all;
                [lwrBndCtc uprBndCtc] = obj.calcUpperAndLowerBounds(xPos, yPos, slcSerie);
                tt = 1 : 1 : size(slcSerie, 3); tt = [tt tt];
                h = fill(tt, [uprBndCtc lwrBndCtc], [0.8216 1 1]);
                set(h,'EdgeColor','none');
                plot(ctc, '--');
                plot(avgCtc);
                if strcmp('STMS', obj.getMethodChoice())
                    filteredCtcSet = obj.segTool.getfilteredCtcSet(slcName);
                    filtCtc = squeeze(filteredCtcSet(coordinates(2), coordinates(1), :));
                    plot(filtCtc);
                end
                ylim([0 obj.segTool.getMaxValOfProcessedCtcSet(slcName)]);
                legend('bounds', 'raw curve', 'filtered curve', 'ROI average curve');
                title(sprintf('roi ID: %d, size : %d', roiIdx, length(xPos)));
                xlabel('time (heartbeat)'); ylabel('A.U');
                dcm_obj = datacursormode(figureMgr.getInstance().getFig('segmentationTool:filteredCtc'));
                if strcmp('STMS', obj.getMethodChoice())
                    set(dcm_obj, 'UpdateFcn', {@updateDataTip4CurvePlotCb, ctc, filtCtc, avgCtc});
                else
                    set(dcm_obj, 'UpdateFcn', {@updateDataTip4CurvePlotCb, ctc, 0, avgCtc});
                end
            end

        end%onBnClickCb
        
        function [lwrBndCtc, uprBndCtc] = calcUpperAndLowerBounds(obj, xPos, yPos, slcSerie)
            lwrBndCtc = ones(1, size(slcSerie, 3)) * inf;
            uprBndCtc = ones(1, size(slcSerie, 3)) * (-inf);
            for k = 1 : length(lwrBndCtc)
                for  l = 1 : length(xPos)
                    if slcSerie(xPos(l), yPos(l), k) < lwrBndCtc(k)
                        lwrBndCtc(k) = slcSerie(xPos(l), yPos(l), k);
                    end
                    if slcSerie(xPos(l), yPos(l), k) > uprBndCtc(k)
                        uprBndCtc(k) = slcSerie(xPos(l), yPos(l), k);
                    end
                end
            end
            uprBndCtc(1) = lwrBndCtc(1);
            uprBndCtc(end) = lwrBndCtc(end);
        end% calcUpperAndLowerBounds
        
        function onScrollCb(obj, ~, arg2, slcName)
            slcSerie = obj.segTool.getSlcSerie(slcName);
            obj.slcTimePos = floor(obj.slcTimePos  + arg2.VerticalScrollCount);
            if obj.slcTimePos < 1
                obj.slcTimePos = 1;
            end
            if obj.slcTimePos > size(slcSerie, 3)
                obj.slcTimePos = size(slcSerie, 3);
            end
            obj.dispResults(true);
        end%onSCrollCb
        
        function startErase(obj, slcName)
            set(gcf, 'WindowButtonMotionFcn', {@obj.erase, slcName});
            set(gcf, 'WindowButtonUpFcn', {@obj.stopEraseCb, slcName});
            set(gcf,'Pointer', 'circle');
        end
        
        function erase(obj, arg1, ~, slcName)
         labeledImg = obj.segTool.getLabledSlcImg(slcName);
         tmplblImg = filterMask(obj, labeledImg);
         coordinates = get(gca, 'CurrentPoint');
         disp(coordinates);
         coordinates = floor(coordinates(1, 1:2));
         if ~coordinates(1); coordinates(1) = 1; end
         if ~coordinates(2); coordinates(2) = 1; end
         disp(coordinates);
         tmplblImg(coordinates(2) - 1, coordinates(1)) = 0;
         tmplblImg(coordinates(2), coordinates(1) - 1) = 0;
         tmplblImg(coordinates(2) - 1, coordinates(1) - 1) = 0;
         tmplblImg(coordinates(2) - 1, coordinates(1) + 1) = 0;
         tmplblImg(coordinates(2), coordinates(1)) = 0;
         tmplblImg(coordinates(2) + 1, coordinates(1) - 1) = 0;
         tmplblImg(coordinates(2) + 1, coordinates(1)) = 0;
         tmplblImg(coordinates(2), coordinates(1) + 1) = 0;
         tmplblImg(coordinates(2) + 1, coordinates(1) + 1) = 0;
         newLabeledImg = labeledImg - (filterMask(obj, labeledImg) - tmplblImg);
         obj.segTool.setLabledSlcImg(slcName, newLabeledImg);
         obj.segTool.setMask(slcName, newLabeledImg > 0);
         xlim = get(gca, 'XLim'); ylim = get(gca, 'YLim');
         axes(gca); 
         imHdle = imagesc(tmplblImg);axis off image;
         set(gca, 'XLim', xlim); set(gca, 'YLim', ylim);
         set(imHdle, 'ButtonDownFcn', {@obj.onBnClickCb, slcName});
        end%eraseCb
        
        function stopEraseCb(obj, ~, ~, slcName)
         set(gcf, 'WindowButtonMotionFcn', '');
         set(gcf,'Pointer', 'arrow');
         obj = obj.dispResults(false);
        end%stopEraseCb
        
        function onKeyPressCb(obj, ~, arg)
            obj.onKeyPressCb@baseUI([], arg);
            obj.dispResults(true);
        end%onKeyPressCb
        
        function obj = browsePatientPathCb(obj, ~, ~)
            obj = obj.browsePatientPathCb@baseUI();
            obj.updateSavePath(fullfile('segmentation', obj.getMethodChoice()));
        end%browsePatientPathCb
        
    end%methods (Access = protected)
    
    %% public methods
    methods (Access = public)
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.setMethodChoiceUI();
            
            obj = obj.initPatientPathUI(fullfile(obj.basePath,...
                            'patientData\Segmentation\Arthaud_Gerard-new'));
%             obj = obj.initSavePathUI([obj.basePath 'segmentation\']);
            obj.updateSavePath(fullfile('segmentation', obj.getMethodChoice()));
            obj = obj.initParametersMap();
            obj = obj.dispMergeOption();
            obj = obj.dispOverlayOptionUI();
            obj = obj.initRoiSelectionUI();
            obj = obj.initThresholdTypeUI();
            obj = obj.dispEraseModeUI();
            obj.methodChoiceCb();
            obj.slcTimePos = 20;
            obj.setFooterStr('Segmentation Tool');
        end%initialize
        
        %getters
        function methodeChoice = getMethodChoice(obj)
            methodeChoiceList = get( obj.methodChoiceUI, 'String');
            methodeChoice = char(methodeChoiceList(get( obj.methodChoiceUI, 'Value')));
        end%getMethodChoice
        
        function mergeOption = getStmsMergeOption(obj)
            if get(obj.mergeoptionUI, 'value')
                mergeOption = '--merge';
                return;
            end
            mergeOption = '';
        end%getStmsMergeOption
        
        function overlayOption = getOverlayOption(obj)
            overlayOptionList = get(obj.overlayOptionUIStruct.popup, 'String');
            overlayOption = char(overlayOptionList(get( obj.overlayOptionUIStruct.popup, 'Value')));
        end%overlayOptionUI
        
        function eraseOption = getEraseOption(obj)
            if get(obj.eraseOptionUI, 'value')
                eraseOption = true;
                return;
            end
            eraseOption = false;
        end%getEraseOption
        
        function roiFilterTab = getRoiFilterTab(obj)
            roiFilterStr = get(obj.roiSelectionUIStruct.editBox, 'string');
            switch roiFilterStr
                case 'all'
                    roiFilterTab = -1;
                otherwise
                    splitBlockList = strsplit(roiFilterStr,';');
                    cpt = 1;
                    for k = 1 : length(splitBlockList)
                        if length(strfind(char(splitBlockList(k)), '-')) > 0
                            tmp = str2num(char(strsplit(char(splitBlockList(k)),'-')));
                            for l = tmp(1) : tmp(2)
                                roiFilterTab(cpt) = l; cpt = cpt + 1;
                            end
                        else
                            roiFilterTab(cpt) = str2num(char(splitBlockList(k)));
                            cpt = cpt + 1;
                        end
                    end
            end
        end
        
        function thresholdType = getThresholdType(obj)
            thresholdTypeList = get(obj.thresholdTypeUIStruct.popup, 'String');
            thresholdType = char(thresholdTypeList(get( obj.thresholdTypeUIStruct.popup, 'Value')));
        end%getThresholdType
    end
    
end

