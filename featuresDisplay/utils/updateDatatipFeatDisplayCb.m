% updateDatatipFeatDisplayCb.m
% brief: 
% Display the position of the data cursor
% 
%
% references:
% input:
% obj          Currently not used (empty)
% event_obj    Handle to event object

%
% output
% output_txt: Data cursor text string (string or cell array of strings)
%
%
% keywords: datatip, update, display
% author: C.Daviller
% date: 03-Nov-2017 


 function output_txt = updateDatatipFeatDisplayCb(obj, event_obj, dimKS, featuresVect, threshold)


output_txt = {[char(dimKS(1)), ': ', num2str(featuresVect(1))],...
              [char(dimKS(2)), ': ', num2str(featuresVect(2))],...
              [char(dimKS(3)), ': ', num2str(featuresVect(3))],...
              ['threshold: ', num2str(threshold)]};
end