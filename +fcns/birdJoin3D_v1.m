function [out] = birdJoin3D_v1(birds,opts)

% function [out] = birdJoin3D_v1(birds,opts)
%
% Uses MATLAB's assignDetectionsToTracks in 2D & 3D to try and track the
% points swifts in a scene
%
% out = [x,y,z,rmse,u1,v1,u2,v2,u3,v3] tiled in columns
%
% _v7 - major re-architecture, different output data structure and no more
% xydata or minSpeed inputs.
%  
% _swallowJoin3D_v1 - fork of swiftJoin3D_v7sparse for swallow work
% _birdJoin3D_v1 - fork of swallowJoin3D_v1 for general bird work

% control whether detailed status messages are printed or not
msgs=true;

% setup pruning
if opts.minimumTrackLength==0
  pruning=false;
else
  pruning=true;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Kalman construction constants for XY - tuned on 2014-10-31
initialEstimateErrorXY=[0.0196 16.3662];
motionNoiseXY=[7.2391e-11 7.1038e-04];
measurementNoiseXY=0.0059;

% Kalman construction constants for XYZ - tuned on 2014-10-31
initialEstimateErrorXYZ=[8.3829e-08 0.3003];
motionNoiseXYZ=[9.1316e-05 0.0024];
measurementNoiseXYZ=0.4430;

% extract initial Kalman XYZ configuration
foo=configureKalmanFilter('ConstantVelocity',[2,2,2],initialEstimateErrorXYZ,motionNoiseXYZ,measurementNoiseXYZ);
Hxyz=foo.MeasurementModel; 
Rxyz=foo.MeasurementNoise;
Pxyz=foo.StateCovariance;
Axyz=foo.StateTransitionModel;
Qxyz=foo.ProcessNoise;
Xxyz=foo.State;

% extract initial Kalman XY configuration
foo=configureKalmanFilter('ConstantVelocity',ones(1,birds.numCams*2)*2,initialEstimateErrorXY,motionNoiseXY,measurementNoiseXY);
Hxy=foo.MeasurementModel;
Rxy=foo.MeasurementNoise;
Pxy=foo.StateCovariance;
Axy=foo.StateTransitionModel;
Qxy=foo.ProcessNoise;
Xxy=foo.State;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialization
frame=opts.startFrame; % first frame
numFrames=opts.endFrame-opts.startFrame-1; % number of frames to process
xyz=birds.xyzpts{frame}(:,1:4);
xy=birds.xypts{frame}(:,:);
tBlock=size(xyz,2)+size(xy,2); % size of an [xyz,xy] track array

% setup output arrays
out(frame,:)=reshape([xyz,xy]',1,numel([xyz,xy]));
out(frame+1:frame+numFrames,:)=0;
out=sparse(out);

% setup storage cell array to avoid having main storage arrays grow too
% large
outStore{1}=sparse([]);
outStorePos=1;

% current values for number of active tracks, their length & newness
numTracks=size(out,2)/tBlock;
trackLength=ones(numTracks,1);
trackNewness=ones(numTracks,1);

% expand out to accomodate 500 additional tracks
out(:,(numTracks+1)*tBlock-(tBlock-1):(numTracks+500)*tBlock-(tBlock-0))=0;

% setup a Kalman filter specification for each bird, separate xyz & xy
for i=1:numTracks
  Hxy2(:,:,i)=Hxy;
  Rxy2(:,:,i)=Rxy;
  Pxy2(:,:,i)=Pxy;
  Axy2(:,:,i)=Axy;
  Qxy2(:,:,i)=Qxy;
  Xxy2(1:2:birds.numCams*4,1,i)=xy(i,:);
  
  Hxyz2(:,:,i)=Hxyz; % Hxyz never changes, could not bother to track it
  Rxyz2(:,:,i)=Rxyz; % Rxyz never changes, could not bother to track it
  Pxyz2(:,:,i)=Pxyz;
  Axyz2(:,:,i)=Axyz; % Axyz never changes, could not bother to track it
  Qxyz2(:,:,i)=Qxyz; % Qxyz never changes, could not bother to track it
  Xxyz2(1:2:6,1,i)=xyz(i,1:3);
  
  %kalmanXYZ{i}=configureKalmanFilter('ConstantVelocity',xyz(i,:),initialEstimateErrorXYZ,motionNoiseXYZ,measurementNoiseXYZ);
  %kalmanXY{i}=configureKalmanFilter('ConstantVelocity',xy(i,:),initialEstimateErrorXY,motionNoiseXY,measurementNoiseXY);
end
Xxy2(birds.numCams*4,:,:)=0;
Xxyz2(6,:,:)=0;

%ajc adding initial estimate of velocity based on optic flow
if size(birds.uvData{1},2) > 6
    for i = 1:size(birds.uvData,2)                                    %Cycle through each camera
        uvd = birds.uvData{i};     
        meds = round(median(uvd(find(uvd(:,1)<uvd(1,1)+5),:))); %Get median values
        Xxy2(i*4-2,:,:) = meds(4);
        Xxy2(i*4,:,:) = meds(5);
    end
end
% processing sequence
pseq=frame:frame+numFrames-1;
for i=0:19
  milestones(i+1,1)=round(numel(pseq)*i/20)+frame;
end
milestones=unique(milestones);

% main track assignment & generation loop
for k=pseq
  %disp(k)
  % display milestone info
  mdx=find(milestones==k);
  if numel(mdx)>0
    disp(['Track building ',num2str((mdx-1)*5),'% complete'])
  end
  
  % display frame number if Messages are on
  if msgs
    disp(k)
  end
  
  % identify active tracks
  activeTracks=find(trackNewness<=opts.maximumGapLength);
  if msgs
    disp([num2str(numel(activeTracks)),' active tracks'])
  end
    
  % get Kalman predictions
  fooXYZ=inf(numel(activeTracks),3);
  fooXY=inf(numel(activeTracks),birds.numCams*2);
  fooXYd=inf(numel(activeTracks),birds.numCams*2);
  for i=1:numel(activeTracks)
    
    % project error covariance ahead
    Pxy2(:,:,activeTracks(i))=Axy2(:,:,activeTracks(i))*Pxy2(:,:,activeTracks(i))*Axy2(:,:,activeTracks(i))'+Qxy2(:,:,activeTracks(i));
    Pxyz2(:,:,activeTracks(i))=Axyz2(:,:,activeTracks(i))*Pxyz2(:,:,activeTracks(i))*Axyz2(:,:,activeTracks(i))'+Qxyz2(:,:,activeTracks(i));
    
    % kalman gains
    Kxy2(:,:,activeTracks(i))=(Pxy2(:,:,activeTracks(i))*Hxy2(:,:,activeTracks(i))')/ ...
      (Hxy2(:,:,activeTracks(i))*Pxy2(:,:,activeTracks(i))* ...
      Hxy2(:,:,activeTracks(i))'+Rxy2(:,:,activeTracks(i)));
    Kxyz2(:,:,activeTracks(i))=(Pxyz2(:,:,activeTracks(i))*Hxyz2(:,:,activeTracks(i))')/ ...
      (Hxyz2(:,:,activeTracks(i))*Pxyz2(:,:,activeTracks(i))* ...
      Hxyz2(:,:,activeTracks(i))'+Rxyz2(:,:,activeTracks(i)));
    
    % kalman predictions
    % NaN-safe xy prediction
    fXxy2=Xxy2(:,:,activeTracks(i));
    fdx=find(isnan(fXxy2));
    fXxy2(fdx)=0;
    Xxy2(:,:,activeTracks(i))=Axy2(:,:,activeTracks(i))*fXxy2;
    Xxy2(fdx,:,activeTracks(i))=NaN;
    %Xxy2(:,:,activeTracks(i))=Axy2(:,:,activeTracks(i))*Xxy2(:,:,activeTracks(i));
    
    % xyz prediction
    Xxyz2(:,:,activeTracks(i))=Axyz2(:,:,activeTracks(i))*Xxyz2(:,:,activeTracks(i));
    
    % copy predictions
    fooXY(i,:)=Xxy2(1:2:birds.numCams*4,:,activeTracks(i)); % kalman xy coordinates
    fooXYd(i,:)=Xxy2(2:2:birds.numCams*4,:,activeTracks(i)); % kalman xy velocity
    fooXYZ(i,:)=Xxyz2(1:2:6,:,activeTracks(i)); % kalman xyz coordinates
    
    
    %fooXYZ(i,:)=predict(kalmanXYZ{activeTracks(i)});
    %fooXY(i,:)=predict(kalmanXY{activeTracks(i)});
    %fooXYd(i,:)=kalmanXY{activeTracks(i)}.State(2:2:12).*[1,-1,1,-1,1,-1]'; % kalman velocity
  end
  
  % get new data
  if numel(birds.xypts{k+1})>0
    % grab data and make sure we have unique combos
    xyz=birds.xyzpts{k+1};
    xy=birds.xypts{k+1};
    
    % This step picked only the best 3D point for a given 2D detection - no
    % multiples
    % [xy,xyz]=xyUnique_v1([xy,xyz]);
    
    % assignment
%    disp(num2str(k))
    if k==8916
      %disp('oops')
    end
    %[assignments,unassignedTracks,unassignedDetections] = tileAssign_v3(xy,xyz,fooXY,fooXYZ,trackNewness(activeTracks),opts);
    %[assignments,unassignedTracks,unassignedDetections] = tileAssign_v5(xy,xyz,fooXY,fooXYZ,trackNewness(activeTracks),trackLength(activeTracks),opts);
    [assignments,unassignedTracks,unassignedDetections] = tileAssign_v5(xy,xyz,fooXY,fooXYZ,trackNewness(activeTracks),trackLength(activeTracks),opts);
    % report cost
    %plot(assignments(:,3)*0+k,assignments(:,3),'.')
  else
    assignments=zeros(0,3);
    unassignedTracks=1:numel(activeTracks);
    unassignedDetections=[];
  end
  
  % add to existing tracks
  if msgs
      disp(['Found ',num2str(size(assignments,1)),' observation <--> track matches with median cost ',num2str(median(assignments(:,3)))])
  end
    
    % update newness & length
    trackNewness(activeTracks(assignments(:,1)),1)=1;
    trackNewness(activeTracks(unassignedTracks),1)=trackNewness(activeTracks(unassignedTracks),1)+1;
    trackLength(activeTracks(assignments(:,1)),1)=trackLength(activeTracks(assignments(:,1)),1)+1;
    
    % add to existing tracks
    if msgs
      disp(['Updating ',num2str(size(assignments,1)),' tracks'])
    end
    out(k+1,:)=0; % make sure a row of NaNs gets added to paths
    
    % Fast update since updating the sparse array in a loop is slow
    % xyz
    idxT=[activeTracks(assignments(:,1))*tBlock-(tBlock-1),activeTracks(assignments(:,1))*tBlock-(tBlock-2),activeTracks(assignments(:,1))*tBlock-(tBlock-3),activeTracks(assignments(:,1))*tBlock-(tBlock-4)];
    idxT=reshape(idxT',1,numel(idxT));
    idxX=[assignments(:,2)*4-3,assignments(:,2)*4-2,assignments(:,2)*4-1,assignments(:,2)*4-0];
    idxX=reshape(idxX',1,numel(idxX));
    xyz2=reshape(xyz',1,numel(xyz));
    out(k+1,idxT)=xyz2(idxX);
    
    % xy
    idxT=repmat([activeTracks(assignments(:,1))*tBlock-(tBlock-5)],1,birds.numCams*2);
    if numel(idxT)>0
      for i=2:birds.numCams*2
        idxT(:,i)=idxT(:,i-1)+1;
      end
      idxT=reshape(idxT',1,numel(idxT));
      idxX=repmat([assignments(:,2)*birds.numCams*2-(birds.numCams*2-1)],1,birds.numCams*2);
      for i=2:birds.numCams*2
        idxX(:,i)=idxX(:,i-1)+1;
      end
      idxX=reshape(idxX',1,numel(idxX));
      xy2=reshape(xy',1,numel(xy));
      out(k+1,idxT)=xy2(idxX);
    end
    
    % Update Kalman filters
    if numel(assignments)>0
      for i=activeTracks(assignments(:,1))'
        
        % corrections
        Xxyz2(:,:,i)=Xxyz2(:,:,i)+Kxyz2(:,:,i)*(full(out(k+1,i*tBlock-(tBlock-1):i*tBlock-(tBlock-3)))'-Hxyz2(:,:,i)*Xxyz2(:,:,i));
        
        % NaN-safe update for xy points
        fXxy2=Xxy2(:,:,i);
        fXxy2(isnan(fXxy2))=0;
        obs=full(out(k+1,i*tBlock-(tBlock-5):i*tBlock-0))';
        obs(isnan(obs))=0;
        Xxy2(:,:,i)=Xxy2(:,:,i)+Kxy2(:,:,i)*(obs-Hxy2(:,:,i)*fXxy2);
        %Xxy2(:,:,i)=Xxy2(:,:,i)+Kxy2(:,:,i)*(full(out(k+1,i*10-5:i*10-0))'-Hxy2(:,:,i)*Xxy2(:,:,i));
        
        % update error covariance
        Pxy2(:,:,i)=(eye(birds.numCams*4)-Kxy2(:,:,i)*Hxy2(:,:,i))*Pxy2(:,:,i);
        Pxyz2(:,:,i)=(eye(6)-Kxyz2(:,:,i)*Hxyz2(:,:,i))*Pxyz2(:,:,i);
        
        %correct(kalmanXYZ{i},full(out(k+1,i*21-20:i*21-18)));
        %correct(kalmanXY{i},full(out(k+1,i*21-17:i*21-12)));
      end
    end
    %   parfor i=1:size(assignments,1)
    %     K=activeTracks(assignments(i,1));
    %       correct(kalmanXYZ{K},full(out(k+1,K*21-20:K*9-6)));
    %       correct(kalmanXY{K},full(out(k+1,K*9-5:K*9)));
    %   end
    
    % create new tracks & kalmans
    % expand array sizes if appropriate
    if size(out,2)/tBlock-(numTracks+numel(unassignedDetections))<100
      out(:,(numTracks+1)*tBlock-(tBlock-1):(numTracks+500+numel(unassignedDetections))*tBlock)=0;
      
      Hxy2(:,:,end+1:(24+numel(unassignedDetections)))=0;  % why 24?
      Rxy2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Pxy2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Axy2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Qxy2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Xxy2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      
      Hxyz2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Rxyz2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Pxyz2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Axyz2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Qxyz2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      Xxyz2(:,:,end+1:(24+numel(unassignedDetections)))=0;
      
      if msgs
        disp('    Added more blank tracks')
      end
    end
    if msgs
      disp(['Adding ',num2str(numel(unassignedDetections)),' tracks'])
    end
    trackLength(numTracks+1:numTracks+numel(unassignedDetections),1)=1;
    trackNewness(numTracks+1:numTracks+numel(unassignedDetections),1)=1;
    
    for i=1:numel(unassignedDetections)
      %out(end+1,1:9,k+1)=[xyz(unassignedDetections(i),1:3),xy(unassignedDetections(i),1:6)];
      numTracks=numTracks+1;
      out(k+1,numTracks*tBlock-(tBlock-1):numTracks*tBlock)=[xyz(unassignedDetections(i),1:4),xy(unassignedDetections(i),1:birds.numCams*2)];
      
      Hxy2(:,:,numTracks)=Hxy;
      Rxy2(:,:,numTracks)=Rxy;
      Pxy2(:,:,numTracks)=Pxy;
      Axy2(:,:,numTracks)=Axy;
      Qxy2(:,:,numTracks)=Qxy;
      Xxy2(1:2:birds.numCams*4,1,numTracks)=full(out(k+1,numTracks*tBlock-(tBlock-5):numTracks*tBlock-0));
      
      Hxyz2(:,:,numTracks)=Hxyz;
      Rxyz2(:,:,numTracks)=Rxyz;
      Pxyz2(:,:,numTracks)=Pxyz;
      Axyz2(:,:,numTracks)=Axyz;
      Qxyz2(:,:,numTracks)=Qxyz;
      Xxyz2(1:2:6,1,numTracks)=full(out(k+1,numTracks*tBlock-(tBlock-1):numTracks*tBlock-(tBlock-3)));
      
      %kalmanXYZ{numTracks}=configureKalmanFilter('ConstantVelocity',full(out(k+1,numTracks*21-20:numTracks*21-18)),initialEstimateErrorXYZ,motionNoiseXYZ,measurementNoiseXYZ);
      %kalmanXY{numTracks}=configureKalmanFilter('ConstantVelocity',full(out(k+1,numTracks*21-17:numTracks*21-12)),initialEstimateErrorXY,motionNoiseXY,measurementNoiseXY);
      
    end
  %end
  % ajc added:
 
    if size(birds.uvData{1},2) > 6
        for i = 1:size(birds.uvData,2)                                    %Cycle through each camera
            uvd = birds.uvData{i};     
            meds = round(median(uvd(find(uvd(:,1)>k-5 & uvd(:,1)<k+5),:))); %Get median values
            Xxy2(i*4-2,:,end-numel(unassignedDetections):end) = meds(4);
            Xxy2(i*4,:,end-numel(unassignedDetections):end) = meds(5);
        end
    end
  
  % prune paths
  if k-frame>20 && pruning % check pruning conditions
    
    % remove stuff based on minimum track length
    idx=find(trackLength<opts.minimumTrackLength & (trackNewness>opts.maximumGapLength | isinf(trackNewness)));
    
    if numel(idx)>0
      % delete kalmans
      Hxy2(:,:,idx)=[];
      Rxy2(:,:,idx)=[];
      Pxy2(:,:,idx)=[];
      Axy2(:,:,idx)=[];
      Qxy2(:,:,idx)=[];
      Xxy2(:,:,idx)=[];
      
      Hxyz2(:,:,idx)=[];
      Rxyz2(:,:,idx)=[];
      Pxyz2(:,:,idx)=[];
      Axyz2(:,:,idx)=[];
      Qxyz2(:,:,idx)=[];
      Xxyz2(:,:,idx)=[];
      
      % not sure the below lines are correct for n cameras
      %idxOut=repmat(idx*10,1,10)-repmat(0:9,numel(idx),1);
      idxOut=repmat(idx*tBlock,1,tBlock)-repmat(0:(tBlock-1),numel(idx),1);
      out(:,reshape(idxOut,1,numel(idxOut)))=[];
      numTracks=numTracks-numel(idx);
      trackLength(idx)=[];
      trackNewness(idx)=[];
    end
    if msgs
      disp(['Deleting ',num2str(numel(idx)),' tracks'])
    end
  end
  
  % store old paths
  if k-frame>20
    % store stuff based on minimum track length & maxGapLength
    idx=find(trackLength>=opts.minimumTrackLength & (trackNewness>opts.maximumGapLength | isinf(trackNewness)));
    
    if numel(idx)>0
      
      % delete kalmans
      Hxy2(:,:,idx)=[];
      Rxy2(:,:,idx)=[];
      Pxy2(:,:,idx)=[];
      Axy2(:,:,idx)=[];
      Qxy2(:,:,idx)=[];
      Xxy2(:,:,idx)=[];
      
      Hxyz2(:,:,idx)=[];
      Rxyz2(:,:,idx)=[];
      Pxyz2(:,:,idx)=[];
      Axyz2(:,:,idx)=[];
      Qxyz2(:,:,idx)=[];
      Xxyz2(:,:,idx)=[];
      
      numTracks=numTracks-numel(idx);
      trackLength(idx)=[];
      trackNewness(idx)=[];
      
      % check outStore size
      if numel(outStore{outStorePos}>2^16)
        outStorePos=outStorePos+1;
        outStore{outStorePos}=sparse([]);
      end
      
      % store in a loop so we can set the array length when copying
      for i=fliplr(idx')
        idx2=find(out(:,i*tBlock-(tBlock-1))~=0);
        outStore{outStorePos}(idx2(1):idx2(end),end+1:end+tBlock)=out(idx2(1):idx2(end),i*tBlock-(tBlock-1):i*tBlock);
        out(:,i*tBlock-(tBlock-1):i*tBlock)=[];
      end
      if msgs
        disp(['Storing ',num2str(numel(idx)),' tracks'])
      end
    end
  end
  1;
  % make sure trackNewness and trackLength are at least [0,1] in size
  if isempty(trackNewness)
    trackNewness=zeros(0,1);
  end
  if isempty(trackLength)
    trackLength=zeros(0,1);
  end
end


% final pruning event to get rid of newly created tracks that don't meet
% standards
idx=find(trackLength<opts.minimumTrackLength);

if numel(idx)>0
  % delete kalmans
  Hxy2(:,:,idx)=[];
  Rxy2(:,:,idx)=[];
  Pxy2(:,:,idx)=[];
  Axy2(:,:,idx)=[];
  Qxy2(:,:,idx)=[];
  Xxy2(:,:,idx)=[];
  
  Hxyz2(:,:,idx)=[];
  Rxyz2(:,:,idx)=[];
  Pxyz2(:,:,idx)=[];
  Axyz2(:,:,idx)=[];
  Qxyz2(:,:,idx)=[];
  Xxyz2(:,:,idx)=[];
  
  % not sure the below lines are correct for n cameras
  %idxOut=repmat(idx*10,1,10)-repmat(0:9,numel(idx),1);
  idxOut=repmat(idx*tBlock,1,tBlock)-repmat(0:(tBlock-1),numel(idx),1);
  out(:,reshape(idxOut,1,numel(idxOut)))=[];
  numTracks=numTracks-numel(idx);
  trackLength(idx)=[];
  trackNewness(idx)=[];
end
disp(['Final cleanup: Deleting ',num2str(numel(idx)),' tracks'])




% trim padding
idx=find(sum(out(:,3:tBlock:end))==0);
for i=fliplr(idx)
  out(:,i*tBlock-(tBlock-1):i*tBlock)=[];
end

% merge storage and live arrays (preallocated method)
tic
disp('Merging live and storage data arrays')
% gather info for preallocation
cols=size(out,2);
nonzero=nnz(out);
for i=1:outStorePos
  cols=cols+size(outStore{i},2);
  nonzero=nonzero+nnz(outStore{i});
end

% preallocate the sparse array
out2=spalloc(size(out,1),cols,nonzero);
cp=1; % starting column position
for i=1:outStorePos
  outStore{i}(1:size(out,1),end+1)=0; % pad with zeros
  outStore{i}(:,end)=[]; % remove padding column
  out2(:,cp:cp+size(outStore{i},2)-1)=outStore{i};
  cp=cp+size(outStore{i},2);
  outStore{i}=[]; % keep ram usage under control
  %disp('.')
end
out2(:,cp:cp+size(out,2)-1)=out;
out=out2;

idx=find(sum(out(:,3:tBlock:end))==0);
for i=fliplr(idx)
  out(:,i*tBlock-(tBlock-1):i*tBlock)=[];
end

toc

disp('track generation done')