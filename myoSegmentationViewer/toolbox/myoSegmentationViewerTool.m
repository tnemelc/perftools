classdef myoSegmentationViewerTool < cPerfImSerieTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        imSerie;
        myoMask;
        rvBloodPoolMask;
        lvBloodPoolMask;
    end
    
    methods (Access = public)
        function obj = run(obj, ~)
            obj = obj.run@cPerfImSerieTool();
            obj = obj.loadMasks();
        end
    end
    
    methods (Access = protected)
        function obj = loadMasks(obj)
             masks = readnifti(fullfile(obj.dataPath, 'seg_sa.nii'));
             %LV myocardium
             obj.myoMask = masks;
             obj.myoMask(obj.myoMask ~= 2) = 0;
             obj.myoMask(obj.myoMask == 2) = 1;
             %RV myocardium
             obj.rvBloodPoolMask = masks;
             obj.rvBloodPoolMask(obj.myoMask ~= 3) = 0;
             obj.rvBloodPoolMask(obj.myoMask == 3) = 1;
             %lv myocardium
             obj.lvBloodPoolMask = masks;
             obj.lvBloodPoolMask(obj.myoMask ~= 1) = 0;
        end%loadMyoMask(ob
        
        function obj = loadImSeries(obj)
            obj.imSerie = readnifti(fullfile(obj.dataPath, 'sa.nii'));
        end%loadImSeries(obj)
        
    end%methods (Access = protected)
    
    methods (Access = public)
        function imSerie = getImserie(obj)
            imSerie = obj.imSerie;
        end
        
        function mask = getMask(obj, maskName)
            mask = obj.(maskName);                    
        end
    end
    
end

