function ASD(img1,img2)

    boundaries1 = BoundaryDetector(img1);
    
    boundaries2 = BoundaryDetector(img2);
    
%     for k=1:length(boundaries)
%         b = boundaries{k};
%         plot(b(:,2),b(:,1),'g','LineWidth',3);
%     end
end