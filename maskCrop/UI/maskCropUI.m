classdef maskCropUI < baseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        cropTool;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = maskCropUI;
            end
            obj = localObj;
        end
    end%methods (Static)
    
    methods (Access = public)
        
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', '02_CHUSE'));
        end
    end%methods (Access = public)
    
    
    methods (Access = protected)
        %
        function obj = goCb(obj, ~, ~)
            clc;
            obj.wipeResults();
            figureMgr.getInstance().closeAllBut('deconvTool');
            obj.cropTool = maskCropTool;
            toolOpt.inputDataRootPath = obj.getDataPath();
            toolOpt.maskName = 'roisMask';
            obj.cropTool.prepare(toolOpt);
            obj.cropTool.run()
            obj.dispResults();
        end%goCb
        %
        function obj = saveCb(obj, ~, ~)
            savemat(fullfile(obj.getDataPath(), ['cropped_' obj.cropTool.getMaskName()]), obj.cropTool.getCroppedMask);
        end
        %
        function obj = dispResults(obj)
            
            obj.handleAxesTab = tight_subplot(1, 2, [.05 .05], [.01 .01], [.01 .01], obj.rPanel);
            axes(obj.handleAxesTab(1));
            imagesc(obj.cropTool.getMask()); axis off image;
            axes(obj.handleAxesTab(2));
            imagesc(obj.cropTool.getCroppedMask()); axis off image;
        end
    end%methods (Access = protected)
end

