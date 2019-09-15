classdef myoMaskEditorUI < imSeriesUI & maskOverlayBaseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = protected)
        imgSeriesTool;
        obj
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = myoMaskEditorUI;
            end
            obj = localObj;
        end
    end%methods (Static)

    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', 'patientName', 'example'));
            obj.boundsDisplayMode = 'off';
        end%initialize
        %%
        
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function goCb(obj, ~, ~)
            clc
            obj.wipeResults();
            obj.setFooterStr('starting run');
            try
                obj.imgSeriesTool = myoMaskEditorImSerieTool();
                opt.dataPath = obj.getDataPath();
                obj.imgSeriesTool = obj.imgSeriesTool.prepare(opt);
                obj.imgSeriesTool = obj.imgSeriesTool.run();
                obj.dispResults();
            catch e
                obj.setFooterStr('something bad happened x_x');
                rethrow(e);
            end
            obj.setFooterStr('run completed successfully');
        end%goCb(obj)
        %%
        function saveCb(obj)
        end%saveCb(obj)
        %%
        function dispResults(obj)
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(2, 2, [.05 .05], [.05 .05], [.1 .01], obj.rPanel);
                set(obj.handleAxesTab(4), 'color', 'k');
            end
             isKS = obj.imgSeriesTool.getSeriesKS(); %im series names
             for k = 1 : length(isKS)
                 isName = char(isKS(k));
                 axes(obj.handleAxesTab(k));
                 slcSerie = obj.imgSeriesTool.getImserie(isName);
                 h = imagesc(obj.correctImage(slcSerie(:, :, obj.slcTimePos)));
                 obj.displayMyoBoundaries(isName, obj.handleAxesTab(k));
                 colormap gray; axis off image;
                 obj.optimizeFocus(obj.handleAxesTab(k), obj.imgSeriesTool.getMyoMask(isName));
                 text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d', isName, obj.slcTimePos, size(slcSerie, 3)));
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(slcSerie, 3)});
                set(h, 'ButtonDownFcn', {@obj.onImgClick, isName});
             end
        end%dispResults
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            obj.dispResults();
        end
        %%
        function [x, y] = onImgClick(obj, arg1, arg2, isName)
            [x, y] = obj.onImgClick@imSeriesUI(arg1, arg2, isName);
            switch obj.maskEditMode
                case 'eraser'
                    opt.slcName = isName;
                    obj.startMaskEditCb(obj.imgSeriesTool.getMyoMask(isName), opt);
            end
        end
        
        %%
        function displayMyoBoundaries(obj, isName, axisHdle)
            if nargin == 2
                axisHdle = gca;
            end
            bnds = obj.processMaskBounds(obj.imgSeriesTool.getMyoMask(isName));
            obj.boundariesPlot(bnds{2}, [1 0 0], axisHdle, 2);
            obj.boundariesPlot(bnds{1}, [0 1 0], axisHdle, 2);
        end%displayMyoBoundaries
        
                %% mask edit
        %%
        function [mask, x, y] = maskEditCb(obj, arg1, ~, opt)
            mask = obj.maskEditCb@maskOverlayBaseUI(arg1, [], opt);
            if ~isnan(mask)
                mask(mask > 0) = 1;
                oldMask = obj.imgSeriesTool.getMyoMask(opt.slcName);
                oldMask(oldMask > 0) = 1;
                maskDiff = abs(oldMask - mask);
                myoMask = obj.imgSeriesTool.getMyoMask(opt.slcName);
                myoMask(maskDiff == 1) = 0;
                obj.imgSeriesTool.updateMyoMask(opt.slcName, myoMask);
            end
            axes(gca);
            imagesc(mask);
            axis off image;
            obj.optimizeFocus(gca, mask);
        end
        %%
        function stopMaskEditCb(obj, ~, ~, opt)
            obj.stopMaskEditCb@maskOverlayBaseUI();
            obj.dispResults();
        end%stopMaskEdit
        %%
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = obj.onKeyPressCb@baseUI([], arg);
            if validKey
                obj.displayMapOverlay();
                return;
            end
            prevMode = obj.maskEditMode;
            validKey = obj.onKeyPressCb@maskOverlayBaseUI([], arg);
            if strcmp('none', obj.maskEditMode) && ...
                    (strcmp('eraser', prevMode) || strcmp('pencil', prevMode))
                obj.imgSeriesTool.saveMyoMaskUpdate();
            end
        end
    end%methods (Access = protected)
    
end

