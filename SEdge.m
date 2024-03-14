classdef SEdge
    %SEDGE Summary of this class goes here
    %   Detailed explanation goes here
    % �������ǰѱ�������Ϣ������䣬һ���ߵ�������Ҫ����Ϣ
    properties
        
        nid1;
        nidx1;
        nid2;
        nidx2;
        
        cap;
        wt;
        
        tr;
        
    end
    
    methods
        
        function self = SEdge(nid1,nidx1,nid2,nidx2,cap,wt,tr)
            self.nid1 = nid1;
            self.nidx1 = nidx1;
            self.nid2 = nid2;
            self.nidx2 = nidx2;
            self.cap  = cap;
            self.wt = wt;
            self.tr = tr;
            
        end
        
        function obj = setWeight(self,wt)
            
            self.wt = wt;
            obj = self;
        end
    end
    
    
end

