classdef myoSegmentationViewerUI < imSeriesUI & maskOverlayBaseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = protected)
        myoSegVrTool;
        viewNum;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = myoSegmentationViewerUI;
            end
            obj = localObj;
        end
    end%methods (Static)

    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', 'patientName', 'example'));
            obj.viewNum = 1;
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
                obj.myoSegVrTool = myoSegmentationViewerTool();
                opt.dataPath = obj.getDataPath();
                obj.myoSegVrTool = obj.myoSegVrTool.prepare(opt);
                obj.myoSegVrTool = obj.myoSegVrTool.run();
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
                obj.handleAxesTab = tight_subplot(1, 1, [.05 .05], [.05 .05], [.1 .01], obj.rPanel);
            end
            
            
            slcSerie = obj.myoSegVrTool.getImserie();
            imagesc(obj.correctImage(slcSerie(:, :, obj.viewNum, obj.slcTimePos)));
            mask = obj.myoSegVrTool.getMask('myoMask');
            text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
             'color', 'white', 'string', sprintf('%d/%d', obj.slcTimePos, size(slcSerie, 4)));
            set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(slcSerie, 4)});
            colormap gray; axis off image;
            
            if max(max(mask(:, :, obj.viewNum, obj.slcTimePos))) ~= 0
                obj.optimizeFocus(obj.handleAxesTab, mask(:, :, obj.viewNum, obj.slcTimePos));
                obj.displayBoundaries(mask(:, :, obj.viewNum, obj.slcTimePos));
            end
        end%dispResults
        
        function displayBoundaries(obj, mask)
            if nargin == 2
                axisHdle = gca;
            end
            bnds = obj.processMaskBounds(mask);
            try
                obj.boundariesPlot(bnds{1}, [0 1 0], axisHdle, 2);
                obj.boundariesPlot(bnds{2}, [1 0 0], axisHdle, 2);
            catch e
                if strcmp(e.message, 'Index exceeds matrix dimensions.')
                    obj.lgr.err('could not display segmentation results correctly')
                end
            end
        end%displayMyoBoundaries
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            obj.dispResults();
        end
        
        
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = obj.onKeyPressCb@baseUI([], arg);
            if validKey
                return;
            end
            try
                obj.viewNum = str2num(arg.key);
            catch
                switch arg.Key
                    case 'add'
                        if obj.viewNum < 11
                            obj.viewNum = obj.viewNum + 1;
                        end
                    case 'subtract'
                        if obj.viewNum > 0
                            obj.viewNum = obj.viewNum - 1;
                        end
                end
            end
            obj.setFooterStr(sprintf('viewNum: %d', obj.viewNum));
            validKey = true;
        end

    end%methods (Access = protected)
    
end

