% resCompDataTipCb.m
% brief: display voxel and region parameter values
%
%
% references:
%
%
% input:
% event_obj: Handle to event object
% roiMaskStack: stack of parameters maps 
% axesTab: 
%
%
% output: 
% output_txt: Data cursor text string (string or cell array of strings).
%
%
% keywords: results comparator, data visualization
% author: C.Daviller
% date: 28-Dec-2017 


 function output_txt = resCompDataTipCb(~, event_obj, paramMapStack, roiMapsStack, axesTab)
 
    gcaPos = find(axesTab == gca);
    pos = get(event_obj,'Position');
    paramMap = paramMapStack(:, :, gcaPos);
    voxVal = paramMap(pos(2), pos(1));
    [avgRoiTab, stdRoiTab] = processRoiStat(paramMap, roiMapsStack(:, :, gcaPos));
    output_txt = sprintf('X: %d , Y: %d\nVoxel value: %0.02f\n', pos(1), pos(2), voxVal);
    for k = 1 : numel(avgRoiTab)
        output_txt = sprintf('%sroi %d Mean(std) value: %0.2f(%0.2f)\n', output_txt, k, avgRoiTab(k), stdRoiTab(k));
    end
    
     function [roiAvgTab, roiStdTab] = processRoiStat(paramMap, mask)
         nbRoi = max(mask(:));
         for i = 1 : nbRoi
             roiPos = find(mask == i);
             roiParamValVect = paramMap(roiPos);
             %remove out of mask voxels
             roiParamValVect(roiParamValVect == 0) = [];
             roiAvgTab(i) = mean(roiParamValVect);
             roiStdTab(i) = std(roiParamValVect);
         end
     end%processRoiStat
end