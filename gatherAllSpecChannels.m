function specdat=gatherAllSpecChannels(id,study)

%specdat=readspectralpsg3(id,study,datadir,channel,existingspecdat,dataformatspec)

channels={'fz','fcz','cz','pz'};
for i=1:length(channels)
    if exist('specdat','var')
        try
            specdat=readspectralpsg3(id,study,'J:\PAN2\spectral_vertsd',channels{i},specdat);
        end
    else
        try
            specdat=readspectralpsg3(id,study,'J:\PAN2\spectral_vertsd',channels{i});
        end
    end
end
end