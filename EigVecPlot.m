function EigVecPlot(ptCloud)

% a function for ploting eigne vectors of a point cloud

u1 = pcaEig(ptCloud.Location, 'max');
u2 = pcaEig(ptCloud.Location, 'middle');
u3 = pcaEig(ptCloud.Location, 'min');


% pcshow(ptCloud)
% 
% hold on
% plot3([0 50*u1(1)], [0 50*u1(2)], [0 50*u1(3)],'->' ,'LineWidth', 3)
% plot3([0 50*u2(1)], [0 50*u2(2)], [0 50*u2(3)],'->' ,'LineWidth', 3)
% plot3([0 50*u3(1)], [0 50*u3(2)], [0 50*u3(3)],'->' ,'LineWidth', 3)
% xlabel('X')
% ylabel('Y')
% zlabel('Z')
% legend({'pint cloud','first eigen vector', 'second eigen vector', 'third eigen vector'},'TextColor','w')

if abs(u1(3)) > 0.5
    % istadeh
    if u1(3) < 0
        u1 = -1*(u1);
    end
else
    % khabideh
    if u1(2)<0
        u1 = -1*(u1);
    end
end

if abs(u2(1)) > 0.5
     % khabideh
     if u2(1)<0
        u2 = -1*(u2);
     end
else
     % istadeh
     if u2(2)<0
        u2 = -1*(u2);
     end
end

if abs(u3(3)) > 0.5
    if u3(3)<0
        u3 = -1*(u3);
    end
else
    if u3(1)<0
        u3 = -1*(u3);
    end
end


pcshow(ptCloud)

hold on
plot3([0 50*u1(1)], [0 50*u1(2)], [0 50*u1(3)],'->' ,'LineWidth', 3)
plot3([0 50*u2(1)], [0 50*u2(2)], [0 50*u2(3)],'->' ,'LineWidth', 3)
plot3([0 50*u3(1)], [0 50*u3(2)], [0 50*u3(3)],'->' ,'LineWidth', 3)
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'pint cloud','first eigen vector', 'second eigen vector', 'third eigen vector'},'TextColor','w')


end

function u = pcaEig(pc, magnitude)

    % Obtain the covariance matrix
    
    covariance = cov([pc(:, 1) pc(:, 2) pc(:, 3)]);
    
    % Calculate the eigenvectors and obtain the normal vector
    
    [V, D] = eig(covariance);

    diagonalEigenvalues = diag(D);
    
    % Output the normal vector 
    
    % Sort the eigenvectors based on size of eigenvalues 
    [~, I] = sort(diagonalEigenvalues);
    V = V(:, I);
    
    switch magnitude
        case 'max'
            % Choose the eigenvector of the highest eigenvalue
            u = V(:, 3); 
        case 'middle'
            % Choose the eigenvector of the middle eigenvalue
            u = V(:, 2); 
        case 'min'
            % Choose the eigenvector of the lowest eigenvalue
            u = V(:, 1); 
    end
    
end

