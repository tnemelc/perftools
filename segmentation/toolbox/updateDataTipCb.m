function output_txt = updateDataTipCb(obj, event_obj, roiMaskStack, axesTab)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

gcaPos = find(axesTab == gca);

pos = get(event_obj,'Position');
roiVal = roiMaskStack(pos(2), pos(1), gcaPos);
roiSize = length(find((roiMaskStack(:, :, gcaPos)) == roiVal));
output_txt = {['X: ',num2str(pos(1),4)],...
    ['Y: ', num2str(pos(2),4)],...
    ['roi: ', num2str(roiVal)],...
    ['roi size: ', num2str(roiSize)]};

end%updateDataTipCb

