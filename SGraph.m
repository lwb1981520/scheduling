classdef SGraph
    %SGRAPH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        max_edges;
         
        
        %下面的存储格式都是向量，每个向量对应一条边，该边的id为eidx，故每个向量对应的是同个边
        
        %表示所有的边，没在里面的就是没有边，可理解为容量为0
        %注意：容量有可能为0的情况，这个要注意处理
        
        W; %边的权值数组
        %CAP -2 说明虽然记录了边，但该边已删除
        Cap; %边的容量数组
        
        Traf; %流量大小
        
        %边向量 DG1(eidx) 到 DG2(eidx)存在一条有向边
        DG1; %源节点ID
        DG2; %目标节点ID
        
        cur_eidx; %当前边位置，对上面各个数组，<=这个索引值的值是合法的
        
        %将edge (ID1 -> ID2) 映射为 eidx
        
        map_edge;
       
    end
    
    methods(Static)
       

        
        function test()

            g = SGraph(100);           
                
            for i=1:6
                a = SEdge(i,i,i+1,i+1,1,1,i*3);
                
                g = g.pushEdge(a);

                a = SEdge(i,i,i+2,i+2,1,1,i*5);
                g = g.pushEdge(a);
                
            end
            
            for i=1:6
                g = g.addTraf(SEdge(i,i,i+1,i+1,1,1,7));
                assert(g.getTrafValue(SEdge(i,i,i+1,i+1,1,1,0)) == i*3+7,'err');
                assert(g.getTrafValue(SEdge(i,i,i+2,i+2,1,1,0)) == i*5,'err');
                
            end
            
            %g.DG1
            
            %[dist,opath,path,pred,dmap]  = g.getshortestpath(1,7)
            
            fprintf(1,'ALL OK\n');
            
        end
        
    end
    
    methods
        
        function self=SGraph(max_edges)
            
            self = self.resetGraph(max_edges);
        end
        
        function obj=resetGraph(self,max_edges)
            
            
            self.max_edges = max_edges;
            self.W = zeros(1,max_edges);
            self.Cap = zeros(1,max_edges);
            self.DG1 = zeros(1,max_edges);
            self.DG2 = zeros(1,max_edges);
            self.Traf = zeros(1,max_edges);
            
            self.cur_eidx=0;
            
            self.map_edge = containers.Map({0},{0});
           
            
            
            obj=self;
        end
        
        %aedge is [nid_fr, nid_to, capacity, weight]
        %push时同时添加流量信息，Traf T_DGx的相同下标处
        %注意：是增加一条边，若边已存在，则报错
        function obj = pushEdge(self,aedge)
        
            
            %首先查询edge_map，已有边则抛出异常
            emidx = aedge.nidx1*100000+aedge.nidx2;
            
            %这个边以前加过了
            if(isKey(self.map_edge,emidx))
                
                throw(MException('SGraph:error','edge duplicated')); 
                
            end
            
            
            
            eidx = self.cur_eidx + 1;
            
           
            
            self.map_edge(emidx) = eidx;
            
            %fprintf(1,'cur_eidx: %d eidx: %d  wt: %d\n',self.cur_eidx,eidx,aedge.wt);
            
            self.DG1(eidx) = aedge.nidx1;
            self.DG2(eidx) = aedge.nidx2;
            self.Cap(eidx) = aedge.cap;
            self.W(eidx) = aedge.wt;
            self.Traf(eidx) = aedge.tr;
            
            
            self.cur_eidx = eidx;
            
            
            
            obj=self;
            
        end
        
        
        %update if exist, or push
%         function obj = updPushEdge(self,aedge)
%             
%             eidx = intersect(find(self.DG1==aedge.nidx1),find(self.DG2==aedge.nidx2));
%             
%             if(isempty(eidx))
%             	%找到了，更新吧 
%                 self.Cap(eidx) = aedge.cap;
%                 self.W(eidx) = aedge.wt;
%                 self.Traf(eidx) = aedge.tr;
%             else
%                 %没找到，添加
%                 self = self.pushEdge(aedge);
%             end
%             
%             
%             
%         	obj=self;
%             
%             
%         end
        
        function traf_idx = getTrafIndex(self,aflow)

            %找到对应下标
            emidx = aflow.nidx1*100000+aflow.nidx2;            

            
            
            traf_idx = self.map_edge(emidx);


        end

        function traf_v = getTrafValue(self,aflow)
            
            traf_v = self.getPropValue(aflow,'traf');

        end

        function prop_v = getPropValue(self,aflow,aType)
           
            traf_idx = self.getTrafIndex(aflow);
            
            
            
            if( strcmp(aType,'w'))
               prop_v = self.W(traf_idx); 
            elseif( strcmp(aType,'cap'))
               prop_v = self.Cap(traf_idx);
               
            elseif( strcmp(aType,'traf'))
                
               prop_v = self.Traf(traf_idx); 
            else
                throw(MException('SGraph:error_atype',aType));
            
            end
        end
        
        %只是更新流量，必须是已有的边，若存在则更新，否则忽略
        %注意：是加上流量
        function obj = addTraf(self,aflow)
            
            traf_idx = self.getTrafIndex(aflow);
            
            self.Traf(traf_idx) = self.Traf(traf_idx)+aflow.tr;
            
            obj=self;
            
            
        end
        
        
        
        function [dist,opath,path,pred,dmap] = getshortestpath(self,gidx_fr,gidx_to)
            
            cnt = self.cur_eidx;
            if(cnt+2 > self.max_edges)
                msg = sprintf('idx (cnt+2)=(%d) > max_edges(%d)',cnt+2,self.max_edges);
                throw(MException('SGraph:error',msg));
            end
            dg1 = self.DG1(1:cnt+2);
            dg2 = self.DG2(1:cnt+2);
            w = self.W(1:cnt+2);
            
            
            %graphshortestpath函数要求sparse矩阵的行列必须相等
            %且sparse给定下标多大就生成多大的矩阵，矩阵太大，我们需要转化
            %   即:
            %       1.对每个DG_1和_2中的id,转化为一个顺序id,记录这个关系和反向关系，用于转化路径
            %           因为shortestpath函数需要节点ID是1到N之间都有的，不能是跳着的ID
            
            
                cur_id = 0;
                
                %索引即转化后id, 值为原始id
                dmap = ones(0,2*cnt);
                
                omap = containers.Map({0},{0});
                
                for i=1:cnt
                    
                    %x1是当前边的起始节点原始值
                    x1 = dg1(i);
                    
                    %x2是当前变动终止节点原始值
                    x2 = dg2(i);
                    
                    
                    if(isempty(find(dmap==x1, 1)))
                       % no x1, add it
                       cur_id = cur_id + 1;
                       dmap(cur_id) = x1;
                       omap(x1)=cur_id;
                    end
                    
                    if(isempty(find(dmap==x2, 1)))
                       % no x1, add it
                       cur_id = cur_id + 1;
                       dmap(cur_id) = x2;
                       omap(x2) = cur_id;
                    end
                    
                    
                    
                    
                end
            
                %现在dmap中是对应关系了，我们按顺序替换
                for i=1:cnt
                   
                    dg1(i) = omap(dg1(i));
                    dg2(i) = omap(dg2(i));
                end
                
            
            
            
            %       2.生成sparse路径时，注意DG_1和DG_2中的最大值应该相当，才能生成相同行列的矩阵
            %       如果不一样，则添加一个边，权值为intmax
            
            max1 = max(dg1);
            max2 = max(dg2);
            
            rmax = max(max1,max2);
            
            dg1(cnt+1) = rmax;
            dg2(cnt+1) = rmax+1;
            w(cnt+1) = 0;
            
            dg1(cnt+2) = rmax+1;
            dg2(cnt+2) = rmax;
            w(cnt+2) = 0;
            
            %给w加上一个基础值
            tDG = sparse(dg1,dg2,w+1);
            
           
            
            %转化源和目标点
            gidx_fr = find(dmap==gidx_fr,1);
            gidx_to = find(dmap==gidx_to,1);
            
            [dist,opath,pred] = graphshortestpath(tDG,gidx_fr,gidx_to);  
            
            
            %构建反向map,并转化path
            path = opath;
            
            for i=1:length(path)
                
                path(i) = dmap(path(i));
                
            end
            
            
            
            
        end
        
    end
    
end

