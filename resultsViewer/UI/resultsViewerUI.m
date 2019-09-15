classdef resultsViewerUI < maskOverlayBaseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        datasetPathUITab;
        slcList;
        modeChoiceUI;
        parameterChoiceUI;
        maxVisibleValUIHdleList;
        
        ctcSetMapDS1;
        fitCtcSetMapDS1;
        ctcSetMapDS2;
        fitCtcSetMapDS2;
        
        peakImgDS1Map;% peak image dataset 1
        peakImgDS2Map;% peak image dataset 2
        
        imSerieMap;
        
        overlayImageStackDS1;% overlay image stack dataset 1
        overlayImageStackDS2;% overlay image stack dataset 2
        
        handleImgTab;
        
        aifCtc;
        
        dataVisuTool;
        framePos;
    end
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = resultsViewerUI;
            end
            obj = localObj;
        end
    end
    %% public methods
    methods (Access = public)
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.setDatasetsPathsUI();
            obj = obj.setModeChoiceUI();
            obj = obj.setParameterMapChoiceUI();
            obj = obj.setMaxVisibleValueSlider();
%             obj = obj.setSavePathUI([obj.basePath 'resultsComparator\']);
            obj.updateSavePath('resultsComparator');
            obj.framePos = 10;
        end% initialize
    end
    %% protected methods
        methods (Access = protected)
            function obj = goCb(obj, src, ~)
                obj.handleAxesTab = [];
                delete(get(obj.rPanel,'Children'));
                
                obj.setFooterStr('running');
                figureMgr.getInstance().closeAllBut('deconvTool');
                obj = obj.checkPathes();
                
                obj = obj.loadAifCtc();
                obj = obj.loadCtcSetMaps();
                
                switch obj.getMode()
                    case 'Bland_Altman'
                        obj = obj.loadPeakImage();
                        obj = obj.processBlandAltman();
                    case 'overlay'
                      %  obj = obj.loadPeakImage();
                        obj.loadImSeries();
                        obj.dispResults();
                        set(obj.maxVisibleValUIHdleList.caption, 'Visible', 'on');
                        set(obj.maxVisibleValUIHdleList.slider, 'Visible', 'on');
                        set(obj.maxVisibleValUIHdleList.editBoxVal, 'Visible', 'on');
                        set(obj.maxVisibleValUIHdleList.unit, 'Visible', 'on');
                    case 'histogram'
                        opt.path = obj.getDataSetPath(1);
                        opt.parameterName = obj.getParameterChoice();
                        switch  opt.parameterName
                            case 'delayMap'
                                opt.step = 0.5;
                            otherwise
                                opt.step = 0.2;
                        end
                        opt.contrast = obj.histOpt.contrast;
                        opt.brightness = obj.histOpt.brightness;
                        obj.dataVisuTool = paramHistogramViewerTool();
                        obj.dataVisuTool.prepare(opt);
                        obj.dataVisuTool.run();
                end
                obj.setFooterStr('completed!');
            end%goCb
            
            function obj = saveCb(obj, ~, ~)
                switch obj.getMode()
                    case 'Bland_Altman'
                        msgbox('TBD')
                    case 'overlay'
                        savePath = fullfile(obj.getSavePath(), obj.getMethod(1));
                        if ~isdir(savePath); mkdir(savePath); end
                        %figureMgr.getInstance().saveAllBut(savePath, 'deconvTool');
                        for k = 1 : length(obj.slcList)
                            imwrite(frame2im(getframe(obj.handleAxesTab(2 * k - 1))), [savePath '\' char(obj.slcList(k)) '_rest.png']);
                            imwrite(frame2im(getframe(obj.handleAxesTab(2 * k))), [savePath '\' char(obj.slcList(k)) '_stress.png']);
                            xlim = get(obj.handleAxesTab(2 * k - 1), 'XLim'); ylim = get(obj.handleAxesTab(2 * k - 1), 'YLim');
                            subImg = obj.peakImgDS1Map(char(obj.slcList(k)));
                            subImg = obj.correctImage(subImg(ylim(1) : ylim(2), xlim(1) : xlim(2)));
                            minVal = min(subImg(:)); maxVal = max(subImg(:));
                            subImg = (subImg - minVal) ./ (maxVal - minVal);
                            imwrite(subImg , [savePath '\' char(obj.slcList(k)) '_noMap.png']);
                        end
                        obj.setFooterStr(sprintf('save successful in : %s', savePath));
                    case 'histogram'
                        opt.paramMapName = obj.getParameterChoice();
                        if 0 ~= obj.dataVisuTool.save(obj.getSavePath(), opt)
                            obj.setFooterStr('x_x save failure');
                        else
                            obj.setFooterStr('save completed');
                        end
                end
                
            end%saveCb
            
            function obj = onImgBnClickCb(obj, arg1, arg2)
                axesHandle  = get(arg1, 'Parent');
                coordinates = get(axesHandle, 'CurrentPoint');
                coordinates = floor(coordinates(1, 1:2));
                if ~coordinates(1); coordinates(1) = 1; end
                if ~coordinates(2); coordinates(2) = 1; end
                
                imhdlePos = find(obj.handleImgTab == arg1);
                obj.setFooterStr(sprintf('clicked on voxel(%d,%d)', coordinates(2), coordinates(1)));
                %rest or stress?
                if ~mod(imhdlePos, 2);
                    ctcSetMap = obj.ctcSetMapDS2;
                    fitctcSetMap = obj.fitCtcSetMapDS2;
                else
                    ctcSetMap = obj.ctcSetMapDS1;
                    fitctcSetMap = obj.fitCtcSetMapDS1;
                end
                %which slice?
                slcIdx = floor((imhdlePos + 1) / 2);
                
                ctcSet = ctcSetMap(char(obj.slcList(slcIdx)));
                try
                    fitctcSet = fitctcSetMap(char(obj.slcList(slcIdx)));
                catch
                    disp('resultComparator:onImgBnClickCb could not load fitctcSet');
                    fitctcSet = zeros(size(ctcSet));
                end
                figureMgr.getInstance().newFig('ctc');
                plot(obj.aifCtc, 'o', 'color', [0 127 0] ./ 256); 
                plot(squeeze(ctcSet(coordinates(2), coordinates(1), :)), 'o', 'linewidth', 1); hold all;
                plot(squeeze(fitctcSet(coordinates(2), coordinates(1), :)), '-')
                xlabel('heart beat'); ylabel('[Gd](mol/L)');
                legend('ctc' , 'fitted ctc');
            end %onImgBnClickCb
            
            function retVal = dispResults(obj)
                retVal = 0;
                %delete(get(obj.rPanel,'Children'));
                if isempty(obj.handleAxesTab)
                    obj.handleAxesTab = tight_subplot(3,2,[.05 .03],[.01 .01],[.01 .01], obj.rPanel);
                end
                if ~strcmp('none', obj.getParameterChoice())
                    obj.handleImgTab = zeros(1, 2 * length(obj.slcList));
                    [restMap, stressMap] = obj.prepareOverlayMaps();
                end
                
                obj.overlayImageStackDS1 = [];
                obj.overlayImageStackDS2 = [];
                for k = 1 : length(obj.slcList)
                    if ~strcmp('none', obj.getParameterChoice())
                        %Rest
                        stackPos = 3 * (k - 1) + 1;
                        [obj.overlayImageStackDS1(:, :, stackPos : stackPos + 2), scale] = overlay(obj.correctImage(obj.peakImgDS1Map(char(obj.slcList(k)))),...
                            restMap(char(obj.slcList(k))));
                        axes(obj.handleAxesTab(2 * k - 1));
                        obj.handleImgTab(2 * k - 1) = obj.dispMap(obj.overlayImageStackDS1(:, :, stackPos : stackPos + 2), scale, [obj.getParameterChoice() ' map ' char(obj.slcList(k)) ' rest (ml/g/min)']); axis image;
                        set(obj.handleImgTab(2 * k - 1),  'ButtonDownFcn', @obj.onImgBnClickCb);
                        mask = restMap(char(obj.slcList(k))); mask(1,1) = 0;
                        obj.optimizeFocus(obj.handleAxesTab(2 * k - 1), mask);
                        %obj.setText('dataset 1', char(obj.slcList(k)));
                        %Stress
                        [obj.overlayImageStackDS2(:, :, stackPos : stackPos + 2), scale] = overlay(obj.correctImage(obj.peakImgDS2Map(char(obj.slcList(k)))),...
                            stressMap(char(obj.slcList(k))));
                        axes(obj.handleAxesTab(2 * k));
                        obj.handleImgTab(2 * k) = obj.dispMap(obj.overlayImageStackDS2(:, :, stackPos : stackPos + 2), scale, [obj.getParameterChoice() ' map ' char(obj.slcList(k)) ' stress (ml/g/min)']); axis image;
                        set(obj.handleImgTab(2 * k),  'ButtonDownFcn', @obj.onImgBnClickCb);
                        mask = stressMap(char(obj.slcList(k))); mask(1,1) = 0;
                        obj.optimizeFocus(obj.handleAxesTab(2 * k), mask);
                        obj.setText('dataset 2', char(obj.slcList(k)));
                    else
                        axes(obj.handleAxesTab(2 * k - 1));
                        imagesc(obj.correctImage(obj.peakImgDS1Map(char(obj.slcList(k))))); axis off image; colormap gray;
                        mask = loadmat(fullfile(obj.getDataSetPath(1), char(obj.slcList(k)), 'mbfMap'));
                        obj.optimizeFocus(obj.handleAxesTab(2 * k - 1), mask);
                        axes(obj.handleAxesTab(2 * k));
                        imagesc(obj.correctImage(obj.peakImgDS2Map(char(obj.slcList(k))))); axis off image; colormap gray;
                        mask = loadmat(fullfile(obj.getDataSetPath(1), char(obj.slcList(k)), 'mbfMap'));
                        obj.optimizeFocus(obj.handleAxesTab(2 * k), mask);
                    end
                end
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb});
                try
                    mapStack = obj.loadRoiMaps();
                    %obj.plotRoiBounds(mapStack);
                    dcm_obj = datacursormode(figureMgr.getInstance().getFig('deconvTool'));
                    set(dcm_obj, 'UpdateFcn', {@resCompDataTipCb, obj.paramMap2Stack(restMap, stressMap), mapStack, obj.handleAxesTab});
                catch
                    cprintf('orange', 'resultsViewerUI:dispResults: exception thrown while managing roi maps\n');
                    obj.setFooterStr('resultsViewerUI:dispResults: exception thrown while managing roi maps');
                    retVal = -1;
                end
            end%dispResults
            
            function [overlayMapRest, overlayMapStress] = prepareOverlayMaps(obj)
                
                [overlayMapRest, overlayMapStress] = obj.getOverlayMaps();
                minVal = Inf;
                maxVal = -Inf;
                % search global min val and max val 
                for k = 1 : length(obj.slcList)
                    slcOverlayRest = overlayMapRest(char(obj.slcList(k)));
                    slcOverlayStress = overlayMapStress(char(obj.slcList(k)));
                    slcMinVal = min(min(slcOverlayRest(:)), min(slcOverlayStress(:)));
                    slcMaxVal = max(max(slcOverlayRest(:)), max(slcOverlayStress(:)));
                    if slcMinVal < minVal
                        minVal = slcMinVal;
                    end
                    if slcMaxVal > maxVal
                        maxVal = slcMaxVal;
                    end
                end
                obj.setMaxVisibleValueSliderInterval(minVal, maxVal);
                maxParamVal = obj.getmaxParamVal();
                
                for k = 1 : length(obj.slcList)% force the map to go from min to max mbf value
                    slcOverlayRest = overlayMapRest(char(obj.slcList(k)));
                    slcOverlayStress = overlayMapStress(char(obj.slcList(k)));
                    
                    posToZero = find(slcOverlayRest > maxParamVal);
                    slcOverlayRest(posToZero) = 0;
                    slcOverlayRest(1,1) = obj.getmaxParamVal();
                    
                    posToZero = find(slcOverlayStress > maxParamVal);
                    slcOverlayStress(posToZero) = 0;
                    slcOverlayStress(1,1) = obj.getmaxParamVal();
                    
                    overlayMapRest(char(obj.slcList(k))) = slcOverlayRest;
                    overlayMapStress(char(obj.slcList(k))) = slcOverlayStress;
                end
            end%prepareOverlayMaps
            
            function [overlayMapRest, overlayMapStress] = getOverlayMaps(obj)
                overlayMapRest =   obj.loadMap(obj.getDataSetPath(1), [obj.getParameterChoice() '.mat']);
                overlayMapStress = obj.loadMap(obj.getDataSetPath(2), [obj.getParameterChoice() '.mat']);
            end%getOverlayMap
            
            function imHdle = dispMap(obj, map, colorbarRge, titleStr)
                imHdle = imagesc(map);
                colorbar('YColor', [1 1 1]); caxis(colorbarRge);
                axis off; %title(titleStr, 'fontsize', 8);
            end%dispMap
            
            function plotRoiBounds(obj, roiMapsStack)
                for k = 1 : size(roiMapsStack, 3)
                    curRoiMap = roiMapsStack(:, :, k);
                    [B, ~] = bwboundaries(curRoiMap, 'noholes');
                    axes(obj.handleAxesTab(k)); hold on;
                    cmap = [1 0 0; 0 1 0; 0 0 1];
                    for l = 1 : length(B)
                        boundary = B{l};
                        plot(boundary(:, 2), boundary(:, 1), 'w', 'LineWidth', 2, 'color', cmap(l, :));
                    end
                end
            end%plotRoiBounds
            
            function obj = checkPathes(obj)
                obj.slcList = {}; cpt = 1; 
                if isdir([obj.getDataSetPath(1) '/' 'base']); obj.slcList(cpt) = {'base'}; cpt = cpt + 1; end
                if isdir([obj.getDataSetPath(1) '/' 'mid']); obj.slcList(cpt) = {'mid'}; cpt = cpt + 1; end
                if isdir([obj.getDataSetPath(1) '/' 'apex']); obj.slcList(cpt) = {'apex'}; end
                
                for k = 1 : length(obj.slcList)
                    if ~isdir([obj.getDataSetPath(2) '/' char(obj.slcList(k))])
                        throw(MException('resultsComparatorUI:checkPathes', 'slices folder do not match'));
                    end
                end
            end%checkPathes
            
            function obj = loadAifCtc(obj)
                %D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\Boncompain\dataPrep\Aif
                %D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\Boncompain\deconvolution\Bayesian
                obj.aifCtc = loadmat(fullfile(fileparts(fileparts(obj.getDataSetPath(1))), 'dataPrep', 'Aif', 'aifCtc.mat'));
            end
            
            function obj = loadPeakImage(obj)
%                 try
                    for k = 1 : length(obj.slcList)
                        dcmPath = fileparts(fileparts(obj.getDataSetPath(1)));
                        imStack = loadDcm(fullfile(dcmPath, char(obj.slcList(k))));
                        peakPos = selectPeakImage(imStack);
                        obj.peakImgDS1Map = mapInsert(obj.peakImgDS1Map, char(obj.slcList(k)), imStack(:, :, peakPos));
                        obj.peakImgDS2Map = mapInsert(obj.peakImgDS2Map, char(obj.slcList(k)), imStack(:, :, peakPos));
                    end
%                 catch
%                     for k = 1 : length(obj.slcList)
%                         % peak image
%                         obj.peakImgDS1Map = obj.loadMap(obj.getDataSetPath(1), 'peakImage.mat');
%                         obj.peakImgDS2Map = obj.loadMap(obj.getDataSetPath(2), 'peakImage.mat');
%                     end
%                 end
            end%loadPeakImage
            
            function setPeakImg(obj)
                for k = 1 : length(obj.slcList)
                    imSerie  = obj.imSerieMap(char(obj.slcList(k))); 
                    obj.peakImgDS1Map(char(obj.slcList(k))) = imSerie(:, :, obj.framePos);
                    obj.peakImgDS2Map(char(obj.slcList(k))) = imSerie(:, :, obj.framePos);
                end
            end
            
            function obj = loadImSeries(obj)
                
                dcmPath = fileparts(fileparts(obj.getDataSetPath(1)));
                for k = 1 : length(obj.slcList)
                    imSerie = loadDcm(fullfile(dcmPath, char(obj.slcList(k))));
                    obj.imSerieMap = mapInsert(obj.imSerieMap, char(obj.slcList(k)), imSerie);
                    obj.peakImgDS1Map = mapInsert(obj.peakImgDS1Map, char(obj.slcList(k)), imSerie(:, :, obj.framePos));
                    obj.peakImgDS2Map = mapInsert(obj.peakImgDS2Map, char(obj.slcList(k)), imSerie(:, :, obj.framePos));
                end
            end%loadImSeries
            
            function obj = loadCtcSetMaps(obj)
                try
                obj.ctcSetMapDS1 = obj.loadMap(obj.getDataSetPath(1), 'ctcSet.mat');
                obj.ctcSetMapDS2 = obj.loadMap(obj.getDataSetPath(2), 'ctcSet.mat');
                catch
                    disp('resultComparator:loadCtcSetMaps, could not load ctcSet');
                end
                try
                obj.fitCtcSetMapDS1 = obj.loadMap(obj.getDataSetPath(1), 'fitCtcSet.mat');
                obj.fitCtcSetMapDS2 = obj.loadMap(obj.getDataSetPath(2), 'fitCtcSet.mat');
                catch
                    disp('resultComparator:loadCtcSetMaps, could not load fitCtcSet');
                end
            end%loadCtcSetMaps
            
            function map = loadMap(obj, path, matName)
                map = [];
                for k = 1 : length(obj.slcList)
                    mat = loadmat([path '\' char(obj.slcList(k)) '\' matName]);
                    if ~isa(map, 'containers.Map')% create map if does not exists
                        map = containers.Map(char(obj.slcList(k)), mat) ;
                    else % else insert into map
                        map(char(obj.slcList(k))) = mat;
                    end
                end
            end%loadMap
            
            function restStressRoiMapStack = loadRoiMaps(obj)
                restRoiRootPath = fullfile(fileparts(fileparts(obj.getDataSetPath(1))), 'segmentation');
                stressRoiRootPath = fullfile(fileparts(fileparts(obj.getDataSetPath(2))), 'segmentation'); 
                for k = 1 : length(obj.slcList)
%                     normalRestRoi = 2 .* loadmat(fullfile(normalRestRoiRootPath, ['firstRoiMask_' char(obj.slcList(k)) '.mat']));
%                     lesionRestRoi = loadmat(fullfile(lesionRestRoiRootPath, char(obj.slcList(k)), 'labeledImg001.mat'));
                    restRoiMapStack(:, :, k) = loadmat(fullfile(restRoiRootPath, 'ManualMultiRoiMapDisplay', ['labelsMask_' char(obj.slcList(k)) '.mat']));
                    
%                     normalStressRoi = 2 .* loadmat(fullfile(normalStressRoiRootPath, char(obj.slcList(k)), 'labeledImg001.mat'));
%                     lesionStressRoi = loadmat(fullfile(lesionStressRoiRootPath, char(obj.slcList(k)), 'labeledImg001.mat'));
                    stressRoiMapStack(:, :, k) = loadmat(fullfile(stressRoiRootPath, 'ManualMultiRoiMapDisplay', ['labelsMask_' char(obj.slcList(k)) '.mat']));
                end
                %organize stress and rest maps in one stack in agreement
                %with axes (rest_base, stress_base, rest_mid,
                %stress_mid...
                [H, W] = size(stressRoiMapStack(:, :, 1));
                
                restStressRoiMapStack = zeros(H, W, 2 * length(obj.slcList));
                restStressRoiMapStack(:, :, 1 : 2 : end) = restRoiMapStack;
                restStressRoiMapStack(:, :, 2 : 2 : end) = stressRoiMapStack;
                
            end%loadRoiMaps
            
            function obj = processBlandAltman(obj)
                
                [restMap stressMap] = obj.getOverlayMaps();
                %[H, W, SLC] = size( obj.mbfStackMeth1); 
                
                for k = 1 : length(obj.slcList)
                    data1 = restMap(char(obj.slcList(k)));
                    data2 = stressMap(char(obj.slcList(k)));
                    
                    fm = figureMgr.getInstance();
                    label = {obj.getMethod(1), obj.getMethod(2), 'ml/g/min'}; % Names of data sets
                    corrinfo = {'n','SSE','r2','eq'}; % stats to display of correlation scatter plot
                    BAinfo = {'RPC(%)'}; % stats to display on Bland-ALtman plot
                    limits = 'auto'; % how to set the axes limits
                    gnames = obj.slcList(k); % names of groups in data
                    [~, figHdl, baResults] = BlandAltman(data1(:), data2(:), label,...
                        [obj.getMethod(1) ' vs ' obj.getMethod(2)], gnames, ...
                        corrinfo, BAinfo, limits, 'brg', '');
                    set(figHdl, 'Name', [obj.getParameterChoice() char(obj.slcList(k))]);
                    fm.addFig(figHdl);
                    
                end
            end%processBlandAlman
            
            function obj = modeChoiceCb(obj, ~, ~)
                switch obj.getMode()
                    case 'Bland_Altman'
                        %set(obj.datasetPathUITab(1), 'String', [obj.basePath 'deconvolution\Patients\ARBANE\stress\Bayesian\']);
                        %set(obj.datasetPathUITab(2), 'String', [obj.basePath 'deconvolution\Patients\ARBANE\stress\BayesianParallel\']);
                        set(obj.maxVisibleValUIHdleList.caption, 'Visible', 'off');
                        set(obj.maxVisibleValUIHdleList.slider, 'Visible', 'off');
                        set(obj.maxVisibleValUIHdleList.editBoxVal, 'Visible', 'off');
                        set(obj.maxVisibleValUIHdleList.unit, 'Visible', 'off');
                    case 'overlay'
                        %set(obj.datasetPathUITab(1), 'String', [obj.basePath 'deconvolution\Patients\ARBANE\rest\BayesianParallel']);
                        %set(obj.datasetPathUITab(2), 'String', [obj.basePath 'deconvolution\Patients\ARBANE\stress\BayesianParallel']);
                end
            end%modeChoiceCb
            
            function obj = sldrCb(obj, ~, ~)
                val = get(obj.maxVisibleValUIHdleList.slider, 'Value');
                set(obj.maxVisibleValUIHdleList.editBoxVal, 'String', val);
            end%sldrCb
            
            function obj = paramChoiceCb(obj, ~, ~)
                obj.updateSavePath();
            end%paramChoiceCb
            
            function obj = eBoxMaxValCb(obj, ~, ~)
                val = str2double(get(obj.maxVisibleValUIHdleList.editBoxVal, 'String'));
                set(obj.maxVisibleValUIHdleList.slider, 'Value', val);
            end%eBoxMaxValCb
            
            function updateSavePath(obj, ~, ~, folderName)
                set(obj.savePathUI, 'String', fullfile(fileparts(fileparts(obj.getDataSetPath(1))), 'resultViewer', obj.getParameterChoice()));
            end%updateSavePath
            
            function paramStack = paramMap2Stack(obj, restMap, stressMap)
                for k = 1 : length(obj.slcList)
                    paramStack(:, :, 2 * (k - 1) + 1) = restMap(char(obj.slcList(k)));
                    paramStack(:, :, 2 * k) = stressMap(char(obj.slcList(k)));
                end
            end%paramMap2Stack
            
            function onScrollCb(obj, ~, arg2)
                set(gcf, 'WindowScrollWheelFcn', '');
                imSerie = obj.imSerieMap(char(obj.slcList(1)));
                obj.framePos = floor(obj.framePos  + arg2.VerticalScrollCount);
                if obj.framePos < 1
                    obj.framePos = 1;
                    set(gcf, 'WindowScrollWheelFcn', @obj.onScrollCb);
                    return;
                end
                if obj.framePos > size(imSerie, 3)
                    obj.framePos = size(imSerie, 3);
                    set(gcf, 'WindowScrollWheelFcn', @obj.onScrollCb);
                    return;
                end
                obj.setPeakImg();
                obj.dispResults();
                %set(gcf, 'WindowScrollWheelFcn', @obj.onScrollCb);
            end%onScrollCb
            
            function onKeyPressCb(obj, arg1, arg2)
                obj.onKeyPressCb@baseUI(arg1, arg2);
                obj.dispResults();
            end%onKeyPressCb
            
            function setText(obj, dataSetName, slcName)
                 text('units', 'normalized', 'position', [0.2, 0.05], 'fontsize', 10,...
                'color', 'white', 'string', ...
                sprintf('%s | %s, %d/%d', dataSetName, slcName, obj.framePos, size(obj.imSerieMap(slcName), 3)));
            end%setText

        end
        %% private methods
    methods (Access = private)
        %setters
        function obj = setDatasetsPathsUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 4) 0.1 obj.HdleHeight],...
                'String', 'Path dataset 1');
            %edit box
            obj.datasetPathUITab(1) = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', obj.basePath ,...
                'Position', [obj.col(2) obj.lin(end - 4) 0.5 obj.HdleHeight], ...
                'Callback', @obj.updateSavePath);
            
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 3) 0.1 obj.HdleHeight],...
                'String', 'Path dataset 2');
            %edit box
            obj.datasetPathUITab(2) = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', obj.basePath,...
                'Position', [obj.col(2) obj.lin(end - 3) 0.5 obj.HdleHeight]);
        end%setDatasetsPathsUI
        
        function updateMethodPathCb(obj, arg1, ~, method)
            disp('to be done');
%             switch method
%                 case 'meth1'
%                     set(obj.datasetPathUITab(2), 'String', );
%                 case 'meth2'
%                     set(obj.datasetPathUITab(1), 'String');
%             end
%             end%switch
            
        end%updateMethodPathCb
        
        function obj = setModeChoiceUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 8) 0.1 obj.HdleHeight],...
                'String', 'comparison mode');
            
            %mode choose box
            obj.modeChoiceUI = uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(end - 8) 0.4 obj.HdleHeight],...
                'String', {'Bland_Altman', 'overlay', 'histogram'});
            set(obj.modeChoiceUI, 'Callback', @obj.modeChoiceCb);
        end%modeChoiceUI
        
        function obj = setParameterMapChoiceUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 7) 0.1 obj.HdleHeight],...
                'String', 'parameter');
            %mode choose box
            obj.parameterChoiceUI = uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(end - 7) 0.4 obj.HdleHeight],...
                'String', {'mbfMap', 'mbvMap', 'ttpMap', 'delayMap', 'mbfUncertaintyMap', 'baselineSigmaMap', 'baselineAvgMap', 'baselineLengthMap', 'labeledImg','none'});
            set(obj.parameterChoiceUI, 'Callback', @obj.paramChoiceCb);
        end%setParameterMapChoiceUI
        
        function obj = setMaxVisibleValueSlider(obj)
            initVal = 4;
            % texbox
            obj.maxVisibleValUIHdleList.caption = uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 5) 0.1 0.05],...
                'String', 'max visible value',...
                'Visible', 'off');
            %slider
            obj.maxVisibleValUIHdleList.slider = ...
                uicontrol(obj.lPanel, 'Style', 'slider',...
                'Units',  'normalized',...
                'Value', initVal,...
                'Min', 0, ...
                'Max', 100, ...
                'Position', [obj.col(2) obj.lin(end - 5) 0.35 0.05],...
                'Callback', @obj.sldrCb,...
                'Visible', 'off');
            %edit box
            obj.maxVisibleValUIHdleList.editBoxVal = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', num2str(initVal),...
                'Position', [obj.col(6) obj.lin(end - 5) 0.1 0.05], ...
                'Callback', @obj.eBoxMaxValCb,...
                'Visible', 'off');
            
            % units
            
            obj.maxVisibleValUIHdleList.unit = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(8) obj.lin(end - 5) 0.1 0.05],...
                'String', 'A.U',...
                'Visible', 'off');
            
        end% setMaxVisibleValueSlider
        
        function obj = setMaxVisibleValueSliderInterval(obj, minVal, maxVal)
            currentVal = get(obj.maxVisibleValUIHdleList.slider, 'value');
            set(obj.maxVisibleValUIHdleList.slider, 'min', minVal, 'max', maxVal);
            if (currentVal < minVal) || (currentVal > maxVal)
                set(obj.maxVisibleValUIHdleList.slider, 'value', maxVal);
                set(obj.maxVisibleValUIHdleList.editBoxVal, 'string', num2str(maxVal));
            end
        end %setMaxVisibleValueSlider
        
        %getters
        function datasetPath = getDataSetPath(obj, idx)
            datasetPath = get(obj.datasetPathUITab(idx), 'String');
        end%getDataSetPath
        
        function method = getMethod(obj, idx)
            path = obj.getDataSetPath(idx);
            if path(end) == '\'; path = path(1:end - 1); end
            [~, method] = fileparts(path);
        end%getMethod
        
        function val = getmaxParamVal(obj)
            val = str2double(get(obj.maxVisibleValUIHdleList.editBoxVal, 'String'));
        end%getmaxParamVal
        
        function mode = getMode(obj)
            modeList = get(obj.modeChoiceUI, 'String');
            val = get(obj.modeChoiceUI, 'Value');
            mode = char(modeList(val));
        end% getMode
        
        function param = getParameterChoice(obj)
            paramList = get(obj.parameterChoiceUI, 'String');
            val = get(obj.parameterChoiceUI, 'Value');
            param = char(paramList(val));
        end% getParameterChoice
    end
end

